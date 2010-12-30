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

class ArtistError < StandardError
end

class AlbumError < StandardError
end

class SongError < StandardError
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
	res = $get.checkClient(params[:username])
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
	res = $get.checkClientPassword(params[:username],passcode)
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


get '/artist/:name/song/:id' do
	@res = $get.song(params[:id])
	
	erb :song
end


get '/artist/:name/album/:id' do

	@res = $get.album(params[:id])
	@songs = $db.select("	SELECT product_id, song_number, song_name, song_length
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


get '/artist/:name/merch/:id' do
	@res = $get.merchandise(params[:id])
	erb :merch
end


get '/top' do
  @albums = $get.topAlbums()
  @songs = $get.topSongs()
  @merch = $get.topMerch()
  
  erb :charts
end


get '/addorder' do
  price = $get.productPrice(params[:id])
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
      res = $db.select("select merchandise_name from merchandise where product_id = '#{params[:id]}'")
      session[:orders][params[:id]] << 1
      session[:orders][params[:id]] << res[0]
      session[:orders][params[:id]] << params[:type]
      session[:orders][params[:id]] << price[0]
    elsif params[:type]=='s' #song
      res = $db.select("select song_name from song where product_id = '#{params[:id]}'")
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
  price = $get.productPrice(params[:id])
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
	begin
		$lf.addArtist(params[:artistName])
	rescue ArtistError
		redirect '/admin?error=artistnotfound'
	end
	redirect '/admin'
end


post '/addAlbumManual' do
	album_id = $db.select("SELECT product_number.nextval FROM DUAL")
	
	begin
		$manage.addProduct(album_id[0], params[:albumArtist], params[:albumDescription], params[:albumImage], params[:albumDate], params[:albumPrice], params[:albumStock])
		$manage.addAlbum(album_id[0], params[:albumName], params[:albumLength], params[:albumGenre], params[:albumLabel])
	rescue
		redirect '/admin?error=badartistid'
	end
	redirect '/admin'
end


post '/addAlbumLastfm' do
	begin
		$lf.addAlbum(params[:albumName], params[:albumLength], params[:albumGenre], params[:albumLabel], params[:albumArtist], params[:albumPrice], params[:albumStock])
	rescue ArtistError
		redirect '/admin?error=badartistid'
	rescue AlbumError
		redirect '/admin?error=albumnotfound'
	rescue SongError
		redirect '/admin?error=badsongdata'
	end
	redirect '/admin'
end


post '/addSong' do
	song_id = $db.select("SELECT product_number.nextval FROM DUAL")
	
	begin
		$manage.addProduct(song_id[0], params[:songArtist], params[:songDescription], params[:songImage], params[:songDate], params[:songPrice], '-1')
	rescue
		redirect '/admin?error=badartistid'
	end
	
	if (params[:addSongAlbum] != '')
		begin
			$manage.addSong(song_id[0], params[:songAlbum], params[:songName], params[:songLength], params[:songGenre], params[:songNumber])
		rescue
			redirect '/admin?error=badalbumid'
		end
	else
		$manage.addSong(song_id[0], 'null', params[:songName], params[:songLength], params[:songGenre], 'null')
	end
	

	redirect '/admin'
end


post '/addMerch' do
	merch_id = $db.select("SELECT product_number.nextval FROM DUAL")
  url = "http://tinyurl.com/api-create.php?url=#{params[:merchImage]}"
  resp = Net::HTTP.get_response(URI.parse(url))
  image=resp.body
	begin
		$manage.addProduct(merch_id[0], params[:merchArtist], params[:merchDescription], image, params[:merchDate], params[:merchPrice], params[:merchStock])
		$manage.addMerch(merch_id[0], params[:merchName])
	rescue
		redirect '/admin?error=badartistid'
	end

	redirect '/admin'
end


post '/editMerch' do

end


post '/editClient' do	
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
			info = $get.checkClientPassword(session[:id],passcode)
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
end


post '/deleteArtist' do
	res = $get.checkArtist(params[:ID])
	if (res[0])
		$manage.deleteArtist(params[:ID])
		redirect '/admin'
	else
		redirect '/admin?error=badartistid'
	end
end


post '/deleteAlbum' do
	res = $get.checkAlbum(params[:ID])
	if (res[0])
		$manage.deleteAlbum(params[:ID])
		redirect '/admin'
	else
		redirect '/admin?error=badalbumid'
	end
end


post '/deleteSong' do
	res = $get.checkSong(params[:ID])
	if (res[0])
		$manage.deleteSong(params[:ID])
		redirect '/admin'
	else
		redirect '/admin?error=badsongid'
	end
end


post '/deleteMerch' do
	res = $get.checkMerch(params[:ID])
	if (res[0])
		$manage.deleteMerch(params[:ID])
		redirect '/admin'
	else
		redirect '/admin?error=badmerchid'
	end
end


post '/deleteClient' do
	res = $get.checkClient(params[:ID])
	if (res[0])
		$manage.deleteClient(params[:ID])
		redirect '/admin'
	else
		redirect '/admin?error=badclientid'
	end
end



get '/final' do #client adds an order to the database
		
	res = $get.cartStock(session[:orders])
	if res.length == 0
		$manage.addOrder(session[:id],session[:orders],session[:total])
		session[:orders] = {}
		session[:total] = 0
	
		redirect '/?erro=f'
	else
		i=0
		erro=''
		while i < res.length
			erro.concat(res[i])
			erro.concat(':')
			i=i+1
		end
		redirect "/checkout?erro=#{erro}"
	end
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