
class Lastfm
	
	def initialize()
	
	end
	
	def get_artist(name)
		url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{name.gsub(' ','+')}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url)).body
		arr = Array.new
		doc = REXML::Document.new resp
		doc.elements.each("lfm/artist/image") do |r|
			if r.attributes["size"] == 'large'
				arr[0] = r.text
			end
		end
		doc.elements.each("lfm/artist/bio/summary") do |r|
			arr[1] = r.text
		end	
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
					WHERE upper(artist_name) LIKE upper('#{name}')")
		$db.execute("Commit")
	end
	
	#Use Last.fm API to get information we want about this album
	def get_album(artist_name,album_name)
		url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=#{artist_name.gsub(' ','+')}&album=#{album_name.gsub(' ','+')}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url)).body
		arr = Array.new
		date = String.new
		
		doc = REXML::Document.new resp
		doc.elements.each("lfm/album/image") do |r|
			if r.attributes["size"] == 'large'
				arr[0] = r.text
			end
		end
		doc.elements.each("lfm/album/wiki/summary") do |r|
			arr[1] = r.text
		end
		doc.elements.each("lfm/album/releasedate") do |r|
			date = r.text
		end
		i=0
		while i < date.length
			if date[i] == ','
				arr[2] = date[i-4,4]
			end
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
					
		#exist = get_album_id(artist_name,album_name)
		
		id_product = $db.select("SELECT product_number.nextval FROM dual")
		puts 'aaa'
		puts res[1]
		
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
					VALUES(#{id_product[0]},'#{album_name}','60','Merge','Rock')
					")
		$db.execute("Commit")
		
	
	end
	
	def get_album_id(artist_name,album_name)
		# TODO
	end


end