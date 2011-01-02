/*==============================================================*/
/* DBMS name:      ORACLE Version 11g                           */
/* Created on:     06-12-2010 17:41:22                          */
/*==============================================================*/


/*==============================================================*/
/*                      Patch Notes 2.85						*/
/*   										                    */
/*	SONG's ALB_PRODUCT_ID can now be null						*/
/*	SONG's SONG_NUMBER can now be null							*/
/*	PRODUCT no longer has field PRODUCT_NAME					*/
/*	MERCHANDISE now has field MERCHANDISE_NAME					*/
/*	ALBUM now has field ALBUM_NAME								*/
/*	ALBUM no longer has field ALBUM_YEAR						*/
/*	Changed PRODUCT's PRODUCT_IMAGE to just IMAGE				*/
/*  PRODUCT'S DESCRIPTION field resized to varchar2(1000)       */
/*	CLIENT_ID's type changed from INTEGER to VARCHAR2(20)		*/
/*	CURRENT_PRICE is now a FLOAT								*/
/* 	ADDED_DATE to PRODUCT										*/
/*  NUM_SELLS added to PRODUCT 									*/
/*	CLIENT's field TELEPHONE's type changed from INTEGER to		*/
/*	VARCHAR (20)												*/
/*	CLIENT's field PASSWORD size increased from 20 to 50		*/
/*  ADDED DELETE TRIGGERS										*/
/*  CREATED CREDITS IN CLIENT									*/
/*  "ORDER" TABLE CHANGED to MAIN_ORDER							*/
/*	ALBUM_GENRE can no longe be null (wtf?)						*/
/*==============================================================*/


alter table ALBUM
   drop constraint FK_ALBUM_INHERITAN_PRODUCT;

alter table MERCHANDISE
   drop constraint FK_MERCHAND_INHERITAN_PRODUCT;

alter table "ORDER"
   drop constraint FK_ORDER_MAKES_CLIENT;

alter table ORDER_DETAILS
   drop constraint FK_ORDER_DE_HAS_ORDER;

alter table ORDER_DETAILS
   drop constraint FK_ORDER_DE_HAS_ONE_PRODUCT;

alter table PRODUCT
   drop constraint FK_PRODUCT_OF_ARTIST;

alter table SONG
   drop constraint FK_SONG_HAS_SEVER_ALBUM;

alter table SONG
   drop constraint FK_SONG_INHERITAN_PRODUCT;

drop table ALBUM cascade constraints;

drop table ARTIST cascade constraints;

drop table CLIENT cascade constraints;

drop table MERCHANDISE cascade constraints;

drop index MAKES_FK;

drop table "ORDER" cascade constraints;

drop index HAS_ONE_FK;

drop index HAS_FK;

drop table ORDER_DETAILS cascade constraints;

drop index OF_FK;

drop table PRODUCT cascade constraints;

drop index HAS_SEVERAL_FK;

drop table SONG cascade constraints;

drop sequence artist_number;

drop sequence product_number;

CREATE sequence artist_number
START with 1
INCREMENT by 1
NOCYCLE;

CREATE sequence order_number
START with 1
INCREMENT by 1
NOCYCLE;

CREATE sequence product_number
START with 1
INCREMENT by 1
NOCYCLE;


create or replace procedure voting (id in integer, vote in integer) IS

allvotes product.votes%type;
new_rating product.rating%type;
old_rating product.rating%type;

BEGIN
	select votes into allvotes from product where product_id=id for update of votes;
	select rating into old_rating from product where product_id=id for update of rating;

	new_rating := (old_rating*allvotes + vote) / (allvotes+1);
	allvotes:=allvotes+1;
	update product set rating = new_rating where product_id=id;
	update product set votes = allvotes where product_id=id;
	commit;
END;
/

create or replace procedure buy_credits (creditos in client.credits%type, id in client.client_id%type, result out integer) IS
old_credits client.credits%type;
new_credits client.credits%type;
BEGIN
	select credits into old_credits from client where client_id = id for update of credits;
	new_credits := creditos + old_credits;
	update client set credits = new_credits where client_id=id;
	commit;
	result:=0;
END;
/

/* ADD CLIENT */
create or replace procedure addClient(
	username in client.client_id%type,
	address in client.address%type, 
	telephone in client.telephone%type, 
	name in client.name%type, 
	password in client.password%type, 
	email in client.email%type,
	result out integer) IS
	
	aux_user client.client_id%type;
