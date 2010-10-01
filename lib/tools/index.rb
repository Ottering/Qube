require 'qube'
require 'checksum'

module Toolkit
	module Indexer
		MANIFEST_FILE = 'bin/fmf.rbo'
		NIL_FILE = ['.', '..']

		def self.load()
			@manifest = File.exist?( MANIFEST_FILE ) ? Marshal.restore( MANIFEST_FILE ) : Qube::Configuration.new()
        end

		def self.index( volume, delete_copy = true )
			return false unless volume.is_a? Dir
			volume.entries.each do |file|
				next if NIL_FILE.include? file

				name = File.expand_path( file )
				index( volume, delete_copy ) if File.directory( name )
				next if File.directory( name )
				
				hash = Checksum.hash( name, Checksum::SHA512 )
				unless @manifest.include? hash
					@manifest[ hash ] = name
				else
					File.delete( name )
				end
			end
		end

		private :NIL_FILE
	end
end