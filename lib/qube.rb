require 'digest/md5'

QENV = Hash.new

# Core module of the Qube engine libraries. All components of the engine will appear within this module.  Packages and
# modules required by the engine are automagically imported based upon their specifications and order within the file
# 'includes.rbo'.  This functions as the dependency list to ensure that all components ofthe library are required in the
# proper order.
# Environment variables for the engine are stored in the globalized constant QENV, a Hash object.
# The Toolkit module is only for developmental purposes, while Resources contains 3rd-party code.
module Qube
	# Title of window
	WV_TITLE		= 'wv_title'
	# Icon of window
	WV_ICON			= 'wv_icon'
	# Size of window (pixels)
	WV_SIZE			= 'wv_size'
	# Position of window
	WV_POS			= 'wv_pos'
	# If true, make fullscreen
	WV_FULLSCREEN	= 'wv_fullscreen'
	# If true, maximize
	WV_MAXIMIZE		= 'wv_maximize'
	# If true, center on screen
	WV_CENTER		= 'wv_center'
	# Bits for GLUT options
	WV_GLUT			= 'wv_glut'

	# Network host
	SV_HOST			= 'sv_host'
	# System language (use ENV['LANG'] for local default)
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
	
	# Stores the local configuration file
	def self.store_config( file )
		dump( QENV, file )
	end
	
	# Returns the checksum of the file as a String
	# * file:  File to be read
	# * digest:  Digest to be used for calculating the checksum; default:  MD5
	def self.checksum( file, digest = Digest::MD5.new )
		open( file, 'r'){ |io| digest.update( io.readpartial( 1024 ) ) until io.eof }
		return digest.digest.to_s
	end
	
	# Returns true if the file's checksum is correct
	# * file:  File to be read
	# * expected:  Expected checksum string
	# * digest:  Digest to be used (see: Qube#checksum)
	def self.same?( file, expected, digest = Digest::MD5.new )
		return checksum( file, digest ).eql? expected
	end
end

# Begin Require Statements
Qube::load('bin/includes.rbo').each{|e| require e }
