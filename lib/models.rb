module Qube
	class Bone

		def initialize( id, normal_pos, normal_rot )
			@id = id
			@pos_normal = normal_pos
			@pos_current = @pos_normal.clone
			@rot_normal = normal_rot
			@rot_current = @rot_normal.clone

			# Safety measure
			@pos_normal.freeze
			@pos_current.freeze
		end

		def id()
			return @id
		end

		def position()
			return @pos_current
		end

		def position=( pos )
			@pos_current = pos
		end

		def rotation()
			return @rot_current
		end

		def rotation=( rot )
			@rot_current = rot
		end

		def norm_pos()
			return @pos_normal
		end

		def norm_rot()
			return @rot_normal
		end
	end

	class Keyframe

		def initialize( references = nil )
			@time = 0.0
			@refs = references if references
		end

		def duration()
			return @time
		end

		def duration=( time )
			@time = time
		end

		def []=( bone_id, pos, rot )
			@refs[bone_id] = [pos, rot]
		end
		alias :set :[]=

		def []( bone_id )
			return @refs[bone_id]
		end
		alias :get :[]

		def include?( bone_id )
			return @refs.include? bone_id
		end
		alias :has? :include?

		def delete( bone_id )
			return @refs.delete( bone_id )
		end
		alias :remove :delete
	end

	class Animation

		def initialize()
			@frames = Array.new
		end

		def play()
		#	@thread.kill if( defined? @thread and @thread )
			Thread.start do |thread|
				@frames.each do |frame|
					# TODO:  move model based on bone settings in keyframe
					# TODO:  sleep thread for duration of keyframe
				end
			end
		end

		def <<( frame )
			@frames << frame
		end
		alias :add :<<

		def []=( index, frame )
			@frames[index] = frame
		end
		alias :set_frame :[]=

		def []( index )
			return @frames[index]
		end
		alias :get_frame :[]

		def length()
			return @frames.size
		end
		alias :size :length
		
		def frames()
			return @frames
		end

		def delete( ref )
			return @frames.delete( ref )
		end
		alias :remove :delete

		def include?( ref )
			return @frames.include? ref
		end
		alias :has? :include?
	end

	class Vertex < Qube::Point

		def initialize( x, y, z )
			super [x, y, z]
		end

		def bone()
			return (defined? @bone) ? @bone : nil
		end

		def bone=( bid )
			@bone = bid
		end
	end

	class Model < Qube::GeometryArray
		require 'zip/zip'
		
		MF_GEOMETRY		= 'Geometry'
		MF_TEXTURE		= 'Texture'
		MF_COORD_BYTES	= 'CoordinateBytes'
		MF_GL_TYPE		= 'OpenGL-Type'
		MF_GEOM_MESH	= 'Geometry-Mesh'
		MF_GEOM_NAME	= 'Geometry-Name'
		MF_TEX_CHANNELS	= 'Texture-Channels'
		MF_TEX_MIPMAP	= 'Texture-MipMap'
		MF_TEX_ARGS		= 'Texture-Args'
		MF_TEX_MODE		= 'Texture-Mode'

		RBO_FILE = 'manifest.rbo'

		def initialize( name, pos = Qube::Point.new, rot = Qube::Rotation.new, instance = nil )
			super( name, pos, rot, instance )
		end

		def self.create( name, zip_source, instance = nil )
			return Model.new( name, instance ) if instance

			zip = Zip::ZipFile.new( zip_source )
			@manifest = Marshal.restore( zip.get_output_stream( zip.get_entry( RBO_FILE ) ) )

			# TODO: Read zip data to create geometry/normal/bone instances

			# Generate geometries
			@manifest[ MF_GEOMETRY ].each do |geo|

				# Create vertex array
				vbit = geo[ MF_COORD_BYTES ]
				vcor = geo[ MF_GL_TYPE ]
				verts = Array.new
				zip.get_output_stream( zip.get_entry( geo[ MF_GEOM_MESH ] ) ) do |io|
					verts << io.read_bytes( vbit ) until io.eof?
				end

				# Create pixel array (texture)
				txch = geo[ MF_TEX_CHANNELS ]
				txmm = geo[ MF_TEX_MIPMAPS ]
				txar = geo[ MF_TEX_ARGS ]
				texture = nil
				zip.get_output_stream( zip.get_entry( geo[ MF_TEXTURE ] ) ) do |io|
					texture = (geo[ MF_TEX_MODE ].eql? GL::TEXTURE_2D) ?
						Qube::Texture2D( io.read, txar, txch, txmm ) : Qube::Texture3D( io.read, txar, txch, txmm )
				end
				
				# Attach geometry instance
				append Qube::Geometry.new( geo[ MF_GEOM_NAME ], verts, texture, vcor )
			end

			# Initialize and generate display list
			model = Model.new( name )
			model.begin()
				meshes.each do |geometry|
					geometry.draw()
				end
			model.end()

			return model
		end
	end
end
