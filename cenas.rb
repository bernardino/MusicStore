require 'oci8'

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
	end

	def execute(query)
		@conn.exec(query)
	end
end