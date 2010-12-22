require './database.rb'

#estes gets provavelmente estão todos mal e deviam estar a receber ids em vez de names

class Get
	
	def initialize()
	end
	
	
	def artist(artist_name)
		return $db.select("	SELECT artist_name, artist_bio, artist_image
							FROM artist
							WHERE upper(artist_name) like upper('#{artist_name}')
						")
	end
	
	#falta devolver as songs
	def album(album_name)
		return $db.select("	SELECT artist_name, album_name, image, description, release_date, album_length, album_genre, album_label, rating, votes, current_price
							FROM album al, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = al.product_id
							AND upper(album_name) like upper('#{album_name}')
						")
	end

	
	def song(song_name)
		return $db.select("	SELECT artist_name, DECODE(alb_product_id, null, (	SELECT 'None'
																				FROM dual),
																			(	SELECT album_name
																				FROM album a, song s
																				WHERE upper(song_name) like upper('#{song_name}')
																				AND a.product_id = s.alb_product_id)) album,											
									song_name, song_length, song_genre, song_number, release_date, rating, votes, current_price
							FROM song s, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = s.product_id
							AND upper(song_name) like upper('#{song_name}')
						")
	end	
	
	
	def merchandise(merchandise_name)
		return $db.select("	SELECT artist_name, merchandise_name, image, description, release_date, rating, votes, current_price
							FROM merchandise m, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = m.product_id
							AND upper(merchandise_name) like upper('%#{merchandise_name}%')
						")
	end
	
	
	def client(client_name)
	

	end
	
end