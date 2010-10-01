module Toolkit
	def self.os()
		return ENV['OS'] + ' ' + RUBY_PLATFORM
	end

	def self.os?( *os_str )
		os_id = os
		os_str.each { |sub| return true if os_id.include? sub }
		return false
	end

	def self.load( file )
		return Marshal.restore( open( file, 'r'){ |io|
			io.read
		})
	end

	def self.dump( object, file )
		open( file, 'w') do |io|
			io.write( Marshal.dump( object ) )
		end
	end
end
