require 'net/http'
require 'socket'

module Qube

	class Server < Thread

		def initialize( sock )
			@socket = sock
		end

		def run()
			# Not handled
		end

		def socket()
			return @socket
		end
	end

	class Tracker < Server

		def initialize( port )
			super( TCPServer.new( port ) )
			@peers = Hash.new
		end

		def run()
			until @socket.closed?
				client = @socket.accept_nonblock
				@peers[client.addr] = client
			end
		end
		
		def get_peer( ip )
			return @peers[ip]
		end
	end

	class Client
		
		def initialize()
			@connections = Hash.new
		end
		
		def send_to( ip, data )
			conn = get_connection( ip )
			return false unless conn
			conn.write data
		end
		
		def connect_to( ip, port )
			tmp = Connection.new( ip, port )
			@connections[ip] = tmp
			return tmp 
		end
		
		def get_connection( ip )
			return @connections[ip]
		end
	end

	class Host < Client
		
		def initialize( port = nil )
			listen_on( port ) if port
		end
		
		def listen_on( port )
			@server.close if defined? @server and @server
			@server = TCPServer.new( port )
			Thread.new( @server ) do |serv_socket|
				until serv_socket.closed?
					client_conn = serv_socket.accept_nonblock
					@connections[client_conn.addr] = client_conn
				end
			end
		end
	end

	class Connection < TCPSocket

		def initialize( host, port )
			super( host, port )
		end
	end

	class Stream < UDPSocket

		def initialize( host, port )
			super()
			bind( host, port )
		end
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
			open( File.join( @output, File.basename( @url.path ) ), 'w') do |io|
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
