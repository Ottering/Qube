require 'digest/md5'
require 'digest/sha2'

module Toolkit
	module Checksum

		MD5     = Digest::MD5.new
	#	SHA128  = Digest::SHA2.new( 128 )
		SHA256  = Digest::SHA2.new( 256 )
		SHA512  = Digest::SHA2.new( 512 )

		def self.digest( bitlen )
			return Digest::SHA2.new( bitlen )
		end

		def self.hash( file, digest = MD5 )
			open( file, 'r') do |io|
				digest.update( io.readpartial( 1024 ) ) until io.eof
			end
			return digest.digest().to_s()
		end

		def self.check( file, expected, digest = MD5 )
			return perform_hash( file, digest ).eql?( expected )
		end
	end
end