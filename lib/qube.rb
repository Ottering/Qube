QENV = Hash.new

# Core module of the Qube engine libraries. All components of the engine will appear within this module.  Packages and
# modules required by the engine are automagically imported based upon their specifications and order within the file
# 'includes.rbo'.  This functions as the dependency list to ensure that all components ofthe library are required in the
# proper order.
# Environment variables for the engine are stored in the globalized constant QENV, a Hash object.
# The Toolkit module is only for developmental purposes, while Resources contains 3rd-party code.
module Qube
	# Window Vars
	WV_TITLE		= 'wv_title'
	WV_ICON			= 'wv_icon'
	WV_SIZE			= 'wv_size'
	WV_POS			= 'wv_pos'
	WV_FULLSCREEN	= 'wv_fullscreen'
	WV_MAXIMIZE		= 'wv_maximize'
	WV_CENTER		= 'wv_center'
	WV_GLUT			= 'wv_glut'

	# System Vars
	SV_HOST			= 'sv_host'
	SV_LANG			= 'sv_lang'

	# Load a serialized (.rbo) object
	def self.load( file )
		return Marshal.restore( open( file, 'rb'){ |io| io.read })
	end

	# Store an object to seralized form
	def self.dump( object, file )
		return open( file, 'wb'){ |io| io.write( Marshal.dump( object ) ) }
	end

	# Set the local configuration file
	def self.import_config( file )
		cfg = load( file )
		cfg.each_pair { |key, val| QENV[key] = val }
	end
	
	def self.store_config( file )
		dump( QENV, file )
	end
end

# Begin Require Statements
Qube::load('bin/includes.rbo').each{|e| require e }
