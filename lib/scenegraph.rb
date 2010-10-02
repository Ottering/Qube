module Qube
	module Scenegraph

		@sgoid = 0

		def self.next_id()
			return @sgoid += 1
		end
	end

	# A Scene defines the current scenegraph root.  It holds all of the children stored within the the scene.
	class Scene
		include Qube::Tree::Branch

		# Creates a new Scene.
		# * center:  Center of the scene; defaults to (0,0,0)
		# * rotation:  Rotation of the scene; defaults to [0,0,0,0]
		def initialize( name, center = Qube::Point, rotation = Qube::Rotation )
			@name = name
			@center = center
			@rotation = rotation
			
			@children = Array.new
		#	@extenders = Array.new
			# TODO:  Consider using BoundingBox for region occupied by scene?
		end

		# Perform the GL operations to draw the scene.  The current view is translated and rotated as per the stored
		# center and rotation before drawing begins.  Each child is called in order, based upon its index in the
		# scenegraph.
		def draw( renderer )
			GL.LoadIdentity()
			GL.Translate( center.x, center.y, center.z ) unless center.identity?
			unless rotation.identity?
				GL.Rotate( rotation.x, 1.0, 0.0, 0.0 )
				GL.Rotate( rotation.y, 0.0, 1.0, 0.0 )
				GL.Rotate( rotation.z, 0.0, 0.0, 1.0 )
			end

			# Draw children
			children.each {|child| child.draw() unless renderer.cull? child }
		end

		# Traverses the scene, printing simple data for each child.
		def traverse()
			children.each do |child|
				disp = "#{child.name}:#{child.id} -> #{child.visible?}"
				disp << " (#{child.position},#{child.rotation})" if child.is_a? SGObject
				disp << " (#{child.enabled?})" if child.is_a? SGExtender
				puts disp
			end
		end

		# Returns the scene's name
		def name()
			return @name
		end

		# Returns the scene's center
		def center()
			return @center
		end

		# Returns the scene's rotation
		def rotation()
			return @rotation
		end
	end

	# Super class for all scenegraph objects.  Stores the bounds, visibility, name, and ID of the object.
	class SGBaseObject

		def initialize( name, bounds = nil, visible = true )
			@name = name
			@bounds = bounds
			@visible = visible
			@sgid = Scenegraph.next_id
		end

		# Returns true if this object is visible and should be rendered.
		def visible?()
			return @visible
		end

		# Sets the visibility flag.
		def visible=( flag )
			@visible = flag
		end

		# Returns this object's bounds, or nil if none were set.
		def bounds()
			return @bounds
		end

		# Sets this object's bounds.
		def bounds=( val )
			@bounds = val
		end
		
		# Returns true if this object has bounds (are not nil).
		def bounded?()
			return @bounds != nil
		end

		# Returns this object's name.
		def name()
			return @name
		end

		# Returns this object's ID in the scenegraph.
		def id()
			return @sgid
		end
	end

	# Mobile scenegraph object.  Stores position and rotation.
	class SGObject < SGBaseObject

		# Creates a new SGObject
		# * pos:  Coordiniates of this object, relative to the scene's center
		# * rot:  Rotation of this object, relative to the scene's rotation
		def initialize( name, pos = Qube::Point.new, rot = Qube::Rotation.new, instance = nil )
			super( name )
			@pos = pos
			@rot = rot
			@behaviors = Array.new
			@dlid = instance if instance
		end

		# Performs GL drawing commands on this object.  After translations, calls the object's DisplayList.  This
		# method returns false if there is no display list OR the object's visibility flag is false (off).
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

		# Returns this object's DisplayList id, an integer value, or nil if one is not present.
		def display_list
			return ( defined? @dlid ) ? @dlid : nil
		end

		# Returns the list of attached behaviors.
		def behaviors()
			return @behaviors
		end

		# Returns this object's position.
		def position()
			return @pos
		end
		alias :location :position

		# Sets this object's position.
		def position=( point )
			@pos = Qube::Point.new( point )
		end
		alias :location= :position=

		# Returns this object's rotation.
		def rotation()
			return @rot
		end

		# Sets this object's rotation.
		def rotation=( rot )
			@rot = Qube::Rotation.new( rot )
		end

		# Create a new DisplayList and begin compilation of subsequent GL commands.  By default, deletes the existing
		# display list.
		# * mode:  Denotes compile mode.  Should be GL::COMPILE.
		# * delete_old:  if false, retains the original display list and issues a new ID to populate.
		def begin( mode = GL::COMPILE, delete_old = true )
			finalize if ( display_list and delete_old )
			@dlid = GL.GenLists( 1 ) unless display_list
			GL.NewList( display_list, mode )
		end
		alias :gl_routine :begin

		# Ends the DisplayList.  MUST be called after begin()
		def end()
			GL.EndList()
		end
		alias :end_routine :end

		# Finalize this object and delete its attached DisplayList.
		# FIXME:  I should also try to garbage collect this object immediately?
		def finalize()
			GL.DeleteLists( display_list, 1 )
			@dlid = nil
		end
	end

	# Extension object.  Used for storage of enabled flag/bit.
	module SGExtender
		
		@enabled = true
		
		# Sets the extender's enabled flag
		def enabled=( flag )
			@enabled = flag
		end
		
		# Returns true if the extender is enabled
		def enabled?()
			return @enabled
		end
	end

	# Simple lighting object.  Uses GL light constants.
	class Light < SGObject
		include SGExtender

		# Creates a new Light.
		# * gl_light:  Constant for Light, ex: GL::LIGHT0
		def initialize( gl_light, name = 'light' )
			super( name )
			@light_id = gl_light
		#	@bounds = BoundingSphere.new( radius )
		end

		# Enables or disables the light (see: SGExtender#enabled=) 
		def enabled=( flag )
			super()
			GL.Enable( light_id ) if enabled?
			GL.Disable( light_id ) unless enabled?
		end

		# Sets the light's position and updates its GL property
		def position=( pos )
			super()
			set_property( GL::POSITION, pos, Qube::Point )
		end

		# Returns the light's attenuation, else nil.
		def attenuation()
			return (defined? @attenuation) ? get_property( @attenuation ) : nil
		end
		
		# Returns the light's attenuation mode, else nil.
		def attenuation_mode()
			return (defined? @attenuation) ? @attenuation : nil
		end

		# Sets the light's attentuation and updates the GL property
		def attenuation=( mode, val )
			@attenuation = mode
			set_property( mode, val )
		end

		# Returns the light's diffusion color
		def diffuse_color()
			return get_property( GL::DIFFUSE )
		end

		# Sets the light's diffusion color and updates the GL property
		def diffuse_color=( color )
			set_property( GL::DIFFUSE, color )
		end

		# Returns the light's specular color
		def specular_color()
			return get_property( GL::SPECULAR )
		end

		# Sets the light's specular color and updates the GL property
		def specular_color=( color )
			set_property( GL::SPECULAR, color )
		end

		# Returns the light's ambient color
		def ambient_color()
			return get_property( GL::AMBIENT )
		end

		# Sets the light's ambient color and updates the GL property
		def ambient_color=( color )
			set_property( GL::AMBIENT, color )
		end

		# Returns the light's GL ID.
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

	# Extension to Light; allows for the creation of spotlight objects.
	class SpotLight < Light

		def initialize( gl_light, name = 'Spotlight')
			super( gl_light, name )
		end

		# Sets the light's rotation and updates the GL property
		def rotation=( rot )
			super( rot )
			set_property( GL::SPOT_DIRECTION, rot, Qube::Rotation )
		end

		# Returns the light's exponent
		def exponent()
			return get_property( GL::SPOT_EXPONENT )
		end

		# Sets the light's exponent and updates the GL property
		def exponent=( exp )
			set_property( GL::SPOT_EXPONENT, exp )
		end

		# Returns the light's cutoff
		def cutoff()
			return get_property( GL::SPOT_CUTOFF )
		end

		# Sets the light's cutoff and updates the GL property
		def cutoff=( val )
			set_property( GL::SPOT_CUTOFF, val )
		end
	end

	# Used for defining Fog.
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

		# Enables and repopulates the fog, or disables it
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

		# Return the fog's mode
		def mode()
			return @mode
		end

		# Return the fog's density
		def density()
			return @density
		end

		# Return the range of the fog
		def range()
			return @range
		end

		# Return the near range
		def near()
			return range.begin
		end

		# Return the far range
		def far()
			return range.end
		end

		# Return the fog's color
		def color()
			return @color
		end
	end

	# Simple geometry object.  Uses VertexBuffers and binds a texture to it.
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

		# Return the  VertexBuffer ID
		def buffer()
			return @bid
		end

		# Return the type of the buffer
		def type()
			return @type
		end

		# Return the mode of the buffer
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

	# Stores an array of Geometry objects.
	class GeometryArray < SGObject

		def initialize( name, instance = nil )
			super( name )
			@geom = Array.new
		end

		# Return the list of geometries
		def meshes()
			return @geom
		end

		# Return the geometry at the given index
		def []( index )
			return @geom[index]
		end
		alias :get :[]

		# Set the geometry at the given index
		def []=( index, geometry )
			@geom[index] = geometry
		end
		alias :set :[]=

		# Append a geometry to the array
		def <<( geometry )
			@geom << geometry
		end
		alias :append :<<
		alias :add :<<

		# Deletes and returns the geometry at the given instance
		def delete( index )
			return @geom.delete( index )
		end
		alias :remove :delete
	end

	# Terrain; incomplete...
	class Terrain < StaticGeometry

		def initialize( name, vertex_array, texture, type = GL::TRIANGLES, buffer = GL::ARRAY_BUFFER, instance = nil )
			super( name, vertex_array, texture, type, buffer, instance )
			# FIXME:  Create support for multi-texturing; this might need to be done in Geometry
		end
	end

	# Generic bounding mixin
	module Bounds

		# The node intersects
		INTERSECTS		= 2
		# The node is outside of the bounds
		OUTSIDE			= -1
		# The node is inside of the bounds
		INSIDE			= 1

		# Returns if this bounds intersects the passed node
		def intersect?( node )
			# TODO:  Intersection test (Bounds)
		end

		# Returns if this bounds contains the passed node
		def contain?( node )
			# TODO:  Containment test (Bounds|Point)
		end
	end

	# Spherical bounding region.
	class BoundingSphere
		include Bounds

		def initialize( radius )
			@radius = radius
		end

		# Return the sphere's radius
		def radius()
			return @radius
		end

		# Set the sphere's radius
		def radius=( val )
			@radius = val
		end
	end

	# Cuboid bounding region.
	class BoundingBox
		include Bounds

		def initialize( width, height, depth )
			@width = width
			@height = height
			@depth = depth
		end

		# Return the box's width.
		def width()
			return @width
		end

		# Set the box's width
		def width=( val )
			@width = val
		end

		# Return the box's height
		def height()
			return @height
		end

		# Set the box's height
		def height=( val )
			@height = val
		end

		# Return the box's depth
		def depth()
			return @depth
		end

		# Set the box's depth
		def depth=( val )
			@depth = val
		end
	end

	# Generic Texture object
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

		# Return the number of color channels (up to RGBA)
		def channels()
			return @channels
		end

		# Returns true if this texture is a mipmap
		def mipmap?()
			return @mipmap
		end

		# Returns this texture's ID
		def id()
			return @texture_id
		end

		# Returns this texture's raster data
		def data()
			return @data
		end

		# Returns the width of this texture
		def width()
			return @width
		end

		# Returns the hieght of this texture
		def height()
			return @height
		end

		# Returns the size of the texture as a Qube::Size object
		def size()
			return Qube::Size( width, height )
		end

		# Returns the format of this texture
		def format()
			return @format
		end

		# Returns true if the width and height are equal
		def square?()
			return width == height
		end

		# Returns true if the texture is square and a multiple of 2
		def standard?()
			return ( square? and width % 2 == 0 )
		end

		def format_to_channels( format )
			return 3 if format.eql? GL::RGB
			return 4 if format.eql? GL::RGBA
		end

		# Finalize this texture and delete is bindings.
		# FIXME:  more garbage collection?
		def finalize()
			GL.DeleteTextures( 1, id )
		end

		private :initialize
		private :format_to_channels
	end

	# 2-Dimensional texture.
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

		# Convenience method for reading full file name
		def create( file, format = GL::RGB, mipmap = false )
			return Texture2D.new( File.read( file ), format, mipmap )
		end
	end

	# 3-Dimensional texture.
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

		# Convenience method for reading full file name
		def create( file, format = GL::RGB, mipmap = false )
			return Texture3D.new( File.read( file ), format, mipmap )
		end
	end
end
