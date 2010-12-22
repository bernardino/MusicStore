require './database.rb'


class Search
	
	def initialize()
	end
	
	def artist(artist_name)
		return $db.select("	SELECT artist_name
							FROM artist
							WHERE upper(artist_name) like upper('%#{artist_name}%')
						")
	end
	
	def album(album_name)
		return $db.select("	SELECT album_name, artist_name
							FROM album al, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = al.product_id
							AND upper(album_name) like upper('%#{album_name}%')
						")
	end

	def song(song_name)
		return $db.select("	SELECT song_name, artist_name, DECODE(alb_product_id, null, (	SELECT 'None'
																							FROM dual),
																						(	SELECT album_name
																							FROM album a, song s
																							WHERE upper(song_name) like upper('#{song_name}')
																							AND a.product_id = s.alb_product_id)) album_name
							FROM song s, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = s.product_id
							AND upper(song_name) like upper('%#{song_name}%')
						")
	end
	
	
	def merchandise(merchandise_name)
		return $db.select("	SELECT merchandise_name, artist_name
							FROM merchandise m, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = m.product_id
							AND upper(merchandise_name) like upper('%#{merchandise_name}%')
						")
	end
	
	def all(some_name)
		return $db.select("	
						")
	end
	
end