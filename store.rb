require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'
require 'digest/sha1'

require './database.rb'
require './lastfm.rb'
require './manage.rb'
require './get.rb'
require './search.rb'

configure do
	$db = Database.new
	$lf = Lastfm.new
	$manage = Manage.new
	$get = Get.new
	$search = Search.new
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
		passcode = Digest::SHA1.hexdigest(params[:passcode])
		$manage.addClient(params[:username], passcode, params[:name], params[:address], params[:phone], params[:email])
		session[:id] = params[:username]
		redirect '/'
	else
		redirect '/register?message=error'
	end
end


post '/login' do
	passcode = Digest::SHA1.hexdigest(params[:password])
	res = $db.select("SELECT client_id FROM client WHERE upper(client_id) LIKE upper('#{params[:username]}') and password LIKE '#{passcode}'")
	if res[0]
		session[:id] = params[:username]
	end
  
	redirect params[:p]
end


get '/logout' do
	session[:id] = nil
	session[:orders] = {}
	session[:total] = 0
	redirect '/'
end

get '/addcredits' do
  #$db.execute("update client set credits=#{params[:c]} where client_id='#{session[:id]}'")
  
  redirect params[:page]
end


get '/artist/:id' do
	res = $get.artist(params[:id])
	@artistID = res[0]
	@bio = res[1]
	@image = res[2]
	@albums = $get.artist_albums(params[:id])
	
	erb :artist
end

#should be '/artist/:name/song/:id'
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


get '/admin' do
	if (session[:id]==nil || session[:id].downcase != 'admin')
		redirect '/notadmin'
	end
	
	erb :admin
end


post '/search' do
	@options = params[:option] #artist / merch / song / album
	
	@searchTerm = params[:term]
	if @searchTerm.length>2
		if @options == 'artist'
			@res = $search.artist(@searchTerm)
		elsif @options == 'album'
			@res = $search.album(@searchTerm)
		elsif @options == 'song'
			@res = $search.song(@searchTerm)
		elsif @options == 'merch'
			@res = $search.merchandise(@searchTerm)
		end
		
		if @res.length == 0
			@error = 'Your search wielded no results'
		end
	else
		@error = 'Please narrow your search'
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


get '/removeorder' do
  session[:total]-=session[:orders][params[:id]][3]
  session[:orders].delete(params[:id])
  redirect params[:page]
end


get '/del' do
  price = $db.select("select current_price from product where product_id = '#{params[:id]}'")
  session[:orders][params[:id]][0]-=1
  session[:orders][params[:id]][3]-=price[0]
  session[:total]-=price[0]
  
  redirect params[:page]
end


get '/checkout' do
  unless session[:id]
    redirect '/'
  end
  
  erb :checkout
end


get '/client' do
	@info = $get.client(session[:id])
	
	erb :client
end


post '/addArtistManual' do
	$manage.addArtist(params[:artistName], params[:artistImage], params[:artistBio])

	redirect '/admin'
end


post '/addArtistLastfm' do
	$lf.addArtist(params[:artistName])

	redirect '/admin'
end


post '/addAlbumManual' do
	album_id = $db.select("SELECT product_number.nextval FROM DUAL")
	
	begin
		$manage.addProduct(album_id[0], params[:albumArtist], params[:albumDescription], params[:albumImage], params[:albumDate], params[:albumPrice], params[:albumStock])
		$manage.addAlbum(album_id[0], params[:albumName], params[:albumLength], params[:albumGenre], params[:albumLabel])
	rescue
		puts "Database exception encountered."
	end
	redirect '/admin'
end


post '/addAlbumLastfm' do
	album_id = $db.select("SELECT product_number.nextval FROM DUAL")

	redirect '/admin'
end


post '/addSong' do
	song_id = $db.select("SELECT product_number.nextval FROM DUAL")
	
	$manage.addProduct(song_id[0], params[:songArtist], params[:songDescription], params[:songImage], params[:songDate], params[:songPrice], '-1')
	if (params[:addSongAlbum] != '')
		$manage.addSong(song_id[0], params[:songAlbum], params[:songName], params[:songLength], params[:songGenre], params[:songNumber])
	else
		$manage.addSong(song_id[0], 'null', params[:songName], params[:songLength], params[:songGenre], 'null')
	end

	redirect '/admin'
end


post '/addMerch' do
	merch_id = $db.select("SELECT product_number.nextval FROM DUAL")

	$manage.addProduct(merch_id[0], params[:merchArtist], params[:merchDescription], params[:merchImage], params[:merchDate], params[:merchPrice], params[:merchStock])
	$manage.addMerch(merch_id[0], params[:merchName])

	redirect '/admin'
end


post '/editClient' do	
	################################################### VERIFY IF IT WAS SUCCESSFULLY UPDATED ##########################################
	if params[:passcode] != ''
		currentPass = Digest::SHA1.hexdigest("#{params[:currentPasscode]}")
		passcode = Digest::SHA1.hexdigest("#{params[:passcode]}")
		
		$db.execute("   UPDATE client c
						SET c.name = '#{params[:name]}',
						c.telephone = '#{params[:phone]}',
						c.address = '#{params[:address]}',
						c.email = '#{params[:email]}',
						c.password = '#{passcode}'
						WHERE upper(c.client_id) = upper('#{session[:id]}')
						AND c.password = '#{currentPass}'
					")
		$db.execute("Commit")		
	else
		currentPass = Digest::SHA1.hexdigest("#{params[:currentPasscode]}")
		$db.execute("   UPDATE client c
						SET c.name = '#{params[:name]}',
						c.telephone = '#{params[:phone]}',
						c.email = '#{params[:email]}',
						c.address = '#{params[:address]}'
						WHERE upper(c.client_id) = upper('#{session[:id]}')
						AND c.password = '#{currentPass}'
					")
		$db.execute("Commit")
	end

	
	res = $get.client(session[:id])

	
	if (res[0] == params[:name] && res[1] == params[:address] && res[2] == params[:phone] && res[3] == params[:email])
		if (params[:passcode] != '')
			info = $db.select("SELECT client_id FROM client WHERE client_id = '#{session[:id]}' AND password = '#{currentPass}'")
			if info[0]
				redirect '/client?erro=f'
			else
				redirect '/client?erro=t'
			end
		else
			redirect '/client?erro=f'
		end
	else
		redirect '/client?erro=t'
	end
	redirect '/client'
end


post '/deleteArtist' do
	$manage.deleteArtist(params[:ID])
	
	redirect '/admin'
end


post '/deleteAlbum' do
	$manage.deleteAlbum(params[:ID])
	
	redirect '/admin'
end


post '/deleteSong' do
	$manage.deleteSong(params[:ID])
	
	redirect '/admin'
end


post '/deleteMerch' do
	$manage.deleteMerch(params[:ID])
	
	redirect '/admin'
end


post '/deleteClient' do
	$manage.deleteClient(params[:ID])
	
	redirect '/admin'
end



get 'final' do #client adds an order to the database
  redirect '/'
end

get '/addvote' do
  $db.execute("begin voting(#{params[:id]},#{params[:v]}); end;")
  $db.execute("commit")
  redirect params[:page]
end

get '/notadmin' do
  "<h1>You don't have enough privileges to access this page!</h1>"
end

get '/*' do
  status 400
  "<h1>Page Not Found!</h1>"
end