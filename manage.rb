require 'oci8'
class Manage
	
	def initialize()
	end
	
	
	def addArtist(artist_name, artist_image, artist_bio)
		cursor = $db.conn.parse("BEGIN addArtist('#{artist_name}','#{artist_bio}','#{artist_image}',:b1); END;")
		cursor.bind_param(0, -1, Integer)
		cursor.exec()
    
		cursor[0] # :b1 result of the procedure
	end
	
	
	def addProduct(product_id, artist_id, description, image, release_date, current_price, stock)
		$db.execute("	INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
						VALUES(#{product_id}, #{artist_id}, '#{description}', '#{image}', #{release_date}, 0, 0, sysdate, "+current_price+", "+stock+", 0)
					")
		$db.execute("Commit")
	end
	
	
	def addAlbum(album_name, album_length, album_genre, album_label, artist_id, description, image, release_date, current_price, stock)
		cursor = $db.conn.parse("BEGIN addAlbum('#{album_name}','#{album_length}','#{album_genre}','#{album_label}','#{artist_id}','#{description}','#{image}',#{release_date},#{current_price},#{stock},:b1,:b2); END;")
    cursor.bind_param(':b1', -1, Integer)
    cursor.bind_param(':b2', -1, Integer)
    
    cursor.exec()
    
    arr = Array.new
    
    arr << cursor[':b1']
    arr << cursor[':b2']
    arr # :b1 result of the procedure
	end
	
	
	def addSong(alb_product_id, song_name, song_length, song_genre, song_number, artist_id, description, image, release_date, current_price, stock)
		cursor = $db.conn.parse("BEGIN addSong(#{alb_product_id}, '#{song_name}', '#{song_length}', '#{song_genre}', #{song_number}, #{artist_id}, '#{description}', '#{image}',#{release_date},#{current_price},#{stock},:b1); END;")
    cursor.bind_param(0, -1, Integer)
    
    cursor.exec()
		cursor[0]
	end
	
	
	def addMerch(merchandise_name, artist_id, description, image, release_date, current_price, stock)
		cursor = $db.conn.parse("BEGIN addMerch('#{merchandise_name}',#{artist_id},'#{description}','#{image}', #{release_date}, #{current_price}, #{stock},:b1); END;")
    cursor.bind_param(0, -1, Integer)
    cursor.exec()
    
    cursor[0] # :b1 result of the procedure
	end
	
	
	def addClient(username, password, name, address, telephone, email)
		$db.execute("	INSERT INTO client(client_id, password, name, address, telephone, email, credits)
						VALUES('#{username}', '#{password}', '#{name}', '#{address}', '#{telephone}', '#{email}', 0)
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
		
	
	
	
	
	
	
	
	def editArtist(artist_name, artist_bio, artist_image, artist_id)
		$db.execute("	UPDATE artist
						SET artist_name = '#{artist_name}', 
							artist_bio = '#{artist_bio}',
							artist_image = '#{artist_image}'
						WHERE artist_id = #{artist_id}
					")
		$db.execute("Commit")
	end
	
	
	def editAlbum(album_name, album_length, album_genre, album_label, artist_id, description, image, release_date, current_price, stock, product_id)
		$db.execute("	UPDATE album
						SET album_name = '#{album_name}',
							album_length = '#{album_length}',
							album_genre = '#{album_genre}',
							album_label = '#{album_label}'
						WHERE product_id = #{product_id}
					")
		
		$db.execute("	UPDATE product
						SET artist_id = #{artist_id},
							description = '#{description}',
							image = '#{image}',
							release_date = '#{release_date}',
							current_price = #{current_price},
							stock = #{stock}
						WHERE product_id = #{product_id}
					")
		
		$db.execute("Commit")
	end
	
	
	def editSong(song_name, song_length, song_genre, song_number, album_id, artist_id, description, image, release_date, current_price, product_id)
		begin
		  $db.execute("	UPDATE song
						SET song_name = '#{song_name}',
							song_length = '#{song_length}',
							song_genre = '#{song_genre}',
							song_number = #{song_number},
							alb_product_id = #{album_id}
						WHERE product_id = #{product_id}
					")
		rescue
		  $db.execute("rollback")
		  return -1
	  end
	  
	  begin
		  $db.execute("	UPDATE product
						SET artist_id = #{artist_id},
							description = '#{description}',
							image = '#{image}',
							release_date = #{release_date},
							current_price = #{current_price}
						WHERE product_id = #{product_id}
					")
		rescue
		  $db.execute("rollback")
		  return -1
	  end
		$db.execute("Commit")
		return 0
	end
	
	
	def editMerch(merchandise_name, artist_id, description, image, release_date, current_price, stock, product_id)
		begin
		  $db.execute("	UPDATE merchandise
						SET merchandise_name = '#{merchandise_name}'
						WHERE product_id = #{product_id}
					")
		rescue
		  $db.execute("rollback")
		  return -1
		end
		
		begin
		  $db.execute("	UPDATE product
						SET artist_id = #{artist_id},
							description = '#{description}',
							image = '#{image}',
							release_date = #{release_date},
							current_price = #{current_price},
							stock = #{stock}
						WHERE product_id = #{product_id}
					")
		$db.execute("Commit")
	  rescue
	    $db.execute("rollback")
	    return -1
	  end
	  return 0
	end
	
	
	def deleteArtist(artist_id)
		$db.execute("	DELETE
						FROM artist
						WHERE artist_id = #{artist_id}
					")
		$db.execute("Commit")
	end
	
	
	def deleteAlbum(product_id)
		$db.execute("	DELETE
						FROM album
						WHERE product_id = #{product_id}
					")
		$db.execute("Commit")
	end
	
	
	def deleteSong(product_id)
		$db.execute("	DELETE
						FROM song
						WHERE product_id = #{product_id}
					")
		$db.execute("Commit")
	end
	
	
	def deleteMerch(product_id)
		$db.execute("	DELETE
						FROM merchandise
						WHERE product_id = #{product_id}
					")
		$db.execute("Commit")
	end
	
	
	def deleteClient(client_id)
		$db.execute("	DELETE
						FROM client
						WHERE client_id = #{client_id}
					")
		$db.execute("Commit")
	end
end