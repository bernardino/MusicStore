require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'yaml'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'
require 'rexml/document'

require './database.rb'
require './lastfm.rb'

configure do
	$db = Database.new
	$lf = Lastfm.new
	#$lf.update_artist(params[:id])
end

get '/' do
  erb :index
end

get '/artist/:id' do
	res = $db.select("SELECT artist_name,artist_bio,artist_image FROM artist
						WHERE upper(artist_name) like upper('#{params[:id]}')")
	@artistID = String.new(params[:id])
	@bio = res[1]
	@image = res[2]
	#result = $db.select("SELECT album_name")
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
  
  #$lf.update_album(params[:id])
  
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