module Qube

	# Generic input device mixin.  Stores a system device name, type, and region code.
	module InputDevice

		# Return the device's name (system)
		def name()
			return @name
		end

		# Returns the type of the device. Currently un-implemented.
		def type()
			return @type
		end

		# Returns the language or region code associated with this device.  Useful for keyboards.
		def region_code()
			return @region
		end
	end

	# A device which supports context mapping of buttons or other input methods.  The context is a Hash.  This may be
	# changed to Qube::DeviceContext in later versios.
	class ContextDevice
		include InputDevice

		def initialize( name, type, region )
			@name = name
			@type = type
			@region = region
			@context = Hash.new
		end

		# Returns the context map of this device.
		def context()
			return @context
		end

		# Return a context mapping.
		def get( key )
			return @context[key]
		end

		# Run the mapping with the given argument list.  If the mapping is a method (Proc), it will be called.  If the
		# mapping is a script, it will be evaluated (Kernal#eval).
		def run( key, *args )
			return false unless bound? key
			get( key ).call( args ) if method? key
			eval( get( key ) ) if script? key
		end

		# Returns true if the mapping is an instance of Proc.
		def method?( key )
			return get( key ).is_a? Proc
		end

		# Returns true if the mapping is an instance of String.
		def script?( key )
			return get( key ).is_a? String
		end

		# Set a context map to the given action (Proc or String).
		def set( key, action )
			@context[key] = action
		end
		alias :bind :set

		# Deletes and returns the mapping.
		def delete( key )
			return @context.delete( key )
		end
		alias :unbind :delete

		# Returns true if the maping exists and is not nil.
		def bound?( key )
			return (@context.include? key and @context[key] != nil)
		end
	end

	# Generic Mouse device.  Allows for binding of buttons to specified actions.  This device only uses a single context.
	class Mouse < ContextDevice

		def initialize( name, type, region, context = nil )
			super( name, type, region )
			@context = context if context
		end
	end

	# Generic Keyboard device.  Allows for binding of keys to specified actions.  This device uses multiple contexts,
	# which can be set with Keyboard#set_context.
	class Keyboard < ContextDevice

		def initialize( name, type, region )
			@name = name
			@type = type
			@region = region
			@contexts = Hash.new
		end

		# Adds a new context.
		# * id:  the name of the context.
		# * context:  the context.
		# * make_active:  if true, sets this context to be active
		def add_context( id, context, make_active = false )
			@contexts[id] = context
			set_context( id ) if make_active
		end
		alias :add :add_context

		# Returns the named context.
		def get_context( context_id )
			return @contexts[context_id]
		end

		# Sets the active context to the named context.
		def set_context( context_id )
			@context = get_context( context_id )
		end
	end
end
