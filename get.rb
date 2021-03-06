
class Get
	
	def initialize()
	end
	
	
	def artist(artist_id)
		return $db.select("	SELECT artist_name, artist_bio, artist_image
							FROM artist
							WHERE artist_id = #{artist_id}
						")
	end
	
	
	def artistToEdit(artist_id)
		return $db.select("	SELECT artist_name, artist_bio, artist_image, artist_id
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
	
	
	def albumToEdit(album_id)
		return $db.select("	SELECT album_name, album_length, album_genre, album_label, artist_id, description, image, release_date, current_price, stock, p.product_id
							FROM album al, product p
							WHERE p.product_id = al.product_id
							AND al.product_id = #{album_id}
						")
	end
	
	
	def song(song_id)
		return $db.select("	SELECT 	artist_name,
									song_name,
									DECODE(alb_product_id, null, 'None', (	SELECT album_name
																			FROM album a, song s
																			WHERE a.product_id = s.alb_product_id
																			AND s.product_id = #{song_id}
																		)) album_name,
									DECODE(song_number, null, 'None', song_number) song_n,
									song_length,
									song_genre,
									release_date,
									rating,
									votes,
									current_price,
									image,
									alb_product_id
							FROM song s, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = s.product_id
							AND s.product_id = #{song_id}
						")
	end
	
	
	def songToEdit(song_id)
		return $db.select("	SELECT song_name, song_length, song_genre, song_number, alb_product_id, artist_id, description, image, release_date, current_price, p.product_id
							FROM song s, product p
							WHERE p.product_id = s.product_id
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
	
	
	def merchToEdit(merchandise_id)
		return $db.select("	SELECT merchandise_name, artist_id, description, image, release_date, current_price, stock, p.product_id
							FROM merchandise m, product p
							WHERE p.product_id = m.product_id
							AND m.product_id = #{merchandise_id}
						")
	end
	
	
	def client(client_id)
		return $db.select("	SELECT name, address, telephone, email
							FROM client c
							WHERE upper(c.client_id) = upper('#{client_id}')
						")
	end
	
	
	def productPrice(product_id)
		return $db.select(" SELECT current_price 
							FROM product 
							WHERE product_id = #{product_id}
						")
	
	end
	
	
	def productStock(product_id)
		return $db.select(" SELECT stock 
							FROM product
							WHERE product_id = #{product_id}
						")
	end
	
	
	def cartStock(orders)
		noStock = Array.new
		
		orders.keys.each do |i|
			if orders[i][2] != 's'
				res = productStock(i)
				if res[0] < orders[i][0]
					noStock << i
				end
			end
		end
		
		return noStock
	end
		
	
	def checkArtist(artist_id)
		return $db.select(" SELECT artist_id 
							FROM artist
							WHERE artist_id = #{artist_id}
						")
	end	


	def checkAlbum(album_id)
		return $db.select(" SELECT product_id 
							FROM album
							WHERE product_id = #{album_id}
						")
	end


	def checkSong(song_id)
		return $db.select(" SELECT product_id 
							FROM song
							WHERE product_id = #{song_id}
						")
	end


	def checkMerch(merch_id)
		return $db.select(" SELECT product_id 
							FROM merchandise
							WHERE product_id = #{merch_id}
						")
	end


	def checkClient(client_id)
		return $db.select(" SELECT client_id 
							FROM client
							WHERE upper(client_id) like upper('#{client_id}')
						")
	end
	
	
	def checkClientPassword(client_id,passcode)
		return $db.select(" SELECT client_id 
							FROM client
							WHERE upper(client_id) like upper('#{client_id}')
							AND password = '#{passcode}'
						")
	end
	
	
	def artistAlbums(artist_id)
		return $db.select("	SELECT p.product_id, album_name, image, release_date, album_length, rating, votes, current_price
							FROM album a, product p
							WHERE a.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date DESC
						")
	end
	
	
	def artist_albums(artist_id)
		return $db.select(" SELECT p.product_id, al.album_name, p.image
							FROM album al, product p
							WHERE al.product_id = p.product_id
							AND p.artist_id = #{artist_id}
						")
	end
	

	def recentlyAddedAlbums()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, al.album_name, ar.artist_name, p.image, ar.artist_id, p.current_price
									FROM product p, album al, artist ar
									WHERE p.product_id = al.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.added_date DESC
								)
							WHERE rownum < 5
						")
	end
	
	
	def recentlyAddedSongs()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, s.song_name, ar.artist_name, p.image, ar.artist_id, p.current_price
									FROM product p, song s, artist ar
									WHERE p.product_id = s.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.added_date DESC
								)
							WHERE rownum < 5
						")
	end	
	
	
	def recentlyAddedMerch()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, m.merchandise_name, ar.artist_name, p.image, ar.artist_id, p.current_price
									FROM product p, merchandise m, artist ar
									WHERE p.product_id = m.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.added_date DESC
								)
							WHERE rownum < 5
						")
	end
	
	
	def topAlbums()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, al.album_name, ar.artist_name, p.image, ar.artist_id
									FROM product p, album al, artist ar
									WHERE p.product_id = al.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.num_sells DESC
								)
							WHERE rownum < 11
						")
	end
	
	
	def topSongs()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, s.song_name, ar.artist_name, p.image, ar.artist_id
									FROM product p, song s, artist ar
									WHERE p.product_id = s.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.num_sells DESC
								)
							WHERE rownum < 11
						")
	end
	
	
	def topMerch()
		return $db.select(" SELECT *
							FROM (	SELECT p.product_id, m.merchandise_name, ar.artist_name, p.image, ar.artist_id
									FROM product p, merchandise m, artist ar
									WHERE p.product_id = m.product_id
									AND p.artist_id = ar.artist_id
									ORDER by p.num_sells DESC
								)
							WHERE rownum < 11
						")
	end
	
	
	def artistName(artist_id)
		return $db.select("	SELECT artist_name
							FROM artist
							WHERE artist_id = #{artist_id}
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
	
	
	def artistSingleSongs(artist_id)
		return $db.select("	SELECT p.product_id, song_name, song_length, image
							FROM song s, product p
							WHERE s.alb_product_id IS NULL
							AND s.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date DESC
						")
	end
	
	
	def artistMerch(artist_id)
		return $db.select("	SELECT p.product_id, merchandise_name, image, release_date, rating, votes, current_price
							FROM merchandise m, product p
							WHERE m.product_id = p.product_id
							AND p.artist_id = #{artist_id}
							ORDER BY release_date
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
	
	def allArtists()
		return $db.select("	SELECT artist_id, artist_name , artist_image
							FROM artist
							ORDER BY artist_name
						")
	end
	
	def allAlbums()
		return $db.select("	SELECT al.product_id, album_name, ar.artist_name, p.artist_id, p.image
							FROM album al, artist ar, product p
							WHERE ar.artist_id = p.artist_id
							AND p.product_id = al.product_id
							ORDER BY album_name, artist_name
						")
	end
	
	def allMerch()
		return $db.select("	SELECT m.product_id, merchandise_name, p.artist_id, artist_name, image
							FROM merchandise m, artist a, product p
							WHERE a.artist_id = p.artist_id
							AND p.product_id = m.product_id
							ORDER BY merchandise_name, artist_name
						")
	end
	
end