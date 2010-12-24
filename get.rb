
class Get
	
	def initialize()
	end
	
	
	def artist(artist_id)
		return $db.select("	SELECT artist_name, artist_bio, artist_image
							FROM artist
							WHERE artist_id = #{artist_id}
						")
	end
	

	def album(album_id)
		return $db.select("	SELECT artist_name, album_name, image, description, release_date, album_length, album_genre, album_label, rating, votes, current_price
							FROM album al, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = al.product_id
							AND al.product_id = #{album_id}
						")
	end
	
	
	def song(song_id)
		return $db.select("	SELECT artist_name, song_name, DECODE(alb_product_id, null, 'None', (	SELECT album_name
																									FROM album a, song s
																									WHERE a.product_id = s.alb_product_id
																									AND s.product_id = #{song_id}
																								)) album_name,
									song_number, song_length, song_genre, release_date, rating, votes, current_price
							FROM song s, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = s.product_id
							AND s.product_id = #{song_id}
						")
	end
	
	
	def merchandise(merchandise_id)
		return $db.select("	SELECT artist_name, merchandise_name, image, description, release_date, rating, votes, current_price
							FROM merchandise m, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = m.product_id
							AND m.product_id = #{merchandise_id}
						")
	end
	

	def client(client_id)
		return $db.select("	SELECT name, address, telephone, email
							FROM client c
							WHERE c.client_id = #{client_id}
						")
	end
	
	
	def artistAlbums(artist_id)
		return $db.select("	SELECT p.product_id, album_name, image, release_date, album_length, rating, votes, current_price
							FROM album a, product p
							WHERE s.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date DESC;
						")
	end
	
	
	def artistSongs(artist_id)
		return $db.select("	SELECT p.product_id, song_name, DECODE(alb_product_id, null, 'None', (	SELECT album_name
																									FROM album al, song s2
																									WHERE al.product_id = s2.alb_product_id
																									AND s2.song_name = s.song_name
																								)) album_name,
									song_number, song_length, rating, votes, current_price
							FROM song s, product p
							WHERE s.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date DESC, album_name ASC, song_number ASC
						")
	end
	
	
	def artistMerch(artist_id)
		return $db.select("	SELECT p.product_id, merchandise_name, image, release_date, rating, votes, current_price
							FROM merchandise m, product p
							WHERE m.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date;
						")
	end
	
	
	def albumSongs(album_id)
		return $db.select("	SELECT p.product_id, song_number, song_name, song_length, rating, votes, current_price
							FROM song s, product p
							WHERE p.product_id = s.product_id
							AND s.alb_product_id = #{album_id}
							ORDER BY song_number
						")
	end
end