require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require "sinatra/reloader" if development?
require 'erb'


get '/' do
  "Hello World"
end

get '/artist/:id' do
  @artistID = params[:id]
  erb :artist
end

get '/song/:id' do
  @songID = params[:id]
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