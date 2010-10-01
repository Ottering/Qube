module Qube
	
	module Dispatcher
		
		@services = Array.new
		
		def self.register( service )
			@services << service
			service.id = Qube::UUID.new()
		end
		
		def self.unregister( service )
			@services.delete( service )
		end
		
		def self.start( service_id )
			s = get_service( service_id )
			return false unless s
			s.start()
		end
		
		def self.restart( service_id )
			s = get_service( service_id )
			return false unless s
			s.restart()
		end
		
		def self.stop( service_id )
			s = get_service( service_id )
			return false unless s
			s.stop()
		end
		
		def self.flush!( service_id )
			s = get_service( service_id )
			return false unless s
			s.stop()
			unregister( s )
		end
		
		def self.services()
			return @services
		end
		
		def self.get_service( service_id )
			return @services[service_id]
		end
	end
	
	module Service
	
		RUNNING		= 'running'
		SLEEPING	= 'sleeping'
		WAITING		= 'waiting'
		STOPPED		= 'stopped'
		STARTING	= 'starting'
		STOPPING	= 'stopping'
		
		def state()
			return @state
		end
		
		def id=( uuid )
			return false if defined? @uuid
			@uuid = uuid
			@uuid.freeze
		end
		
		def id()
			return @uuid
		end
		
		def name()
			return @name
		end
		
		def proc_name()
			return @pname
		end
		
		def respond_to( query )
			# "Keep Alive" for determining if a process is frozen.  Must return a value different from query.
			# If response is not changed, Dispatcher may forcibly close service.
		end
		
		def run()
			# Running process code.
		end
		
		def start()
			# Post-initialization; sets up any remaining resources.
		end
		
		def restart()
			# Kills process and restarts; should call stop->start->run.
		end
		
		def stop()
			# Kills process. 
		end
	end
end
