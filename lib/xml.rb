module Qube
	module Xml

		DOCTYPE				= '<?xml'
		REFERENCE_START		= '<'
		REFERENCE_END		= '>'
		ENTITY_END			= '/>'
		BLOCK_END			= '</'
		COMMENT_START		= '<!--'
		COMMENT_END			= '-->'
		ATTRIB_EQUALS		= '='
		ATTRIB_VALUE		= "\""
		SEP					= "\\s"
	end

	class XmlEntity
		include Qube::Tree::Leaf, Xml

		def initialize( parent, name )
			@parent = parent
			@name = name
			@attributes = Hash.new

			@parent.add self if parent
		end

		def []( attrib )
			return @attributes[attrib]
		end
		alias :get :[]

		def []=( attrib, value )
			@attributes[attrib] = value
		end
		alias :set :[]=

		def attributes()
			return @attributes
		end

		def to_s()
			xml = REFERENCE_START + @name + SEP
			attributes.each do |key, value|
				xml += key + ATTRIB_EQUALS + ATTRIB_VAL + value + ATTRIB_VAL + SEP
			end
			return xml + ENTITY_END
		end
		alias :xml :to_s
	end

	class XmlBlock < XmlEntity
		include Qube::Tree::Branch

		def initialize( parent, name )
			super( parent, name )
			@children = Array.new
		end

		def to_s()
			xml = super.to_s.replace( ENTITY_END, REFERENCE_END )
			children.each do |child|
				xml += "\n" + child
			end
			return xml + "\n" + BLOCK_END + @name + REFERENCE_END
		end
	end

	class XmlDocument < XmlBlock

		def initialize( source )
			raise ArgumentError("Cannot initialize from empty source!") unless( source and not source.eql? '')
			_parse( (File.exists? source) ? File.open( source ) : source  )
		end

		def self.read_file( file )
			return XmlDocument.new( file )
		end
	#	alias :create :read_file

		def write_file( file, binary = false )
			data = binary ? Marshal.dump( self ) : self.to_s
			return open( file, 'w' + ( binary ? 'b' : '') ) do |io|
				io.write( data )
			end
		end

	protected
		def _parse( code )
			comment = false
			active_lv = nil

			code.each do |line|
				# Strip out header
				if line.start_with? DOCTYPE
					@header = line.strip
					next
				end

				# Handle comments
				if line.start_with? COMMENT_START
					comment = true unless line.end_with? COMMENT_END
					next
				elsif line.include? COMMENT_START
					unless line.include? COMMENT_END
						comment = true
					else
						line = line.replace(
							line[ line.index( COMMENT_START ) .. ( line.index( COMMENT_END ) + COMMENT_END.length )],
							''
						)
					end
				elsif line.include? COMMENT_END
					line = line.replace( line[ 0 .. ( line.index( COMMENT_END ) + COMMENT_END.length )], '')
					comment = false
				end

				# Strip off whitespace
				line = line.strip

				# Move back up tree if block has ended
				if line.start_with? BLOCK_END
					active_lv = active_lv.parent

				# Create a new entity
				elsif line.end_with? ENTITY_END
					line = line.replace( REFERENCE_START, '').replace( ENTITY_END, '')
					e = XmlEntity.new( active_lv, line[ 0 .. line.index( SEP )] )
					_read_attr( e, line )

				# Create a new block
				else
					line = line.replace( REFERENCE_START, '').replace( ENTITY_END, '')
					if active_lv
						b = Block.new( active_lv, line[ 0 .. line.index( SEP )] )
					else
						@name = line[ 0 .. line.index( SEP )]
						@parent = nil
						@children = Array.new
						b = self
					end
					_read_attr( b, line )
				end
			end
		end

		def _read_attr( element, code )
			n = element.name.length
			i = n
			while n < code.length
				attrib = code[ i, code.index( ATTRIB_EQUALS )].strip
				i += attrib.length

				value = code[ i, code.index( SEP, i )].strip
				value = value.replace( ATTRIB_VALUE, '')
				n = i + value.length

				element[ attrib ] = value
			end
		end

	#	protected :new
	end
end
