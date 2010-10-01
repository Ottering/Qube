require 'net/http'

module Toolkit
	module Constants
		KiloBytes	= 1024
		MegaBytes	= 1_048_576
		GigaBytes	= 1_099_511_627_776
	end
	
	class Download < Thread

		def initialize( url, destination )
			@url = URL.parse( url ) unless url.is_a? URL
			@stream = Net::HTTP.get_request( @url )	# URL, PATH, PORT
			@has, @total = 0, @stream['Content-Length'].to_i
			@output = destination
			@running = false
		end

		def run()
			@running = true
			open( File.join( @output, File.basename( @url.path ) ), Toolkit.os?('mswin', 'Windows') ? 'wb' : 'w') do |io|
				@stream.read_body do |seg|
					io.write( seg )
					@size += seg.size
				end
			end
		end

		def downloaded()
			return @has
		end

		def size()
			return @total
		end

		def remaining()
			return @total - @has
		end

		def running?()
			return @running
		end

		def complete?()
			return @has.eql? @total
		end

		def progress()
			return ( @has / @total ) * 100.0
		end
	end
end
