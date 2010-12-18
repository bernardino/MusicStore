require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'yaml'
require "sinatra/reloader" if development?
require 'erb'
require 'oci8'
require 'net/http'
require 'uri'
require 'rexml/document'

class pessoa

	def initialize()
		@conn = OCI8.new('bd1','bd1','ORCL')
	end
	
	def select(query)
		res = @conn.exec(query)
		arr = Array.new
		res.each do |row|
			arr << row
		end
		res.cler
		arr

	def execute(query)
		@conn.exec(query)
	end
end