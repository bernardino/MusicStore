# encoding = utf-8

require 'hpricot'

class Lastfm
	
	def initialize()
	end
	
	
	def addArtist(name)
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
		
		$manage.addArtist(name, arr[0], arr[1])
	end	
	
	
	#Use Last.fm API to get information we want about this album
	def addAlbum(artist_name, album_name)
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
		arr[1] = (doc/"lfm/album/wiki/summary").inner_html.gsub(']]>','').gsub('<![CDATA[','')
			#arr[1] = r.text.gsub(/\\/, '\&\&').gsub(/'/, "''").gsub('&quot;','')#.gsub(/[^\' '-~]/,'')


		date = (doc/"lfm/album/releasedate").inner_html
		
		i=0
		while i < date.length
			if date[i].chr == ','
				arr[2] = date[i-4, 4]
				break
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

	
	def add_album(artist_name, album_name)
		res = get_album(artist_name, album_name)
		
		id = $db.select("	SELECT artist_id
							FROM artist
							WHERE upper(artist_name) LIKE upper('#{artist_name}')
						")
					
		exist = get_album_id(artist_name, album_name)
		
		if exist == 1
		
			product_id = $db.select("SELECT product_number.nextval FROM dual")
			#THE DESCRIPTION MAY CREATE A CONFLICT DUE TO STRANGE CHARACTERS
			$manage.addProduct(product_id[0], id[0], 'description', res[0], res[2], '15', '50')
			
			$manage.addAlbum(product_id[0], album_name, '60m', 'Merge', 'Rock')

			
			i = 3		
			while i < res.length
				song_id = $db.select("SELECT product_number.nextval FROM DUAL")
				
				$manage.addProduct(song_id[0], id[0], 'description', res[0], res[2], '0.99', '-1')
				
				$manage.addSong(song_id[0], product_id[0], res[i], '3m', 'Indie', (i-2))
				
				i=i+1
			end				
					
			$db.execute("Commit")
		else
			puts 'That album already exists'
		end
	end
	
	
	def get_artist_id(name)
		res = Array.new
		
		res = $db.select("SELECT artist_id 
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
		$db.execute("	UPDATE artist 
						SET artist_image = '#{res[0]}' ,
						artist_bio = '#{res[1]}'
						WHERE upper(artist_name) LIKE upper('#{name}')
					")
					
		$db.execute("Commit")
	end
	
	
	def update_album(artist_name,album_name)
		res = get_album(artist_name,album_name)
		
		info = $db.select("SELECT product_id
							FROM album
							WHERE upper(album_name) LIKE upper('#{album_name}')"
						 )
		i=0
		if info.length == 0
			puts 'There is no Album with that name'
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
					WHERE product_id = #{info[i]}"
					)	
		$db.execute("commit")		
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
	
	
	def recommended_artists()
	
		url = "http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=8ea76991c5d4936f71710eb66b2e63ac"
		resp = Net::HTTP.get_response(URI.parse(url)).body
		doc = Hpricot resp
		token = (doc/"lfm/token").inner_html
		
		puts 'token'
		puts token
		
		url = "http://www.last.fm/api/auth/?api_key=8ea76991c5d4936f71710eb66b2e63ac&token=#{token}"
		resp = Net::HTTP.get_response(URI.parse(url)).body
		doc = Hpricot resp
		
		
		puts doc
		
		api_sig = Digest::MD5.hexdigest("api_key8ea76991c5d4936f71710eb66b2e63acmethodauth.getSessiontoken#{token}ec28bf8d372e5c1f1531603ba606a561")
		
		url = "http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=8ea76991c5d4936f71710eb66b2e63ac&api_sig=#{api_sig}&token=#{token}"
		resp = Net::HTTP.get_response(URI.parse(url)).body
		doc = Hpricot resp
		
		key = (doc/"lfm/sessin/key").inner_html
		
		puts 'key'
		puts key
		
		url = "http://ws.audioscrobbler.com/2.0/?method=user.getRecommendedArtists&api_key=8ea76991c5d4936f71710eb66b2e63ac&api_sig=#{api_sig}&sk=#{key}"
		
		resp = Net::HTTP.get_response(URI.parse(url)).body
		doc = Hpricot resp
		
		puts (doc/"lfm/error").inner_html
	end
end