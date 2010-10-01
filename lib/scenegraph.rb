module Qube
	module Scenegraph

		@sgoid = 0

		def self.next_id()
			return @sgoid += 1
		end
	end

	class Scene
		include Qube::Tree::Branch

		def initialize( name, center = Qube::Point, rotation = Qube::Rotation )
			@name = name
			@center = center
			@rotation = rotation
			
			@children = Array.new
		#	@extenders = Array.new
			# TODO:  Consider using BoundingBox for region occupied by scene?
		end

		def draw()
			GL.LoadIdentity()
			GL.Translate( center.x, center.y, center.z ) unless center.identity?
			unless rotation.identity?
				GL.Rotate( rotation.x, 1.0, 0.0, 0.0 )
				GL.Rotate( rotation.y, 0.0, 1.0, 0.0 )
				GL.Rotate( rotation.z, 0.0, 0.0, 1.0 )
			end

			# Draw children
			children.each do |child|
				child.draw()
			end
		end

		def traverse()
			children.each do |child|
				disp = "#{child.name}:#{child.id} -> #{child.visible?}"
				disp << " (#{child.position},#{child.rotation})" if child.is_a? SGObject
				disp << " (#{child.enabled?})" if child.is_a? SGExtender
				puts disp
			end
		end

		def name()
			return @name
		end

		def center()
			return @center
		end

		def rotation()
			return @rotation
		end
	end

	class SGBaseObject

		def initialize( name, bounds = nil, visible = true )
			@name = name
			@bounds = bounds
			@visible = visible
			@sgid = Scenegraph.next_id
		end

		def visible?()
			return @visible
		end

		def visible=( flag )
			@visible = flag
		end

		def bounds()
			return @bounds
		end

		def bounds=( val )
			@bounds = val
		end
		
		def bounded?()
			return @bounds != nil
		end

		def name()
			return @name
		end

		def id()
			return @sgid
		end
	end

	class SGObject < SGBaseObject

		def initialize( name, pos = Qube::Point.new, rot = Qube::Rotation.new, instance = nil )
			super( name )
			@pos = pos
			@rot = rot
			@behaviors = Array.new
			@dlid = instance if instance
		end

		def draw()
			return false unless( display_list and visible? )
			GL.PushMatrix()

			# TODO:  Call behaviors tied to this node {behaviors.each->perform}

			GL.Translate( position.x, position.y, position.z ) unless position.identity?
			unless rotation.identity?
				GL.Rotate( rotation.x, 1.0, 0.0, 0.0 )
				GL.Rotate( rotation.y, 0.0, 1.0, 0.0 )
				GL.Rotate( rotation.z, 0.0, 0.0, 1.0 )
			end
			GL.CallList( display_list )
			GL.PopMatrix()
		end

		def display_list
			return ( defined? @dlid ) ? @dlid : nil
		end

		def behaviors()
			return @behaviors
		end

		def position()
			return @pos
		end
		alias :location :position

		def position=( point )
			@pos = Qube::Point.new( point )
		end
		alias :location= :position=

		def rotation()
			return @rot
		end

		def rotation=( rot )
			@rot = Qube::Rotation.new( rot )
		end

		def begin( mode = GL::COMPILE, delete_old = false )
			finalize if ( display_list and delete_old )
			@dlid = GL.GenLists( 1 ) unless display_list
			GL.NewList( display_list, mode )
		end
		alias :gl_routine :begin

		def end()
			GL.EndList()
		end
		alias :end_routine :end

		def finalize()
			GL.DeleteLists( display_list, 1 )
			@dlid = nil
		end
	end

	module SGExtender
		
		@enabled = true
		
		def enabled=( flag )
			@enabled = flag
		end
		
		def enabled?()
			return @enabled
		end
	end

	class Light < SGObject
		include SGExtender

		def initialize( gl_light, name = 'light' )
			super( name )
			@light_id = gl_light
		#	@bounds = BoundingSphere.new( radius )
		end

		def enable( flag )
			super()
			GL.Enable( light_id ) if enabled?
			GL.Disable( light_id ) unless enabled?
		end

		def position=( pos )
			super()
			set_property( GL::POSITION, pos, Qube::Point )
		end

		def attenuation()
			return (defined? @attenuation) ? get_property( @attenuation ) : nil
		end

		def attenuation=( mode, val )
			@attenuation = mode
			set_property( mode, val )
		end

		def diffuse_color()
			return get_property( GL::DIFFUSE )
		end

		def diffuse_color=( color )
			set_property( GL::DIFFUSE, color )
		end

		def specular_color()
			return get_property( GL::SPECULAR )
		end

		def specular_color=( color )
			set_property( GL::SPECULAR, color )
		end

		def ambient_color()
			return get_property( GL::AMBIENT )
		end

		def ambient_color=( color )
			set_property( GL::AMBIENT, color )
		end

		def light_id()
			return @light_id
		end
		
	protected
		def set_property( property, value, val_class = Qube::Color )
			GL.Light( light_id, property, (value.is_a? val_class ) ? value.to_a : value )
		end

		def get_property( property )
			tmp = Object.new
			GL.GetLight( light_id, property, tmp )
			return tmp
		end
	end

	class SpotLight < Light

		def initialize( gl_light, name = 'Spotlight')
			super
		end

		def rotation=( rot )
			super
			set_property( GL::SPOT_DIRECTION, rot, Qube::Rotation )
		end

		def exponent()
			return get_property( GL::SPOT_EXPONENT )
		end

		def exponent=( exp )
			set_property( GL::SPOT_EXPONENT, exp )
		end

		def cutoff()
			return get_property( GL::SPOT_CUTOFF )
		end

		def cutoff=( val )
			set_property( GL::SPOT_CUTOFF, val )
		end
	end

	class Fog
		include SGExtender

		def initialize( mode, density, range, color )	# GL::FOG_INDEX, GL::FOG_COORD_SRC
			super('fog')
			@mode = mode
			@density = density
			@range = range
			@color = color

			enable()
		end

		def enable( flag = true )
			super( flag )
			if enabled?
				GL.Enable( GL::FOG )
				GL.Fog( GL::FOG_MODE, mode )
				GL.Fog( GL::FOG_DENSITY, density )
				GL.Fog( GL::FOG_START, near )
				GL.Fog( GL::FOG_END, far )
				GL.Fog( GL::FOG_COLOR, color.to_a )
			else
				GL.Disable( GL::FOG )
			end
		end

		def mode()
			return @mode
		end

		def density()
			return @density
		end

		def range()
			return @range
		end

		def near()
			return range.begin
		end

		def far()
			return range.end
		end

		def color()
			return @color
		end
	end

	class Geometry < SGObject

		def initialize( name, vertex_array, texture, type = GL::TRIANGLES, buffer = GL::ARRAY_BUFFER, instance = nil )
			super( name )
			@type = type
			@mode = buffer
			@texture = (texture.is_a? Texture) ? texture : Texture2D.create( texture )

			# Generate Vertex Buffer
			GL.GenBuffers( 1, @bid )
			GL.BindBuffer( @mode, @bid )
			GL.BufferData( @mode, vertex_array.length, vertex_array, GL::STATIC_DRAW )

			# Assemble Display List
			self.begin()
				GL.VertexPointer(
					gl_type( type ),									# coordinates
					gl_type( vertex_array[0].class ),					# GL data-type
					0,													# stride
					nil													#-! unknown
				)
				GL.BindTexture( @texture.mode, @texture.id )
				GL.BindBuffer( @mode, @bid )
				GL.EnableClientState( GL::VERTEX_ARRAY )
				GL.DrawArrays( @type, 0, ( vertex_array.length / ( vertex_array[0].size * ( 3 ** -1 ) ) ).to_i )
			self.end()
		end

		def buffer()
			return @bid
		end

		def type()
			return @type
		end

		def mode()
			return @mode
		end

	protected
		def gl_type( obj )
			case obj
				when GL::TRIANGLES then 3
				when GL::QUADS then 4
				when Float then GL::FLOAT
				when Int then GL::INTEGER
			end
		end
	end

	class StaticGeometry < Geometry

		def initialize( name, vertex_array, texture, pos = Qube::Point.new, rot = Qube::Rotation.new, type = GL::TRIANGLES, buffer = GL::ARRAY_BUFFER, instance = nil )
			super( name, vertex_array, texture, type, buffer, instance )
			self.position = pos
			self.rotation = rot
		end
	end

	class GeometryArray < SGObject

		def initialize( name, pos = Qube::Point.new, rot = Qube::Rotation.new, instance = nil )
			super
			@geom = Array.new
		end

		def meshes()
			return @geom
		end

		def []( index )
			return @geom[index]
		end
		alias :get :[]

		def []=( index, geometry )
			@geom[index] = geometry
		end
		alias :set :[]=

		def <<( geometry )
			@geom << geometry
		end
		alias :append :<<
		alias :add :<<

		def delete( index )
			return @geom.delete( index )
		end
		alias :remove :delete
	end

	class Terrain < StaticGeometry

		def initialize( name, vertex_array, texture, pos = Qube::Point.new, rot = Qube::Rotation.new, type = GL::TRIANGLES, buffer = GL::ARRAY_BUFFER, instance = nil )
			super( name, vertex_array, texture, pos, rot, type, buffer )
			# FIXME:  Create support for multi-texturing; this might need to be done in Geometry
		end
	end

	module Bounds

		INTERSECTS		= 2
		OUTSIDE			= -1
		INSIDE			= 1

		def intersect?( other )
			# TODO:  Intersection test (Bounds)
		end

		def contain?( other )
			# TODO:  Containment test (Bounds|Point)
		end
	end

	class BoundingSphere
		include Bounds

		def initialize( radius )
			@radius = radius
		end

		def radius()
			return @radius
		end

		def radius=( val )
			@radius = val
		end
	end

	class BoundingBox
		include Bounds

		def initialize( width, height, depth )
			@width = width
			@height = height
			@depth = depth
		end

		def width()
			return @width
		end

		def width=( val )
			@width = val
		end

		def height()
			return @height
		end

		def height=( val )
			@height = val
		end

		def depth()
			return @depth
		end

		def depth=( val )
			@depth = val
		end
	end

	class Texture

		def initialize( mode, source, params, format, mipmap )
		#	GL.PixelStore( GL::UNPACK_ALIGNMENT, 1 )
			GL.GenTextures( 1, @id )
			GL.BindTexture( mode, @id )

			# Setup image data
			@data = source
			@mipmap = mipmap
			@format = format
			@channels = format_to_channels( format )
			# TODO:  Extrapolate the dimensions of the texture

			# Setup our properties
			params.each do |key, value|
				GL.TexParameter( mode, key, value )
			end if params
		end

		def channels()
			return @channels
		end

		def mipmap?()
			return @mipmap
		end

		def id()
			return @texture_id
		end

		def data()
			return @data
		end

		def width()
			return @width
		end

		def height()
			return @height
		end

		def size()
			return Qube::Size( width, height )
		end

		def format()
			return @format
		end

		def square?()
			return width == height
		end

		def standard?()
			return ( square? and width % 2 == 0 )
		end

		def format_to_channels( format )
			return 3 if format.eql? GL::RGB
			return 4 if format.eql? GL::RGBA
		end

		def finalize()
			GL.DeleteTextures( 1, id )
		end

	#	private :new
	end

	class Texture2D < Texture

		def initialize( binary, params = nil, profile = GL::RGBA, mipmap = false )
			super( GL::TEXTURE_2D, binary, params, profile, mipmap )

			# Create the image
			unless mipmap?
				GL.TexImage2D(
					GL::TEXTURE_2D,
					0,			# Level of Detail
					channels,	# Number of channels
					width,
					height,
					0,			# Border?
					format,		# Image Type
					GL::UNSIGNED_BYTE,
					data
				)
			else
				GLU.Build2DMipmaps(
					channels,	# Number of channels
					width,
					height,
					format,		# Image Type
					GL::UNSIGNED_BYTE,
					data
				)
			end
		end

		def create( file, format = GL::RGB, mipmap = false )
			return Texture2D.new( File.read( File.join( Dir.getwd, file ) ), format, mipmap )
		end
	end

	class Texture3D < Texture

		def initialize( binary, params = nil, profile = GL::RGBA, mipmap = false )
			super( GL::TEXTURE_3D, binary, params, profile, mipmap )

			# Create the image
			unless mipmap?
				GL.TexImage3D(
					GL::TEXTURE_3D,
					0,			# Level of Detail
					channels,	# Number of channels
					width,
					height,
					0,			# Border?
					format,		# Image Type
					GL::UNSIGNED_BYTE,
					data
				)
			else
				GLU.Build3DMipmaps(
					channels,	# Number of channels
					width,
					height,
					format,		# Image Type
					GL::UNSIGNED_BYTE,
					data
				)
			end
		end

		def create( file, format = GL::RGB, mipmap = false )
			return Texture3D.new( File.read( File.join( Dir.getwd, file ) ), format, mipmap )
		end
	end
end