BEGIN
	select client_id into aux_user from client where client_id = username;
	result:=-1;
	
EXCEPTION
	when no_data_found then
		insert into client(client_id, password, name, address, telephone, email, credits)
		values(username, password, name, address, telephone, email, 0);
		result:=0;
		commit;
END;
/

/* ADD ARTIST */
create or replace procedure addArtist(
	name in artist.artist_name%type,
	bio in artist.artist_bio%type,
	image in artist.artist_image%type,
	result out integer) IS
	
	aux_artist artist.artist_name%type;
BEGIN
	select artist_name into aux_artist from artist where artist_name = name;
	result:=-1;
	
EXCEPTION
	when no_data_found then
		INSERT INTO artist(artist_id, artist_name, artist_image, artist_bio)
		VALUES(artist_number.nextval, name, image, bio);
		result:=0;
		commit;
	when others then
		result:=-2;
END;
/

/* ADD ALBUM */
create or replace procedure addAlbum(
	albumname in album.album_name%type,
	album_length in album.album_length%type,
	album_genre in album.album_genre%type,
	album_label in album.album_label%type,
	album_artist in product.artist_id%type,
	album_desc in product.description%type,
	album_image in product.image%type,
	album_date in product.release_date%type,
	album_price in product.current_price%type,
	album_stock in product.stock%type,
	result out integer,
	id_product out integer) IS
	
	aux_albumname artist.artist_name%type;
	aux_artist_id product.artist_id%type;
	product_id product.product_id%type;
BEGIN
	select a.album_name, p.artist_id into aux_albumname, aux_artist_id
	from album a, product p
	where a.product_id = p.product_id and
	upper(a.album_name) = upper(albumname) and
	p.artist_id = album_artist;
	result:=-1;
	
EXCEPTION
	when no_data_found then
		select product_number.nextval into product_id from dual;
		
		INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
		VALUES(product_id, album_artist, album_desc, album_image, album_date, 0, 0, sysdate, album_price, album_stock, 0);
		result:=0;
		
		INSERT INTO album(product_id, album_name, album_length, album_genre, album_label)
		VALUES(product_id, albumname, album_length, album_genre, album_label);
		result:=0;
		id_product:=product_id;
		
		commit;
	when others then
		result :=2;
END;
/

/* ADD MERCHANDISE */
create or replace procedure addMerch(
	name in merchandise.merchandise_name%type,
	artistID in product.artist_id%type,
	description in product.description%type,
	image in product.image%type,
	release_date in product.release_date%type,
	price in product.current_price%type,
	stock in product.stock%type,
	result out integer
	) IS
	
	aux_name merchandise.merchandise_name%type;
	aux_id product.artist_id%type;
	product_id product.product_id%type;
BEGIN
	select m.merchandise_name, p.artist_id into aux_name, aux_id
	from product p, merchandise m
	where p.product_id = m.product_id and
	upper(m.merchandise_name) = upper(name) and
	p.artist_id = artistID;
	result:=-1;
	
EXCEPTION
	when no_data_found then
		select product_number.nextval into product_id from dual;
		
		INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
		VALUES(product_id, artistID, description, image, release_date, 0, 0, sysdate, price, stock, 0);
		result:=0;
		
		INSERT INTO merchandise(product_id, merchandise_name)
		VALUES(product_id, name);
		result:=0;
		
		commit;
	when others then
		result :=2;
END;
/

/* ADD SONG */
create or replace procedure addSong (
	albproduct_id in song.alb_product_id%type,
	name in song.song_name%type,
	song_length in song.song_length%type,
	song_genre in song.song_genre%type, 
	song_number in song.song_number%type,
	artistID in product.artist_id%type,
	description in product.description%type,
	image in product.image%type,
	release_date in product.release_date%type,
	price in product.current_price%type,
	stock in product.stock%type,
	result out integer) IS
	
	product_id product.product_id%type;
	aux_song song.song_name%type;
	aux_id song.alb_product_id%type;
BEGIN
	select s.song_name, s.alb_product_id into aux_song, aux_id
	from song s
	where s.song_name = name and
	s.alb_product_id = albproduct_id;
	result:=-1;
	
