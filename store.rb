require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'yaml'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'
require 'rexml/document'
<<<<<<< HEAD
require './database.rb'

configure do
	$db = Database.new
end
=======
require './cenas'
>>>>>>> bac9e0c394ceffd2228f3d380269a4c113e9c9c2

get '/' do
  erb :index
end

get '/artist/:id' do
<<<<<<< HEAD
	res = $db.select("SELECT artist_name from artist")
	@artistID = res.last
=======
	@artistID = params[:id]
	#db.select("SELECT artist_id from artist") do |r|
	#	@artistID = r.last
	#end
	url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{params[:id]}&api_key=b25b959554ed76058ac220b7b2e0a026" #LAST.FM REST API
	resp = Net::HTTP.get_response(URI.parse(url)).body
	
	doc = REXML::Document.new resp
	doc.elements.each("lfm/artist/image") do |r|
		if r.attributes["size"] == 'large'
			@image = r.text
		end
	end
	
	doc.elements.each("lfm/artist/bio/summary") do |r|
		@bio = r.text
	end
	
>>>>>>> bac9e0c394ceffd2228f3d380269a4c113e9c9c2
  erb :artist
end

get '/song/:id' do
	#@songID = params[:id]
  
	url = 'http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=Cher&api_key=b25b959554ed76058ac220b7b2e0a026' #LAST.FM REST API
	resp = Net::HTTP.get_response(URI.parse(url)).body
	
	doc = REXML::Document.new resp
	doc.elements.each("lfm/artist/image") do |r|
		if r.attributes["size"] == 'large'
			@songID = r.text
		end
		
	end
  erb :song
end

get '/album/:id' do
  @albumID = params[:id]
  
  url = 'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=b25b959554ed76058ac220b7b2e0a026&artist=Cher&album=Believe' #LAST.FM REST API
	resp = Net::HTTP.get_response(URI.parse(url)).body
	
	doc = REXML::Document.new resp
	doc.elements.each("lfm/album/image") do |r|
		if r.attributes["size"] == 'large'
			@image = r.text
		end
		
	end
  
  erb :album
end

get '/search' do
  erb :search
end

get '/merch/:id' do
  @merchID = params[:id]
  erb :merch
end

get '/top' do
  "<h1>Top Chart will soon be available</h1>"
end

get '/*' do
  status 400
  "<h1>Page Not Found!</h1>"
end