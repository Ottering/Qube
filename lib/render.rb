module Qube

	# Stores the methods to be performed by the culling routines.
	class CullRoutine
		
		def initialize( script )
			@script = (script.is_a? String) ? script : open( script, 'r'){|io| io.read }
		end
		
		# Runs the routine.  Bindings must be supplied for renderer.
		def run( bindings )
			return eval( script, bindings )
		end
	end

	# The rendering context.  This class stores an instance of the current camera, as well as a list of all attached
	# cameras.  Views may be canged by specifying the currently active camera.
	class Renderer

		def initialize( window, camera = nil )
			@window = window
			@cameras = Array.new
			@scene = nil

			camera = Camera.new('Default Camera', Frustum.new() ) unless camera
			attach_camera camera
		end

		# Performs GL operations to draw the scene from the current camera's view.  Returns false if the current view
		# has no scene.
		def draw()
			return false unless scene
			rot = camera.rotation
			pos = camera.position

			GL.PushMatrix()
			GL.Translate( pos.x, pos.y, pos.z )
			GL.Rotate( rot.x, 1.0, 0.0, 0.0 )
			GL.Rotate( rot.y, 0.0, 1.0, 0.0 )
			GL.Rotate( rot.z, 0.0, 0.0, 1.0 )
			@scene.draw( self ) if @scene
			GL.PopMatrix()
		end

		# Returns the scene associated with the current view.
		def scene()
			return camera.scene
		end

		# Returns the currently active camera, or whichever camera is specified in the passed argument.
		def camera( cam = nil )
			return cam ? @cameras[cam] : @ccam
		end
		alias :current_camera :camera

		# Sets the currently active camera
		def set_current( cam )
			@ccam = camera( cam )
		end

		# Attaches the new specified camera and returns its index.
		# * make_active:  if true, this camera is now the active view
		def attach_camera( cam, make_active = true )
			@cameras << cam
			set_current @cameras.index( cam ) if make_active
			return @cameras.length - 1
		end

		# Deletes and returns the specified camera
		def detach_camera( cam )
			return @cameras.delete( cam )
		end
		
		# Performs the culling pass on the passed node.  Returns whether or not the node is to be culled.  In future
		# versions, this will be handled by each of the CullRoutine objects (Qube::CullRoutine).
		def cull?( node )
			# Depth Test with bounding (sphere) handling
			dist = node.position - camera.position
			frustum = camera.frustum
			return true unless(
					(node.bounded?) ? 
					(frustum.near + bounds.radius .. frustum.far - bounds.radius) : 
					frustum.depth 
				).include? dist
			
			# Perform vertical volume test
			node_h = node.position.y - camera.position.y
			frustum_h = dist * 2 * Math.tan( frustum.angle / 2 )
			return true unless(
					(node.bounded?) ? 
					(-frustum_h - bounds.raidus .. frustum_h + bounds.raidus) : 
					(-frustum_h .. frustum_h) 
				).include? node_h
			
			# Perform horizontal volume test
			node_x = node.position.x - camera.position.x
			frustum_w = window.aspect * frustum_h
			return true unless(
					(node.bounded?) ?
					(-frustum_w - bounds.radius .. frustum_w + bounds.radius ) :
					(-frustum_w .. frustum_w )
				).include? node_x
			
			# Node is OK
			return false
		end
	end

	# A viewport with coordinates and rotation specified by the global coordinate system.  Stores the frustum data
	# associated with its view.
	class Camera

		def initialize( name, frustum, pos = Point.new, rot = Rotation.new )
			@name = name
			@frustum = frustum
			@position = pos
			@rotation = rot
		end

		# Returns the name of this camera.
		def name()
			return @name
		end

		# Returns the position of this camera.
		def position()
			return @position
		end
		alias :location :position
		
		# Sets the position of this camera.
		def position=( pos )
			@position = pos
		end
		alias :location= :position=

		# Returns the rotation of this camera.
		def rotation()
			return @rotation
		end
		
		# Sets the rotation of this camera.
		def rotation=( rot )
			@rotation = rot
		end

		# Returns the Frustum of this camera.
		def frustum()
			return @frustum
		end
	end

	# A Frustum, or the visual field of view associated with a Camera instance.  Viewable regions are defined by their
	# horizontal viewing angle, the distance to the near image plate, and the distance to the far image plate.
	class Frustum

		def initialize( view_angle = 90.0, near = 5.0, far = 60.0 )
			@view_angle = view_angle
			@near = near
			@far = far
		end
		
		# Returns the view angle
		def angle()
			return @view_angle
		end
		alias :view_angle :angle

		# Returns the distance to the near image plate
		def near()
			return @near
		end
		alias :near_imageplate :near

		# Returns the distance to the far image plate
		def far()
			return @far
		end
		alias :far_imageplate :far

		# Returns a Range object inscribed by the distance from the near to far image plates
		def depth()
			return (near..far)
		end
		alias :view_range :depth
	end

	# This class acts as a wrapper to the current GLUT context and is used for issuing and receiving input commands from
	# any devices attached to the system.
	class RenderWindow

		def initialize( title, size = Qube::Size.new(300, 300), pos = Qube::Point.new, mode = GLUT::RGBA|GLUT::DEPTH|GLUT::DOUBLE )
			@title = title
			@width = ( (size.is_a? Array) ? size[0] : size.width ).to_i
			@height = ( (size.is_a? Array) ? size[1] : size.height ).to_i

			# Set up GLUT data
			GLUT.Init()
			GLUT.InitDisplayMode( mode )
			GLUT.InitWindowPosition(
					( (pos.is_a? Array) ? pos[0] : pos.x ).to_i,
					( (pos.is_a? Array) ? pos[1] : pos.y ).to_i
				)
			GLUT.InitWindowSize( @width, @height )

			# Create our Renderer
			@renderer = Renderer.new( self )

			# Connect our event handlers
			GLUT.DisplayFunc(		method( :draw_scene ).to_proc )
			GLUT.ReshapeFunc(		method( :resize ).to_proc )
			GLUT.VisibilityFunc(	method( :focus_event ).to_proc )
			GLUT.KeyboardFunc(		method( :key_press_event ).to_proc )
			GLUT.KeyboardUpFunc(	method( :key_release_event ).to_proc )
			GLUT.SpecialFunc(		method( :key_press_event ).to_proc )
			GLUT.SpecialUpFunc(		method( :key_release_event ).to_proc )
			GLUT.MouseFunc(			method( :mouse_event ).to_proc )
			GLUT.MotionFunc(		method( :mouse_motion_event ).to_proc )
		end
		
		# Creates the GLUT window
		def create()
			GLUT.CreateWindow( [@title] )
		end

		# Begins the GLUT main loop
		def mainloop()
			return false unless initialized?
			GLUT.MainLoop()
		end
		alias :begin :mainloop
		alias :start :mainloop

		# Returns the width of the window in pixels
		def width()
			return @width
		end

		# Returns the height of the window in pixels
		def height()
			return @height
		end

		# Returns the aspect ratio of the window
		def aspect()
			return height.to_f / width.to_f
		end
		alias :aspect_ratio :aspect

	protected
		def draw_scene()
			
			GL.Clear( 
				GL::COLOR_BUFFER_BIT | 
				GL::DEPTH_BUFFER_BIT 
			)						# Clear the frame buffer
			@renderer.draw			# Call the renderer draw routine
			GLUT.SwapBuffers()		# Flush and post to the window
		end

		def idle()
			GL.Clear( GL::COLOR_BUFFER_BIT )
			GLUT.SwapBuffers()
		end

		def resize( w, h )
			@width = w
			@height = h
			ratio = @height.to_f / @width.to_f

			GL.Viewport( 0, 0, width, height )
			GL.MatrixMode( GL::PROJECTION )
			GL.LoadIdentity()
			GLU.Perspective( camera.frustum.angle * ( ratio ** -1 ), ratio, camera.frustum.near, camera.frustum.far )
			GL.MatrixMode( GL::MODELVIEW )
			GL.LoadIdentity()
		end

		def focus_event( visible )
			GLUT.IdleFunc( (visible == GLUT::VISIBLE) ? method( :idle ).to_proc : nil )
		end

		def key_press_event( key, mouse_x, mouse_y )
			# ex:  @keymap[key].call( mouse_x, mouse_y ) <- keymap stores KEY=>Method pair from Keyboard instance
		end

		def key_release_event( key, mouse_x, mouse_y )
			#
		end

		def mouse_event( button, state, x, y )
			#
		end

		def mouse_motion_event( x, y )
			#
		end
	end
end