EXCEPTION
	when no_data_found then
		select product_number.nextval into product_id from dual;
	
		INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
		VALUES(product_id, artistID, description, image, release_date, 0, 0, sysdate, price, stock, 0);
		result:=0;
		
		INSERT INTO song(product_id, alb_product_id, song_name, song_length, song_genre, song_number)
		VALUES(product_id, albproduct_id, name, song_length, song_genre, song_number);
		result := 0;
		
	when others then
		result :=2;
END;
/



/*==============================================================*/
/* Table: ALBUM                                                 */
/*==============================================================*/
create table ALBUM 
(
   PRODUCT_ID           INTEGER               not null,
   ALBUM_NAME			VARCHAR2(100)         not null,
   ALBUM_LENGTH         VARCHAR2(10)          not null,
   ALBUM_GENRE          VARCHAR2(50)          not null,
   ALBUM_LABEL          VARCHAR2(50)          not null,
   constraint PK_ALBUM primary key (PRODUCT_ID)
);

/*==============================================================*/
/* Table: ARTIST                                                */
/*==============================================================*/
create table ARTIST 
(
   ARTIST_ID            INTEGER              not null,
   ARTIST_NAME          VARCHAR2(50)         not null,
   ARTIST_BIO           VARCHAR2(2000)       not null,
   ARTIST_IMAGE         VARCHAR2(100)        not null,
   constraint PK_ARTIST primary key (ARTIST_ID)
);

/*==============================================================*/
/* Table: CLIENT                                                */
/*==============================================================*/
create table CLIENT 
(
   CLIENT_ID            VARCHAR2(20)         not null,
   PASSWORD             VARCHAR2(50)         not null,
   NAME                 VARCHAR2(50)         not null,
   ADDRESS              VARCHAR2(100)		 not null,
   TELEPHONE            VARCHAR2(20)		 not null,
   EMAIL                VARCHAR2(50)         not null,
   CREDITS 				FLOAT				 not null,
   constraint PK_CLIENT primary key (CLIENT_ID)
);

/*==============================================================*/
/* Table: MERCHANDISE                                           */
/*==============================================================*/
create table MERCHANDISE 
(
   PRODUCT_ID           INTEGER               not null,
   MERCHANDISE_NAME		VARCHAR2(100)         not null,
   constraint PK_MERCHANDISE primary key (PRODUCT_ID)
);

/*==============================================================*/
/* Table: MAIN_ORDER                                            */
/*==============================================================*/
create table MAIN_ORDER
(
   REGISTRY_ID          INTEGER               not null,
   CLIENT_ID            VARCHAR2(20)          not null,
   TOTAL_PRICE          FLOAT                 not null,
   ORDER_DATE           DATE                  not null,
   constraint PK_ORDER primary key (REGISTRY_ID)
);

/*==============================================================*/
/* Index: MAKES_FK                                              */
/*==============================================================*/
create index MAKES_FK on MAIN_ORDER (
   CLIENT_ID ASC
);

/*==============================================================*/
/* Table: ORDER_DETAILS                                         */
/*==============================================================*/
create table ORDER_DETAILS 
(
   REGISTRY_ID          INTEGER               not null,
   PRODUCT_ID           INTEGER               not null,
   QUANTITY             INTEGER               not null,
   DISCOUNT             FLOAT                 not null,
   PRICE                FLOAT                 not null,
   constraint PK_ORDER_DETAILS primary key (REGISTRY_ID, PRODUCT_ID)
);

/*==============================================================*/
/* Index: HAS_FK                                                */
/*==============================================================*/
create index HAS_FK on ORDER_DETAILS (
   REGISTRY_ID ASC
);

/*==============================================================*/
/* Index: HAS_ONE_FK                                            */
/*==============================================================*/
create index HAS_ONE_FK on ORDER_DETAILS (
   PRODUCT_ID ASC
);

/*==============================================================*/
/* Table: PRODUCT                                               */
/*==============================================================*/
create table PRODUCT 
(
   PRODUCT_ID           INTEGER              not null,
   ARTIST_ID            INTEGER              not null,
   DESCRIPTION          VARCHAR2(1000)       not null,
   IMAGE		        VARCHAR2(80)         not null,
   RELEASE_DATE         INTEGER              not null,
   RATING               FLOAT                not null,
   VOTES                INTEGER              not null,
   ADDED_DATE           DATE                 not null,
   CURRENT_PRICE        FLOAT	             not null,
   STOCK                INTEGER              not null,
   NUM_SELLS            INTEGER              not null,
   constraint PK_PRODUCT primary key (PRODUCT_ID)
);

