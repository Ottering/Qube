module Qube
	module QTP
		module Constants

			# CONSTANTS - Header
			CONTENT_LENGTH			= 'Content-Length'
			CONTENT_HASH			= 'Content-Hash'
			PROTOCOL				= 'Protocol'
			VERSION					= 'Version'
			CONTENT_NAME			= 'Content-Name'
			RESOURCE_UUID			= 'UUID'
			COMMAND					= 'Command'
			TIMESTAMP				= 'Timestamp'

			# CONSTANTS - Protocol
			QTP_EMBED_PROTOCOL		= 'qtp'
			QTP_URL_PROTOCOL		= 'qtp://'
			QTP_VERSION				= '0.0'

			# COMMANDS
			REQUEST					= '@Request'	# Request a resource
			FORWARD					= '@Fwd'		# Forward a connection to another peer/host
			POST					= '@Post'		# Alert a tracker of presence data
			OPEN_PORT				= '@Open'		# Ask to open the specified port for a connection
			CLOSE_PORT				= '@Close'		# Ask to close the specified port
			END_SESSION				= '@End'		# Inform endpoint that the session is about to end
			CONFIRM					= '@Ack'		# Acknowledge something (handshake-1)
			SYNCHRONIZE				= '@Syn'		# Confirm + Acknowledge something (handshake-2)
			DENY					= '@Nack'		# Negatively acknowledge
		end

		class Message
			include Constants

			def initialize( source, header, data )
				@source = source
				@header = header
				@data = data
			end

			def source()
				return @source
			end

			def header()
				return @header
			end

			def []( header_attribute )
				return @header[ header_attribute ]
			end

			def data()
				return @data
			end

			def to_binary()
				return Marshal.dump( self )
			end
		end

		class Query < Message

			def initialize( source, resource_id )
				header = { 
					PROTOCOL		=> QTP_EMBED_PROTOCOL,
					VERSION			=> QTP_VERSION,
					TIMESTAMP		=> Time.now,
					COMMAND			=> 'QUERY',
					RESOURCE_UUID	=> resource_id
				}
				super( source, header, nil )
			end
		end

		class Response < Message
			
			def initialize( source, resource_id, has_resource )
				header = {
					PROTOCOL		=> QTP_EMBED_PROTOCOL,
					VERSION			=> QTP_VERSION,
					TIMESTAMP		=> Time.now,
					COMMAND			=> 'RESPONSE',
					RESOURCE_UUID	=> resource_id,
				}
				super( source, header, has_resource )
			end
		end

		class Resource < Message
			
			def initialize( source, resource_id, stream, hash )
				header = {
					PROTOCOL		=> QTP_EMBED_PROTOCOL,
					VERSION			=> QTP_VERSION,
					TIMESTAMP		=> Time.now,
					COMMAND			=> 'RESOURCE',
					RESOURCE_UUID	=> resource_id,
					CONTENT_LENGTH	=> stream.length,
					CONTENT_HASH	=> hash
				}
				super( source, header, stream )
			end
		end
	end
end
