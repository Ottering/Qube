module Qube

	# Simple factory for creation and storage of OpenGL Shading Language (GLSL) scripts.
	module ShaderFactory
		
		SHADERS = Array.new

		# Creates a new script.  If the attach argument is true, it will be added to the current list of shaders.
		def self.create( file, attach = true )
			shader = Shader.new( file )
			SHADERS << shader if attach
			return shader
		end

		# Deletes and returns a shader.
		def self.destroy( shader )
			return SHADERS.delete( shader )
		end

		# Returns the shader.
		def self.[]( shader )
			return SHADERS[ shader ]
		end

		# Sets the shader.
		def self.[]=( old_shader, new_shader )
			old = SHADERS[ old_shader ]
			SHADERS[ old_shader ] = new_shader
			return old
		end
	end

	# A class which stores the instance data for loaded Shader Programs.
	class Shader
		
		def initialize( file )
			@prgm = GL.CreateProgram()
			vertex = GL.CreateShader( GL_VERTEX_SHADER )
			fragment = GL.CreateShader( GL_FRAGMENT_SHADER )

			# Read our source and load it into the shader
			GL.ShaderSource( vertex,
				File.read( File.join( Dir.getwd, file + '.vsh') ) )
			GL.ShaderSource( fragment,
				File.read( File.join( Dir.getwd, file + '.fsh') ) )

			# Compile
			GL.CompileShader( vertex )
			GL.CompileShader( fragment )

			# Attach to program
			GL.AttachShader( @prgm, vertex )
			GL.AttachShader( @prgm, fragment )

			# Link it
			GL.LinkProgram( @prgm )

			# Cleanup source
			GL.DeleteShader( vertex )
			GL.DeleteShader( fragment )
		end

		# Return the ID to the linked shader program
		def program()
			return @prgm
		end

		# Deletes the shader program
		def finalize()
			GL.DeleteProgram( program )
		end
	end
end
