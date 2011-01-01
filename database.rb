require 'oci8'

class Database
  attr_reader :conn
  
	def initialize()
		@conn = OCI8.new('bd1','bd1','ORCL')
	end
	
	def select(query)
		arr = Array.new
		cursor = @conn.exec(query)
		while r = cursor.fetch()
			arr.concat(r)
		end
		cursor.close
		arr
	end
	
	def execute(query)
		@conn.exec(query)
	end
	
end