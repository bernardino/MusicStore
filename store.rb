require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'
require 'rexml/document'

require './database.rb'
require './lastfm.rb'
require './search.rb'
require './get.rb'

configure do
	$db = Database.new
	$lf = Lastfm.new
	$search = Search.new
	$get = Get.new
	#$lf.update_artist(params[:id])
	enable :sessions
end

before do
  if session[:id]
    @logged = true
  else
    @logged = false
  end
	#$lf.create_artist(params[:id])
	#$lf.get_artist_id THIS METHOD MIGHT HAVE A BUGGGGGGGG PLEASE BEWARE
	#$lf.update_album(params[:name],params[:id])
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
	res = $get.artist(params[:id])
	
	@artistID = String.new(params[:id])
	@bio = res[1]
	@image = res[2]
  erb :artist
end

get '/song/:id' do
	#@songID = params[:id]
	
	
  erb :song
end

get '/artist/:name/album/:id' do
	@artistID = params[:name]
	@albumID = params[:id]
	res = $db.select("SELECT artist_name, album_name, image, description, release_date, album_length, album_genre, album_label, rating, votes, current_price, al.product_id
						FROM album al, artist ar, product p
						WHERE ar.artist_id = p.artist_id
						AND p.product_id = al.product_id
						AND upper(album_name) like upper('#{params[:id]}')
					")
	@image = res[2]
	@albumInfo = res[3]
	@albumDate = res[4]
	@albumLength = res[5]
	@albumGenre = res[6]
	@albumLabel = res[7]
	@albumRating = res[8]
	@albumPrice = res[10]
	album_id = res[11]
	
	@songs = $db.select("SELECT song_number, song_name, song_length
							FROM song
							WHERE alb_product_id = #{album_id}
							ORDER BY song_number
						")
						
	#$lf.create_album(params[:name],params[:id])
	
	#$lf.update_album(params[:name],params[:id])
	
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