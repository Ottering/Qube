# Custom errors and exceptions are listed here.  They are used for referencing internal errors unique to the Qube
# system.  Third-party error and exception objects should be listed in this module.
module Error
	
	# The required file or stream was not found or initialized
	class MissingResourceException < Exception
		
		def initialize( message )
			super( message )
		end
	end
	
	# The stream or connection timed out
	class NetworkTimeoutException < Exception
		
		def initialize( message )
			super( message )
		end
	end
	
	# A referenced .rbo or .zip library object did not exist or did not have the desired resource
	class LinkedLibraryException < Exception
		
		def initialize( message )
			super( message )
		end
	end
	
	# A rendering error occurred
	class RenderError < StandardError
		
		def initialize( message )
			super( message )
		end
	end
end
