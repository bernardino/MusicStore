/*==============================================================*/
/* DBMS name:      ORACLE Version 11g                           */
/* Created on:     06-12-2010 17:41:22                          */
/*==============================================================*/


/*==============================================================*/
/*                      Patch Notes 2.82						*/
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

CREATE sequence product_number
START with 1
INCREMENT by 1
NOCYCLE;


create or replace procedure voting (id in integer, vote in integer) IS

allvotes product.votes%type;
new_rating product.rating%type;
old_rating product.rating%type;

BEGIN
	select votes into allvotes from product where product_id=id;
	select rating into old_rating from product where product_id=id;

	new_rating := (old_rating*allvotes + vote) / (allvotes+1);
	allvotes:=allvotes+1;
	update product set rating = new_rating where product_id=id;
	update product set votes = allvotes where product_id=id;
END; /



/*==============================================================*/
/* Table: ALBUM                                                 */
/*==============================================================*/
create table ALBUM 
(
   PRODUCT_ID           INTEGER               not null,
   ALBUM_NAME			VARCHAR2(100)         not null,
   ALBUM_LENGTH         VARCHAR2(10)          not null,
   ALBUM_LABEL          VARCHAR2(50)          not null,
   ALBUM_GENRE          VARCHAR2(50),
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
/* Table: "ORDER"                                               */
/*==============================================================*/
create table "ORDER" 
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
create index MAKES_FK on "ORDER" (
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

alter table "ORDER"
   add constraint FK_ORDER_MAKES_CLIENT foreign key (CLIENT_ID)
      references CLIENT (CLIENT_ID);

alter table ORDER_DETAILS
   add constraint FK_ORDER_DE_HAS_ORDER foreign key (REGISTRY_ID)
      references "ORDER" (REGISTRY_ID);

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

