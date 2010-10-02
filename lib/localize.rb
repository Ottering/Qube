module Qube

	# Module for localization of system messages and text.  Stores multiple Localization objects.
	module Localize

		# Sets the default localization.  If no current localization has been set, it will be set as well.
		def self.default=( localization )
			@default = localization
			@current = @default.clone unless defined? @current
		end

		# Returns the default localization.
		def self.default()
			return @default
		end

		# Sets the current localization.
		def self.current=( localization )
			@current = localization
		end

		# Returns the current localization.
		def self.current()
			return @current
		end
	end

	# Localization object.  Stores message ID's and localized text.
	class Localization

		def initialize( name, display_name, language_code )
			@name = name				# in-system name
			@display = display_name		# unicode display name (written in language)
			@code = language_code		# 2 or 3 letter country/language code
			@messages = Hash.new		# hash of text to display {message ID => text}
		end

		# Return the given message.
		def []( msg_id )
			return @messages[msg_id]
		end
		alias :get_message :[]

		# Set the localization text for the given message ID.
		def []=( msg_id, display_text )
			@messages[msg_id] = display_text
		end
		alias :set_message :[]=

		# Return the system name of this localization.
		def name()
			return @name
		end

		# Return the displayable name of this localization.
		def display_name()
			return @display
		end

		# Return the language code of this localizaton.
		def language_code()
			return @code
		end
		alias :code :language_code
	end
end
