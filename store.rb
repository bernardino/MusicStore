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

configure do
	$db = Database.new
end

get '/' do
  erb :index
end

get '/artist/:id' do
	res = $db.select("SELECT artist_name from artist")
	@artistID = res.last
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