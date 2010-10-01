module Qube
	
	# Module containing simple Tree structures
	module Tree
	
		# Leaf node.  Stores a name and reference to its parent node.
		module Leaf
	
			@parent = nil
			@name = nil
	
			# Returns this node's name
			def name()
				return @name
			end
	
			# Returns this node's parent
			def parent()
				return @parent
			end
		end
	
		# Branch node.  Stores an array of children.
		module Branch
			extend Leaf
	
			@children = Array.new
	
			# Adds the new child to the end of the list unless an index is specified.  Returns the child's index.
			def add( child, index = -0 )
				unless include? child
					@children.insert( index, child )
					return ( index == -0 ? @children.length - 1 : index )
				end
			end
			alias :add_child :add
	
			# Adds the new child to the end of the list.
			def <<( child )
				return @children << child
			end
	
			# Returns true if the given node is a child of this branch.
			def include?( child )
				return @children.include? child
			end
			alias :has :include?
	
			# Deletes and returns the given node
			def delete( child )
				return @children.delete( child )
			end
			alias :remove :delete
	
			# Returns the given node
			def []( child )
				return @children[child]
			end
			alias :get :[]
	
			# Sets the index to the given node, returning a child if one already existed there.
			def []=( index, child )
				tmp = @children[index]
				@children[index] = child
				return tmp
			end
			alias :set :[]=
	
			# Returns the number of children
			def length()
				return @children.length
			end
			alias :size :length
	
			# Returns the list of children
			def children()
				return @children
			end
	
			# Returns the index of the child
			def index( child )
				return @children.index( child )
			end
			alias :index_of :index
		end
	end
end
