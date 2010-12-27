
class Search
	
	def initialize()
	end
	
	
	def artist(artist_name)
		return $db.select("	SELECT artist_id, artist_name , artist_image
							FROM artist
							WHERE upper(artist_name) like upper('%#{artist_name}%')
							ORDER BY artist_name
						")
	end
	
	
	def album(album_name)
		return $db.select("	SELECT al.product_id, album_name, ar.artist_name, p.artist_id, p.image
							FROM album al, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = al.product_id
							AND upper(album_name) like upper('%#{album_name}%')
							ORDER BY album_name, artist_name
						")
	end

	
	def song(song_name)
		return $db.select("	SELECT s.product_id, song_name, artist_name, DECODE(alb_product_id, null, 'None',(	SELECT album_name
																												FROM album al, song s2
																												WHERE al.product_id = s2.alb_product_id
																												AND s2.song_name = s.song_name
																											)) album_name, image
							FROM song s, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = s.product_id
							AND upper(song_name) like upper('%#{song_name}%')
							ORDER BY song_name, artist_name, album_name
						")
	end
	
	
	def merchandise(merchandise_name)
		return $db.select("	SELECT m.product_id, merchandise_name, artist_name, image
							FROM merchandise m, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = m.product_id
							AND upper(merchandise_name) like upper('%#{merchandise_name}%')
							ORDER BY merchandise_name, artist_name
						")
	end	
	
	def client_by_username(username)
		return $db.select("	SELECT client_id, name
							FROM client
							WHERE upper(client_id) like upper('%#{username}%')
							ORDER BY client_id, name
						")
	
	end
	
	
	def client_by_name(name)
		return $db.select("	SELECT client_id, name
							FROM client
							WHERE upper(name) like upper('%#{name}%')
							ORDER BY name, client_id
						")
	end
end