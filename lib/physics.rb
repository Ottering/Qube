module Qube

	# Module for storage of environment variables.
	module Physics

		@envars = Hash.new

		# Return an environment variable
		def self.[]( var )
			return @envars[var]
		end

		# Set an environment variable
		def self.[]=( var, val )
			@envars[var] = val
		end

		# Returns true if a variable is set
		def self.include?( var )
			return @envars.include? var
		end
	end

	# 4-Axis rotation.  Specifies X, Y, Z, and W elements.  The default calculation method is in degrees.  Use
	# Rotation#mode to change between degrees and radians.
	class Rotation < Qube::Point

		alias :alpha :x
		alias :alpha= :x=
		alias :beta :y
		alias :beta= :y=
		alias :gamma :z
		alias :gamma= :z=
		
		DEGREES = 'deg'
		RADIANS = 'rad'

		def initialize( *args )
			@x, @y, @z, @w = fetch( args.length > 0 ? args[0] : [0.0, 0.0, 0.0, 0.0] )
			@mode = DEGREES
		end

		# Returns a new rotation which is the summation of this and another
		def +( other )
			x2, y2, z2, w2 = fetch( other )
			return Rotation.new( x + x2, y + y2, z + z2, w + w2 )
		end

		# Returns a new rotation which is the difference of this and another
		def -( other )
			x2, y2, z2, w2 = fetch( other )
			return Rotation.new( x - x2, y - y2, z - z2, w - w2 )
		end

		# Returns the negation of this rotation.
		def -@()
			return Rotation.new( -x, -y, -z, -w )
		end

		# Returns the W element.
		def w()
			return @w
		end

		# Sets the W element.
		def w=( val )
			@w = val
		end

		# Returns true if this rotation evaluates to zero.
		def identity?()
			return ( super and w == 0.0 )
		end
		alias :zero? :identity?

		# Returns true if this rotation and another are equal.
		def eql?( other )
			x2, y2, z2, w2 = fetch( other )
			return ( x == x2 and y == y2 and z == z2 and w == w2 )
		end
		alias :== :eql?

	private
		def fetch( other )
			return (other.is_a? Rotation) ? [other.x, other.y, other.z, other.w] : other
		end
	end

	# 3-Axis vector.  Supports coordinates and magnitude, handled by axis.
	class Vector < Qube::Point

		def initialize( *args )
			@x, @y, @z, @mx, @my, @mz = fetch( args.length > 0 ? args[0] : [0.0, 0.0, 0.0, 1.0, 1.0, 1.0] )
		end

		# Returns a new vector, which is the summation of this vector and another.
		def +( other )
			x2, y2, z2, mx2, my2, mz2 = fetch( other )
			return Vector.new( x, y, z, mx + mx2, my + my2, mz + mz2 )
		end

		# Returns a new vector, which is the difference of this vector and another.
		def -( other )
			x2, y2, z2, mx2, my2, mz2 = fetch( other )
			return Vector.new( x, y, z, mx - mx2, my - my2, mz - mz2 )
		end

		# Returns the dot product of this vector and another.
		def *( other )
			x2, y2, z2, mx2, my2, mz2 = fetch( other )
			return mx * mx2 + my * my2 + mz * mz2	# alternate:  AB*cos(theta)
		end
		alias :dot :*
		alias :dot_product :*

		# Returns the negation of this vector
		def -@()
			return Vector.new( x, y, z, -mx, -my, -mz )
		end

		# Returns the X magnitude
		def magX()
			return @mx
		end
		alias :magnitude_x :magX
		alias :mx :magX

		# Sets the X magnitude
		def magX=( val )
			@mx = val
		end
		alias :magnitude_x= :magX=
		alias :mx= :magX=

		# Returns the Y magnitude
		def magY()
			return @my
		end
		alias :magnitude_y :magY
		alias :my :magY

		# Sets the Y magnitude
		def magY=( val )
			@my = val
		end
		alias :magnitude_y= :magY=
		alias :my= :magY=

		# Returns the Z magnitude
		def magZ()
			return @mz
		end
		alias :magnitude_z :magZ
		alias :mz :magZ

		# Sets the Z magnitude
		def magZ=( val )
			@mz = val
		end
		alias :magnitude_z= :magZ=
		alias :mz= :magZ=

		# Returns the magnitude of this vector
		def magnitude()
			return Math.sqrt( mx ** 2 + my ** 2 + mz ** 2 )
		end

		# Returns true if this vector and another have equal magnitudes
		def eql?( *other )
			x2, y2, z2, mx2, my2, mz2 = fetch( other )
			return ( mx == mx2 and my == my2 and mz == mz2 )
		end
		alias :== :eql?

		# Returns true if this vector and another are equivalent
		def identical?( *other )
			return ( super other and eql? other )
		end
		alias :same_as? :identical?

	private
		def fetch( other )
			return (other.is_a? Vector) ? [ other.x, other.y, other.z, other.mx, other.my, other.mz ] : other
		end
	end
end
