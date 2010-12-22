
class Lastfm
	
	def initialize()
	
	end
	
	def update_artist(name)
		url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{name.gsub(' ','+')}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url)).body
		image = String.new
		bio = String.new
		doc = REXML::Document.new resp
		doc.elements.each("lfm/artist/image") do |r|
			if r.attributes["size"] == 'large'
				image = r.text
			end
		end
		doc.elements.each("lfm/artist/bio/summary") do |r|
			bio = r.text
		end
		puts image
		puts bio
		$db.execute("UPDATE artist
					SET artist_image = '#{image}' ,
						artist_bio = '#{bio}'
					WHERE artist_name LIKE '#{name}'")
		$db.execute("Commit")
	end
	
	def update_album(artist_name,album_name)
		url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist='#{artist_name.gsub(' ','+')}&album='#{album_name.gsub(' ','+')}'&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
		resp = Net::HTTP.get_response(URI.parse(url)).body
		image = String.new
		tag = String.new
		description = String.new
		
		doc = REXML::Document.new resp
		doc.elements.each("lfm/album/image") do |r|
			if r.attributes["size"] == 'large'
				image = r.text
			end
		end
		doc.elements.each("lfm/album/toptags/tag") do |r|
			tag	 = r.text
		end
		doc.elements.each("lfm/album/wiki/summary") do |r|
			description = r.text
		end
		puts image
		puts tag
		puts description
	end


end