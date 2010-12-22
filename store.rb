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
	enable :sessions
end

before do
  if session[:id]
    @logged = true
  else
    @logged = false
  end
end

get '/' do
  erb :index
end

get '/register' do
  if session[:id]
    redirect '/'
  end
  @message=params[:message]
  if @message
    @message="Username already in use!"
  end
  erb :register
end

post '/register' do
  res = $db.select("select client_id from client where upper(client_id) like upper('#{params[:username]}')")
  unless res[0]
    $db.execute("insert into client values('#{params[:username]}','#{params[:address]}',#{params[:phone]}, '#{params[:name]}', '#{params[:passcode]}', '#{params[:email]}')")
    $db.execute("commit")
    session[:id] = params[:username]
    redirect '/'
  else
    redirect '/register?message=error'
  end
end

post '/login' do
  res = $db.select("select client_id from client where upper(client_id) like upper('#{params[:username]}') and password like '#{params[:password]}'")
  if res[0]
    session[:id] = params[:username]
  end
  
  redirect '/'
end

get '/logout' do
  session[:id] = nil
  redirect '/'
end

get '/artist/:id' do
  $lf.update_artist(String.new(params[:id]))
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