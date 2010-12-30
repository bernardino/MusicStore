
class Manage
	
	def initialize()
	end
	
	
	def addArtist(artist_name, artist_image, artist_bio)
		$db.execute("	INSERT INTO artist(artist_id, artist_name, artist_image, artist_bio)
						VALUES(artist_number.nextval, '#{artist_name}', '#{artist_image}', '#{artist_bio}')
					")
		$db.execute("Commit")
	end
	
	
	def addProduct(product_id, artist_id, description, image, release_date, current_price, stock)
		$db.execute("	INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
						VALUES(#{product_id}, #{artist_id}, '#{description}', '#{image}', #{release_date}, 0, 0, sysdate, "+current_price+", "+stock+", 0)
					")
	end
	
	
	def addAlbum(product_id, album_name, album_length, album_genre, album_label)
		$db.execute("	INSERT INTO album(product_id, album_name, album_length, album_genre, album_label)
						VALUES(#{product_id}, '#{album_name}', '#{album_length}', '#{album_genre}', '#{album_label}')
					")
		$db.execute("Commit")
	end
	
	
	def addSong(product_id, alb_product_id, song_name, song_length, song_genre, song_number)
		$db.execute("	INSERT INTO song(product_id, alb_product_id, song_name, song_length, song_genre, song_number)
						VALUES(#{product_id}, #{alb_product_id}, '#{song_name}', '#{song_length}', '#{song_genre}', #{song_number})
					")
		$db.execute("Commit")
	end
	
	
	def addMerch(product_id, merchandise_name)
		$db.execute("	INSERT INTO merchandise(product_id, merchandise_name)
						VALUES(#{product_id}, '#{merchandise_name}')
					")
		$db.execute("Commit")
	end
	
	
	def addClient(username, password, name, address, telephone, email)
		$db.execute("	INSERT INTO client(client_id, password, name, address, telephone, email)
						VALUES('#{username}', '#{password}', '#{name}', '#{address}', '#{telephone}', '#{email}')
					")
		$db.execute("Commit")
	end
	
	
	def addOrder(client_id,orders,total_price)
		
		res = $db.select("SELECT order_number.nextval FROM DUAL")
		
		$db.execute("	INSERT INTO main_order(registry_id, client_id, total_price, order_date)
						VALUES(#{res[0]},'#{client_id}', #{total_price}, sysdate)
					")
					
		orders.keys.each do |i|
			quantity = orders[i][0]
			item_price = orders[i][3]/ quantity
			product_id = i
			
			$db.execute("	INSERT INTO order_details(registry_id, product_id, quantity, discount, price)
							VALUES(#{res[0]}, #{product_id}, #{quantity}, 0, #{item_price})
						")
		
		end
		
		$db.execute("Commit")
	end
	
	
	
	def deleteArtist(artist_id)
		$db.execute("	DELETE
						FROM artist
						WHERE artist_id = '#{artist_id}'
					")
		$db.execute("Commit")
	end
	
	
	def deleteAlbum(product_id)
		$db.execute("	DELETE
						FROM album
						WHERE product_id = '#{product_id}'
					")
		$db.execute("Commit")
	end
	
	
	def deleteSong(product_id)
		$db.execute("	DELETE
						FROM song
						WHERE product_id = '#{product_id}'
					")
		$db.execute("Commit")
	end
	
	
	def deleteMerch(product_id)
		$db.execute("	DELETE
						FROM merchandise
						WHERE product_id = '#{product_id}'
					")
		$db.execute("Commit")
	end
	
	
	def deleteClient(client_id)
		$db.execute("	DELETE
						FROM client
						WHERE client_id = '#{client_id}'
					")
		$db.execute("Commit")
	end
end