require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'

require './database.rb'
require './lastfm.rb'
require './search.rb'
require './get.rb'

configure do
	$db = Database.new
	$lf = Lastfm.new
	$search = Search.new
	$get = Get.new
	enable :sessions
end

#template(:layout) { :index }

before do
	if session[:id]
		@logged = true
		if session[:id].downcase == 'admin'
			@admin = true
		else
			@admin = false
		end
	else
		@logged = false
	end
  
  unless session[:orders]
    session[:orders] = {}
    session[:total] = 0
  end
  
end

=begin
helpers do
  #def partial template
  #  erb template.to_sym, :layout => false
  #end
  
  def partial(template, options={})
     options.merge!(:layout => false)
     erb template.to_sym, options
   end
end
=end

get '/' do
	@albums = $get.recentlyAddedAlbums()
	@songs = $get.recentlyAddedSongs()
	@merch = $get.recentlyAddedMerch()
  erb :index
end

get '/register' do
  if session[:id]
    redirect '/'
  end
  @message=params[:message]
  if @message
    @message = "Username already in use!"
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
  session[:orders] = {}
  session[:total] = 0
  redirect '/'
end

get '/artist/:id' do
	res = $get.artist(params[:id])
	@artistID = res[0]
	@bio = res[1]
	@image = res[2]
	@albums = $get.artist_albums(params[:id])
	
	erb :artist
end


get '/artist/:id' do
	res = $get.artist(params[:id])
	@artistID = res[0]
	@bio = res[1]
	@image = res[2]
	@albums = $get.artist_albums(params[:id])
	
	erb :artist
end


get '/insertArtist/:id' do
	$lf.create_artist(params[:id])
	i = $lf.get_artist_id(params[:id])
	res = $get.artist(i)
	@artistID = res[0]
	@bio = res[1]
	@image = res[2]
	@albums = $get.artist_albums(i)
	
	erb :artist
end

get '/song/:id' do
	@res = $get.song(params[:id])
	
	erb :song
end

get '/artist/:name/album/:id' do
	@res = $get.album(params[:id])
	@songs = $db.select("	SELECT song_number, song_name, song_length
							FROM song
							WHERE alb_product_id = #{params[:id]}
							ORDER BY song_number
						")
	@albums = $get.artist_albums(params[:name])
	
	erb :album
end


get '/artist/:artist_name/insertAlbum/:album_name' do
	$lf.create_album(params[:artist_name], params[:album_name])
end


get '/search/:id' do
	@res = $search.artist(params[:id])
	
	
  erb :search
end

get '/artists' do


end

get '/albums' do


end


get '/merchandising' do


end

post '/search' do
	@options = params[:option] #artist / merch / song / album
	@searchTerm = params[:term]
	if @options == 'artist'
		@res = $search.artist(@searchTerm)
	elsif @options == 'album'
		@res = $search.album(@searchTerm)
	elsif @options == 'song'
		@res = $search.song(@searchTerm)
	elsif @options == 'merch'
		@res = $search.merchandise(@searchTerm)
	end
	
  
  erb :search
end

get '/merch/:id' do
	res = $get.merchandise(params[:id])
	@artist = res[0]
	@merchID = res[1]
	@image = res[2]
	@desc = res[3]
	@date = res[4]
	@rating = res[5]
	@votes = res[6] 
	@price = res[7]
	erb :merch
end

get '/top' do
  @albums = $get.topAlbums()
  @songs = $get.topSongs()
  @merch = $get.topMerch()
  
  erb :charts
end

get '/addorder' do
  price = $db.select("select current_price from product where product_id = '#{params[:id]}'")
  if session[:orders][params[:id]]
    session[:orders][params[:id]][0] += 1
    session[:orders][params[:id]][3]+= price[0]
  else
    session[:orders][params[:id]] = [] #[0]->quantity, [1]->name, [2]->type, [3]->price
    if params[:type]=='a' #album
      res = $db.select("select album_name from album where product_id = '#{params[:id]}'")
      session[:orders][params[:id]] << 1
      session[:orders][params[:id]] << res[0]
      session[:orders][params[:id]] << params[:type]
      session[:orders][params[:id]] << price[0]
    elsif params[:type]=='m' #merchandise
      res = $db.select("select merchandise_name from album where product_id = '#{params[:id]}'")
      session[:orders][params[:id]] << 1
      session[:orders][params[:id]] << res[0]
      session[:orders][params[:id]] << params[:type]
      session[:orders][params[:id]] << price[0]
    elsif params[:type]=='s' #song
      res = $db.select("select song_name from album where product_id = '#{params[:id]}'")
      session[:orders][params[:id]] << 1
      session[:orders][params[:id]] << res[0]
      session[:orders][params[:id]] << params[:type]
      session[:orders][params[:id]] << price[0]
    end
  end
  if session[:total]
    session[:total]+=price[0]
  else
    session[:total] = price[0]
  end
  redirect params[:page]
end

get '/checkout' do
  unless session[:id]
    redirect '/'
  end
  
  erb :checkout
end

get '/removeorder' do
  session[:total]-=session[:orders][params[:id]][3]
  session[:orders].delete(params[:id])
  redirect params[:page]
end

get 'final' do #client adds an order to the database
  redirect '/'
end

get '/addvote' do
  $db.execute("begin voting(#{params[:id]},#{params[:v]}); end;")
  $db.execute("commit")
  redirect params[:page]
end

get '/*' do
  status 400
  "<h1>Page Not Found!</h1>"
end