/*==============================================================*/
/* Index: OF_FK                                                 */
/*==============================================================*/
create index OF_FK on PRODUCT (
   ARTIST_ID ASC
);

/*==============================================================*/
/* Table: SONG                                                  */
/*==============================================================*/
create table SONG 
(
   PRODUCT_ID           INTEGER              not null,
   ALB_PRODUCT_ID       INTEGER              null,
   SONG_NAME			VARCHAR2(100)        not null,
   SONG_LENGTH          VARCHAR2(10)         not null,
   SONG_GENRE           VARCHAR2(50)         not null,
   SONG_NUMBER          INTEGER              null,
   constraint PK_SONG primary key (PRODUCT_ID)
);

/*==============================================================*/
/* Index: HAS_SEVERAL_FK                                        */
/*==============================================================*/
create index HAS_SEVERAL_FK on SONG (
   ALB_PRODUCT_ID ASC
);

alter table ALBUM
   add constraint FK_ALBUM_INHERITAN_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID);

alter table MERCHANDISE
   add constraint FK_MERCHAND_INHERITAN_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID);

alter table MAIN_ORDER
   add constraint FK_ORDER_MAKES_CLIENT foreign key (CLIENT_ID)
      references CLIENT (CLIENT_ID);

alter table ORDER_DETAILS
   add constraint FK_ORDER_DE_HAS_ORDER foreign key (REGISTRY_ID)
      references MAIN_ORDER (REGISTRY_ID);

alter table ORDER_DETAILS
   add constraint FK_ORDER_DE_HAS_ONE_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID);

alter table PRODUCT
   add constraint FK_PRODUCT_OF_ARTIST foreign key (ARTIST_ID)
      references ARTIST (ARTIST_ID);

alter table SONG
   add constraint FK_SONG_HAS_SEVER_ALBUM foreign key (ALB_PRODUCT_ID)
      references ALBUM (PRODUCT_ID);

alter table SONG
   add constraint FK_SONG_INHERITAN_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID);
	  
	  
CREATE OR REPLACE TRIGGER deleteSong
AFTER
DELETE ON song
FOR EACH ROW
DECLARE

BEGIN
		DELETE FROM product p
		WHERE product_id = :OLD.product_id;
	
END;
/


CREATE OR REPLACE TRIGGER deleteMerch
AFTER
DELETE ON merchandise
FOR EACH ROW
DECLARE

BEGIN
		DELETE FROM product p
		WHERE p.product_id = :OLD.product_id;
	
END;
/


CREATE OR REPLACE TRIGGER deleteAlbumSongs
BEFORE
DELETE ON album
FOR EACH ROW
DECLARE

BEGIN 
	DELETE FROM song s
	WHERE s.alb_product_id = :OLD.product_id;
END;
/

CREATE OR REPLACE TRIGGER deleteAlbumProduct
AFTER
DELETE ON album
FOR EACH ROW
DECLARE

BEGIN
	DELETE FROM product p
	WHERE p.product_id = :OLD.product_id;
END;
/

CREATE OR REPLACE TRIGGER deleteArtist
AFTER
DELETE ON artist
FOR EACH ROW
DECLARE

BEGIN
	DELETE FROM song s
		WHERE s.product_id IN ( SELECT product_id 
									FROM product
									WHERE artist_id = :OLD.artist_id );
	DELETE FROM album al
		WHERE al.product_id IN (SELECT product_id
								FROM product
								WHERE artist_id = :OLD.artist_id);
	DELETE FROM merchandise m
		WHERE m.product_id IN (SELECT product_id
								FROM product
								WHERE artist_id = :OLD.artist_id);
END;
/


CREATE OR REPLACE TRIGGER decreaseCredits
AFTER
INSERT ON main_order
FOR EACH ROW
DECLARE

BEGIN
	UPDATE client
	SET credits = credits - :new.total_price
	WHERE upper(client_id) = upper(:new.client_id);
END;
/

CREATE OR REPLACE TRIGGER sellItem
AFTER
INSERT ON order_details
FOR EACH ROW
DECLARE

BEGIN
	UPDATE product
	SET num_sells = num_sells + :new.quantity,
	stock = stock - :new.quantity
	WHERE product_id = :new.product_id
	AND stock > -1;
END;
/

