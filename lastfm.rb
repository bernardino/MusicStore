require 'hpricot'

class Lastfm
	
	def initialize()
	
	end
	
	def get_artist(name)
		url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{name.gsub(' ','+')}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url))
		arr = Array.new

		doc = Hpricot resp.body
		
		(doc/"lfm/artist/image").each do |ing|
			if ing.attributes["size"] == 'large'
				arr[0] = ing.inner_html
			end
		end
		
		#THIS IS JUST TEMPORARY NEED TO IMPROVE
		arr[1] = (doc/"lfm/artist/bio/summary").inner_html.gsub(']]>',"").gsub('<![CDATA[',"")
		
		
		arr
	end
	
	def create_artist(name)
		exist = get_artist_id(name)
		
		if exist.length == 0
			res = get_artist(name)
			$db.execute("INSERT INTO artist(artist_id,artist_name,artist_image,artist_bio)
						VALUES(artist_number.nextval,
						'#{name}',
						'#{res[0]}',
						'#{res[1]}'
						)"
					)
			$db.execute("Commit")
		end	
	end
	
	def get_artist_id(name)
		res = Array.new $db.select("SELECT artist_id 
							FROM artist 
							WHERE upper(artist_name) LIKE upper('#{name}')
						")
		if res.length > 0
			puts 'Artist already exists on the database'
		else
			puts 'Artist does not exist'
		end
		res
	end
	
	
	def update_artist(name)
		res = get_artist(name)
		$db.execute("UPDATE artist 
					SET artist_image = '#{res[0]}' ,
					artist_bio = '#{res[1]}'
					WHERE upper(artist_name) LIKE upper('#{name}')
					")
					
		$db.execute("Commit")
	end
	
	#Use Last.fm API to get information we want about this album
	def get_album(artist_name,album_name)
		url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=#{artist_name.gsub(' ','+')}&album=#{album_name.gsub(' ','+')}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url)).body
		arr = Array.new
		date = String.new
		
		doc = Hpricot resp
		arr[0] = ' '
		(doc/"lfm/album/image").each do |r|
			if r.attributes["size"] == 'large'
				arr[0] = r.inner_html
			end
		end
		arr[1] = ' '
		arr[1] = (doc/"lfm/album/wiki/summary").inner_html.gsub(']]>','').gsub('<![CDATA[','').gsub(/\\/, '\&\&').gsub(/'/, "''")
			#arr[1] = r.text.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub('&quot;','')#.gsub(/[^\' '-~]/,'')
			
		date = '0'
		date = (doc/"lfm/album/releasedate").inner_html 
		
		i=0
		while i < date.length
			if date[i] == ','
				arr[2] = date[i-4,4]
			end
			i=i+1
		end
		
		i=3
		(doc/"lfm/album/tracks/track/name").each do |r|
			arr[i] = r.inner_html
			i=i+1
		end
		arr	
	end
	
	def update_album(artist_name,album_name)
		res = get_album(artist_name,album_name)
		
		info = $db.select("SELECT product_id
							FROM album
							WHERE upper(album_name) LIKE upper('#{album_name}')"
						 )
		i=0
		if info.length == 0
			puts 'Album with that name does not exist'
		elsif info.length > 1
			while i < info.length
				name = $db.select("SELECT artist_name 
								FROM artist ar, product p
								WHERE ar.artist_id = p.artist_id
								AND ar.artist_id = #{info[i]}"
								 )
				if name == artist_name
					break
				else
					i=i+1
				end
			end
		end
		
		puts res[1]
		
		$db.execute("UPDATE product
					SET description = '#{res[1]}',
					image = '#{res[0]}',
					release_date = #{res[2]}
					WHERE product_id = #{info[i]} "
					)	
		$db.execute("commit")		
	end
	
	
	def create_album(artist_name,album_name)
		res = get_album(artist_name,album_name)
		
		id = $db.select("SELECT artist_id
					FROM artist
					WHERE upper(artist_name) LIKE upper('#{artist_name}')
					")
					
		exist = get_album_id(artist_name,album_name)
		
		if exist == 1
		
			id_product = $db.select("SELECT product_number.nextval FROM dual")
			
			#THE DESCRIPTION MAY CREATE A CONFLICT DUE TO STRANGE CHARACTERS
			$db.execute("INSERT INTO product(product_id,artist_id,current_price,stock,description,image,rating,release_date,votes)
						VALUES(#{id_product[0]},
							#{id[0]},
							15,50,
							'#{res[1]}',
							'#{res[0]}',
							0,
							'#{res[2]}',0)
						")
			
			$db.execute("INSERT INTO album(product_id,album_name,album_length,album_label,album_genre)
						VALUES(#{id_product[0]},'#{album_name}','60m','Merge','Rock')
						")
						
			i = 3		
			while i < res.length
				song_id = $db.select("SELECT product_number.nextval FROM DUAL")
				
				$db.execute("INSERT INTO product(product_id,artist_id,current_price,stock,description,image,rating,release_date,votes)
							VALUES(#{song_id[0]}, 
								#{id[0]},
								1,-1,
								'N/A',
								0,
								'#{res[2]}',0)
							")
				$db.execute("INSERT INTO song(product_id,alb_product_id,song_name,song_length,song_genre,song_number)
							VALUES(#{song_id[0]},
									#{id_product[0]},
									'#{res[i]}',
									'3m',
									'Indie',
									#{(i-2)})
							")
				i=i+1
			end				
					
			$db.execute("Commit")
		else
			puts 'That album already exists'
		end
	
	end
	
	def get_album_id(artist_name,album_name)
		res = $search.album(album_name)
		i=0
		while i < res.length/2
			if res[i+1] == artist_name
				return 0
			else
				return 1
			end
			i=i+2
		end
		return 1;
	end
	
	
	def get_song(artist_name,song_name)
		
	
	
	end


end