# encoding = utf-8

require 'hpricot'
require 'zlib'
require 'open-uri'

class Lastfm
	
	def initialize()
	end
	
	def getOrclStr(string)
		orclString = string.gsub("'","''")
		if orclString[0] == "'"
			orclString = "'" + orclString
		end
		if orclString[orclString.length-1] == "'"
			orclString = orclString + "'"
		end
		
		orclString
	end
	
	
	def addArtist(name)
		url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{name.gsub(' ','+')}&api_key=8ea76991c5d4936f71710eb66b2e63ac" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url))
		image = String.new
		bio = String.new

		doc = Hpricot resp.body
		
		(doc/"lfm").each do |err|
			if err.attributes["status"] == 'failed'
				return -3
			end
		end
	  
		
		(doc/"lfm/artist/image").each do |ing|
			if ing.attributes["size"] == 'large'
				url = "http://tinyurl.com/api-create.php?url=#{ing.inner_html}"
				resp = Net::HTTP.get_response(URI.parse(url))
				image = resp.body
			end
		end
		
		
		bio = getOrclStr((doc/"lfm/artist/bio/summary").inner_html.gsub(']]>',"").gsub('<![CDATA[',""))
		
		result = $manage.addArtist(name, image, bio)
		result
	end	
	
	
	#Use Last.fm API to get information we want about this album
	def addAlbum(name, length, genre, label, artist_id, price, stock)

		artist_name = $get.artistName(artist_id)

		if (artist_name[0])
			url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=#{artist_name[0].gsub(' ','+')}&album=#{name.gsub(' ','+')}&api_key=8ea76991c5d4936f71710eb66b2e63ac"
			resp = Net::HTTP.get_response(URI.parse(url)).body
			arr = Array.new
			date = String.new

			doc = Hpricot resp

			(doc/"lfm").each do |err|
  		  if err.attributes["status"] == 'failed'
  		    arr << -3
  		    return arr
  	    end
  	  end

			arr[0] = getOrclStr((doc/"lfm/album/wiki/summary").inner_html.gsub(']]>','').gsub('<![CDATA[',''))

			if (arr[0]==nil || arr[0].length<5)
				arr[0] = "N/A"
			end

			(doc/"lfm/album/image").each do |r|
				if r.attributes["size"] == 'large'
					arr[1] = r.inner_html
				end
			end

			date = (doc/"lfm/album/releasedate").inner_html
			if (date.length<5)
				arr[2] = -1
			else
				i=0
				while i < date.length
					if date[i].chr == ','
						arr[2] = date[i-4, 4]
						break
					end
					i=i+1
				end
			end

			i=3
			(doc/"lfm/album/tracks/track/name").each do |r|
				arr[i] = getOrclStr(r.inner_html)
				i=i+1
			end

			result = Array.new
			result = $manage.addAlbum(name, length, genre, label, artist_id, arr[0], arr[1], arr[2], price, stock)

			unless result.first == 0
			  return result
		  end

			song_length = "3:00"
			song_genre = "Other"
			song_desc = "N/A"

			i = 3		
			while i < arr.length			
				res = $manage.addSong(result[1].to_i, arr[i], song_length, genre, (i-2), artist_id, song_desc, arr[1], arr[2], '0.99', '-1')

				unless res == 0
				  result[0] = -5
				  $db.execute("rollback")
				  return result;
			  end

				i=i+1
			end
		else
		  result = Array.new
		  result << -4
			return result
		end
		$db.execute("commit")
		result
	end
	
	
	def updateArtist(artist_id)
		res = get_artist(name)
		$db.execute("	UPDATE artist 
						SET artist_image = '#{res[0]}' ,
						artist_bio = '#{res[1]}'
						WHERE artist_id = #{artist_id})
					")
					
		$db.execute("Commit")
	end
	
	
	def updateAlbum(artist_name,album_name)
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
		
		#api_key8ea76991c5d4936f71710eb66b2e63acmethodauth.getSessiontokenada733945e8a06a5eff32814244de55bec28bf8d372e5c1f1531603ba606a561
			
		
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