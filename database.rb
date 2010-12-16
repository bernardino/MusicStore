require 'oci8'

class Database

	def initialize(info)
		@conn = OCI8.new('bd1','bd1','orcl')
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