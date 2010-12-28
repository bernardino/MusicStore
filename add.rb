
class Add
	
	def initialize()
	end
	
	
	def artist(artist_name, artist_image, artist_bio)
		$db.execute("	INSERT INTO artist(artist_id, artist_name, artist_image, artist_bio)
						VALUES(artist_number.nextval, '#{artist_name}', '#{artist_image}', #{artist_bio}')
					")
		$db.execute("Commit")
	end
	
	
	def product(product_id, artist_id, description, image, release_date, current_price, stock)
		$db.execute("	INSERT INTO product(product_id, artist_id, description, image, release_date, rating, votes, added_date, current_price, stock, num_sells)
						VALUES(#{product_id}, #{artist_id}, "+description+", '#{image}', #{release_date}, 0, 0, sysdate, "+current_price+", "+stock+", 0)
					")
		$db.execute("Commit")
	end
	
	
	def album(product_id, album_name, album_length, album_label, album_genre)
		$db.execute("	INSERT INTO album(product_id, album_name, album_length, album_label, album_genre)
						VALUES(#{product_id}, '#{album_name}', '#{album_length}', '#{album_label}', '#{album_genre}')
					")
		$db.execute("Commit")
	end
	
	
	def song(product_id, alb_product_id, song_name, song_length, song_genre, song_number)
		$db.execute("	INSERT INTO song(product_id, alb_product_id, song_name, song_length, song_genre, song_number)
						VALUES(#{product_id}, #{alb_product_id}, '#{song_name}', '#{song_length}', '#{song_genre}', '#{song_number}')
					")
		$db.execute("Commit")
	end
	
	
	def merch(product_id, merchandise_name)
		$db.execute("	INSERT INTO merchandise(product_id, merchandise_name)
						VALUES(#{product_id}, '#{merchandise_name}')
					")
		$db.execute("Commit")
	end
end