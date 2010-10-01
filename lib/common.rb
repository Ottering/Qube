module Qube

	# Universal Unique IDentifier.  Uses a specified number of mixed-case alphanumeric characters (ASCII) to generate
	# a cryptographic key.  Due to the high range of variance (default:  2.27 x 10 ^ 57) in generated keys, these
	# values may be used for object identification as well.
	class UUID

		MINI 	= 16	# 4.76 x 10 ^ 27
		SHORT 	= 32	# 2.27 x 10 ^ 57
		LONG 	= 64	# 5.16 x 10 ^ 114
		SUPER 	= 128	# 2.67 x 10 ^ 229

		# Initializes the UUID.  Length refers to the number of characters to generate, while seed permits using a
		# starting token or string (such as namespace keys).
		def initialize( length = SHORT, seed = '')
			raise ArgumentError('Cannot use seed value with zero-length UUID!') if seed.length > 0 and length == 0
			
			@uuid = seed
			( length - seed.length ).times do |i|
				@uuid << case rand( 3 )
					when 0 then ( 48 + rand(  9 )).chr
					when 1 then ( 65 + rand( 26 )).chr
					when 2 then ( 97 + rand( 26 )).chr
				end
			end
			@uuid.freeze
		end

		# Returns the length of the key
		def length()
			return code.length
		end

		# Returns a copy of the key's literal value
		def code()
			return @uuid
		end
		alias :to_s :code
		alias :to_str :code
	end

	### Coordinates ####################################################################################################

	# N-Dimensional Coordinate.  Supports 1, 2, or 3 axis.
	class Point

		# Initializes a new Point.  Arguments may be ignored, a list of values, or another Point.
		def initialize( *args )
			@x, @y, @z = fetch( args.length > 0 ? args : [0.0, 0.0, 0.0] )
		end

		# Returns a new Point specifying the results of coordinate addition
		def +( other )
			x2, y2, z2 = fetch( other )
			return Point.new( x + x2, y + y2, z + z2 )
		end

		# Returns a new Point specifying the results of coordinate subtraction
		def -( other )
			x2, y2, z2 = fetch( other )
			return Point.new( x - x2, y - y2, z - z2 )
		end

		# Returns a new Point with the negated coordinate values of this Point
		def -@()
			return Point.new( -x, -y, -z )
		end

		# Returns the distance between this and another Point
		def distance( other )
			x2, y2, z2 = fetch( other )
			return Math.sqrt( ( x - x2 ) ** 2 + ( y - y2 ) ** 2 + ( z - z2 ) ** 2 )
		end

		# Returns the X (first) axis value
		def x()
			return @x
		end

		# Sets the X (first) axis value
		def x=( val )
			@x = val
		end

		# Returns the Y (second) axis value
		def y()
			return @y
		end

		# Sets the Y (second) axis value
		def y=( val )
			@y = val
		end

		# Returns the Z (third) axis value
		def z()
			return @z
		end

		# Sets the Z (third) axis value
		def z=( val )
			@z = val
		end

		# Returns true if this Point evaluates to Zero
		def identity?()
			return ( x == 0.0 and y == 0.0 and z == 0.0 )
		end
		alias :zero? :identity?

		# Returns true if this Point and the passed argument (Array or Point) are equal on a per-axis basis
		def eql?( other )
			x2, y2, z2 = fetch( other )
			return ( x == x2 and y == y2 and z == z2 )
		end
		alias :== :eql?

		# Returns the axis values as a 3-element Array
		def to_a()
			return [@x, @y, @z]
		end
		alias :array :to_a
		alias :to_ary :to_a

	private
		def fetch( other )
			other = other[0] if ( other.is_a? Array and other.length == 1 )
			return (other.is_a? Point) ? [ other.x, other.y, other.z ] : other
		end
	end

	### Element Bounding ###############################################################################################

	# Simple rectangular bounding region in the X and Y axis (2D).
	class Size

		# Initializes a new Size.  Arguments may be ignored, a list of values, or another Size
		def initialize( *args )
			@width, @height = fetch( args.length > 0 ? args : [0.0, 0.0] )	
		end
		
		# Returns the sum of this Size and the passed object
		def +( other )
			w2, h2 = fetch( other )
			return Size.new( width + w2, height + h2 )
		end
		
		# Returns the difference of this Size and the passed object
		def -( other )
			w2, h2 = fetch( other )
			return Size.new( width - w2, height - h2 )
		end
		
		# Returns the negation of this Size
		def -@()
			return Size.new( -width, -height )
		end

		# Returns the width of this Size
		def width()
			return @width
		end

		# Sets the width of this Size
		def width=( val )
			@width = val
		end

		# Returns the height of this Size
		def height()
			return @height
		end

		# Sets the height of this Size
		def height=( val )
			@height = val
		end

		# Returns the area of this size (W x H)
		def area()
			return width * height
		end

		# Returns true if this Size is a square
		def is_square?()
			return width == height
		end

	private
		def fetch( other )
			other = other[0] if other.is_a? Array and other.length == 1
			return (other.is_a? Size) ? [ other.width, other.height ] : other
		end
	end

	# Rectangular bounding region.  Allows for setting of coordinate (2D)
	class Rectangle < Size

		# Initializes a new Rectangle.  Arugments may be ignored, a list of values, or another Rectangle.  Arguments are:
		# X coordinate, Y coordinate, Width, Height
		def initialize( *args )
			@x, @y, w, h = fetch( args.length > 0 ? args : [0.0, 0.0, 0.0, 0.0] )
			super( w, h )
		end
		
		# Returns the sum of this Rectangle and the passed object
		def +( other )
			x2, y2, w2, h2 = fetch( other )
			return Rectangle.new( x + x2, y + y2, width + w2, height + h2 )
		end
		
		# Returns the difference of this Rectangle and the passed object
		def -( other )
			x2, y2, w2, h2 = fetch( other )
			return Rectangle.new( x - x2, y - y2, width - w2, height - h2 )
		end
		
		# Returns the negation of this Rectangle
		def -@( other )
			return Rectangle.new( -x, -y, -width, -height )
		end

		# Returns the X coordinate of this Rectangle
		def x()
			return @x
		end

		# Sets the X coordinate of this Rectangle
		def x=( val )
			@x = val
		end

		# Returns the Y coordinate of this Rectangle
		def y()
			return @y
		end

		# Sets the Y coordinate of this Rectangle
		def y=( val )
			@y = val
		end

		# Returns the Size associated with this rectangle
		def size()
			return Size.new( width, height )
		end

	private
		def fetch( other )
			other = other[0] if other.is_a? Array and other.length == 1
			return (other.is_a? Rectangle) ? [ other.x, other.y, other.width, other.height ] : other
		end
	end

	### Colors #########################################################################################################

	# Variable-channel color object.  Supports up to 4 color channels (RGBA)
	class Color

		CHANNEL_VALS = (0..1.0)

		# Initializes a new Color.  Arguments may be ignored, a list of values, or another Color
		def initialize( *args )
			@red, @green, @blue, @alpha = fetch( args.length > 0 ? args : [0.0, 0.0, 0.0, 1.0] )
		end

		# Returns a new Color with RGB channels modified by the specified percentage.  If an alpha value is supplied,
		# the resulting color will have the specified alpha channel
		def shade( percent, new_alpha = nil )
			return Color.new( red * percent, green * percent, blue * percent, ( new_alpha ? new_alpha : alpha ) )
		end
		alias :tint :shade

		# Returns the Red channel
		def red()
			return @red
		end
		alias :r :red

		# Sets the Red channel
		def red=( val )
			@red = val
		end
		alias :r= :red=

		# Returns the Green channel
		def green()
			return @green
		end
		alias :g :green

		# Sets the Green channel
		def green=( val )
			@green = val
		end
		alias :g= :green=

		# Returns the Blue channel
		def blue()
			return @blue
		end
		alias :b :blue

		# Sets the Blue channel
		def blue=( val )
			@blue = val
		end
		alias :b= :blue=

		# Returns the Alpha channel
		def alpha()
			return @alpha
		end
		alias :a :alpha

		# Sets the Alpha channel
		def alpha=( val )
			@alpha = val
		end
		alias :a= :alpha=

	private
		def fetch( other )
			other = other[0] if other.is_a? Array and other.length == 1
			return (other.is_a? Color) ? [other.r, other.g, other.b, other.a] : other
		end
	
		def clamp( val )
			return val if CHANNEL_VALS.include? val
			return ( val < CHANNEL_VALS.first ? CHANNEL_VALS.first : CHANNEL_VALS.last )
		end
	end
end
