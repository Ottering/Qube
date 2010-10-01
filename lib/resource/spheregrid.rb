module Resource
	module Constants
		
		# Type constants
		POWER_SPHERE	= 'PS'
		MANA_SPHERE		= 'MS'
		SPEED_SPHERE	= 'SS'
		ABILITY_SPHERE	= 'AS'
		KEY_SPHERE		= 'KS'
		
		# Value constants
		HEALTH_NODE		= 'HP'
		DEFENSE_NODE	= 'DF'
		STRENGTH_NODE	= 'ST'
		MAGIC_NODE		= 'MA'
		MAGIC_DEF_NODE	= 'MD'
		MANA_NODE		= 'MP'
		ACCURACY_NODE	= 'AC'
		EVASION_NODE	= 'EV'
		AGILITY_NODE	= 'AG'
		KEY_LV1_NODE	= 'K1'
		KEY_LV2_NODE	= 'K2'
		KEY_LV3_NODE	= 'K3'
		KEY_LV4_NODE	= 'K4'

		# Spheregrid Node ID
		SGNID_LEN		= 7
		
		# Type -> Value constants
		SPHERE_TYPE_TABLE	= {
			POWER_SPHERE 	=> [ HEALTH_NODE, DEFENSE_NODE, STRENGTH_NODE ],
			MANA_SPHERE 	=> [ MAGIC_NODE, MAGIC_DEF_NODE, MANA_NODE ],
			SPEED_SPHERE	=> [ ACCURACY_NODE, EVASION_NODE, AGILITY_NODE ],
			KEY_SPHERE		=> [ KEY_LV1_NODE, KEY_LV2_NODE, KEY_LV3_NODE, KEY_LV4_NODE ]
		}
	end

	include Constants
	
	def self.gen_spheregrid_node_id()
		id = ''
		SGNID_LEN.times {|i| id << ( rand( 27 ) + 65 ).chr }
		return id
	end
	
	def self.is_valid_node_type( sphere_type, node_type )
		return SPHERE_TYPE_TABLE[sphere_type].include? node_type
	end
	
#	def self.next_spheregrid_node_id( seed = 'AAAAAAA')
#		@spheregrid_node_id_seed = seed unless defined? @spheregrid_node_id_seed
#		tmp = @spheregrid_node_id_seed
#		@spheregrid_node_id_seed = @spheregrid_node_id_seed.next
#		return tmp
#	end
	
	class SphereGrid
		
		def initialize()
			@nodes = Hash.new
			@start = Hash.new
			@id = Resource.gen_spheregrid_node_id
		end
		
		def id()
			return @id
		end
		
		def set_start( id, node )
			@start[id] = node
		end
		
		def get_start( id )
			return @start[id]
		end
	
		def add( node )
			@nodes[node.id] = node
		end
		alias :[]= :add
		
		def get( node_id )
			return @nodes[node_id]
		end
		alias :[] :get
	end
	
	class SphereNode
		
		def initialize( grid, type, attrib, value, coords )
			@type = type
			raise ArgumentError("#{attrib} is not a valid member of #{type}!") unless 
				Resource.is_valid_node_type( type, attrib )
			@attr = attrib
			@value = value
			@id = "#{grid.id}-#{Resource.gen_spheregrid_node_id}"
			@pos = coords
		end
		
		def position()
			return @pos
		end
		
		def next()
			return (defined? @next) ? @next : nil
		end
		
		def next=( node )
			@next = node
		end
		
		def prev()
			return (defined? @prev) ? @prev : nil
		end
		
		def prev=( node )
			@prev = node
		end
		
		def type()
			return @type
		end
		
		def value()
			return @value
		end
		
		def attribute()
			return @attr
		end
		
		def id()
			return @id
		end
		
		def to_str()
			return "#{id}:#{type}-#{attribute}:#{value}"
		end
		alias :to_s :to_str
	end
end
