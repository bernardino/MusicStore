create or replace procedure voting (id in integer, vote in integer) IS
	allvotes product.votes%type;
	new_rating product.rating%type;
	old_rating product.rating%type;
BEGIN
	select votes into allvotes from product
	where product_id=id;
	
	select rating into old_rating from product
	where product_id=id;
	
	new_rating := (old_rating*allvotes + vote) / (allvotes+1);
	allvotes:=allvotes+1;
	
	update product set rating = new_rating where product_id=id;
	update product set votes = allvotes where product_id=id;
	
END;
/