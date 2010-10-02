require 'json'
require 'cairo'

module Qube

	# Stores the currently loaded style information, active style, and various environment properties.
	module VirtualUI
		
		@styles = Hash.new
		@current = ''
		@env = Hash.new
		
		# Returns the value of the passed environment variable
		def self.[]( var )
			return @env[var]
		end
		
		# Sets the environment variable
		def self.[]=( var, val )
			@env[var] = val
		end
		
		# Load and attach a new style
		def self.load( style )
		#	return false if include? style
			# TODO:  create a new style and attach it
		end
		
		# Return the current table of loaded styles
		def self.styles()
			return @styles
		end
		
		# Returns true if the style has been loaded
		def self.include?( style )
			return @styles.include? style
		end
		
		# Deletes and returns the style
		def self.delete( style )
			return @styles.delete( style )
		end
		
		# Returns the currently active style
		def self.style()
			return (@current.is_a? String) ? @style[@current] : @current
		end
		
		# Sets the current style
		def self.style=( style )
			@current = style
		end
	end
	
	# Defines a style used by the Virtual UI for drawing components.  Each element has a Property (Style::Property)
	# associated with it, which is a Hash of key->value pairs.
	class Style
	
		# Property class for holding element data
		class Property < Hash
			#
		end
		
		def initialize( name )
			@name = name
			@elements = Hash.new
		end
		
		def name()
			return @name
		end
		
		def []( element )
			return @elements[element]
		end
		alias :get :[]
		
		def []=( element, properties )
			@elements[element] = properties
		end
		alias :set :[]=
		
		def load( file )
			# TODO:  Interpret metacity-like file
		end
	end

	# Basic event object; used for reporting events
	class Event

		def initialize( source, message = nil, description = '')
			@source = source
			@message = message
			@description = description
		end

		# Returns the source of this event
		def source()
			return @source
		end
		alias :get_source :source

		# Return this event's payload or message data
		def message()
			return @message
		end
		alias :get_message :message

		# Returns this event's description
		def description()
			return @description
		end
		alias :get_description :description
	end

	# An event that is raised when a component or Frame gains focus.
	class FocusEvent < Event

		def initialize( source, has_focus )
			super( source, has_focus )
		end
		
		alias :has_focus? :message
	end

	# An event that is raised when a component is attached to, or detached from, a container.
	class AttachEvent < Event

		# Component was attached
		ATTACHED = true
		# Component was removed
		REMOVED = false

		def initialize( source, state )
			super( source, state )
		end
		
		alias :attached? :message
	end

	# An event that is raised when a component is resized.
	class ResizeEvent < Event

		def initialize( source, size )
			super( source, size )
		end
		
		alias :size :message

		# Returns the new width of this component
		def width()
			return size.width
		end

		# Returns the new height of this component
		def height()
			return size.height
		end
	end

	# An event that is raised when the layout or placement of a component chances.
	class LayoutEvent < ResizeEvent

		def initialize( source, bounds )
			super( source, bounds )
		end
		
		alias :bounds :message

		# Return the new X position
		def x()
			return bounds.x
		end

		# Return the new Y position
		def y()
			return bounds.y
		end
	end

	# State mixin that denotes a component can be pressed.
	module Pressable

		# Passes the event to the "press" function
		def on_press( evt )
			@press_func.call( evt )
		end

		# Registers the function for the "press" event
		def register_press_event( func )
			@press_func = func
		end
	end

	# State mixin that denotes a component can be selected or deselected.
	module Selectable

		@state = false

		# Passes the event to the "select" function
		def on_selection( evt )
			@select_func.call( evt )
		end
		
		# Registers the function for the "select" event
		def register_select_event( func )
			@select_func = func
		end

		# Returns true if this component has been selected
		def selected?()
			return @state
		end
		alias :get_selected :selected?

		# Sets the selection state of this component
		def selected=( flag )
			@state = flag
		end
		alias :set_selected :selected=
	end

	# State mixin that denotes a component's state changes when hovered over.
	module Hover

		# Passes the event to the "hover" function
		def on_hover( evt )
			@hover_func.call( evt )
		end
		
		# Registers the function for the "hover" event
		def register_hover_event( func )
			@hover_func = func
		end

		# Passes the event to the "exit" function
		def on_exit( evt )
			@uhover_func.call( evt )
		end
		
		# Registers the function for the "exit" event
		def register_exit_event( func )
			@uhover_func = func
		end
	end

	# State mixin that denotes a component can be enabled or disabled.
	module Toggle
		
		# Sets the enabled flag for this component
		def enable( flag )
			@enabled = flag
		end

		# Returns true if this component is enabled
		def enabled?()
			return @enabled
		end
		alias :is_enabled? :enabled?
	end

	# Allows a component to have a border.
	module Border

		# Turns off the border property if added
		NONE		= 0b00000000
		# Solid, monochrome border	
		SOLID		= 0b00000001
		# Dashed, monochrome border		
		DASHED		= 0b00000010
		# Inset beveled edge
		INSET		= 0b00000100
		# Raised beveled edge
		RAISED		= 0b00000101
		# Drop-shadow
		HOVER		= 0b00000110
		

		# Has a title
		TITLED		= 0b00010000
		# Capped (square) corners
		CAPPED		= 0b00100000
		# Angled (mitered) corners
		MITERED		= 0b01000000
		# Rounded corners
		ROUNDED		= 0b10000000

		@border_style = ROUNDED | SOLID
		@thickness = 1.0
		@title = ''

		# Returns the style bits for this component
		def style()
			return @border_style
		end

		# Sets the style bits for this component
		def style=( s )
			@border_style = s
		end

		# Returns the thickness of the border, in pixels
		def thickness()
			return @thickness
		end

		# Sets the thickness of the border, in pixels
		def thickness=( pix )
			@thickness = pix
		end

		# Returns the title of the border, or an empty string if one is not present
		def title()
			return (defined? @title) ? @title : ''
		end

		# Sets the title of the border
		def title=( txt )
			@title = txt
		end
	end

	# Allows a component to have an icon, which can be aligned.
	module IconComponent
	
		# Left aligned
		LEFT	= 'left'
		# Right aligned
		RIGHT	= 'right'
		# Top (center) aligned
		TOP		= 'top'

		@icon = nil
		@icon_align = LEFT

		# Returns the component's icon
		def icon()
			return @icon
		end
		alias :get_icon :icon

		# Sets the component's icon
		def icon=( val )
			@icon = val		# TODO:  Setup icon via Textures
		end
		alias :set_icon :icon=

		# Return the icon's alignent
		def icon_alignment()
			return @icon_align
		end

		# Set the icon's alignment
		def icon_alignment=( val )
			@icon_align = val
		end
	end

	# Allows a component to contain text or display text.  Editing and display options are provided.
	module TextComponent
		
		# Wrap text by word (uses spaces or hyphens)
		WRAP_BY_WORD	=  1
		# Wrap text by characters
		WRAP_BY_CHAR	= -1
		# Do not wrap lines
		NO_LINE_WRAP	=  0

		@text = ''
		@font = nil
		@edit = false
		@wrapping = WRAP_BY_WORD
		@multiline = false
		@selection = (0..0)
		@caret = 0

		# Return the component's text
		def text()
			return @text
		end
		alias :get_text :text

		# Set the component's text
		def text=( str )
			@text = str
		end
		alias :set_text :text=

		# Append text to this component
		def append( str )
			@text << str
		end
		alias :append_text :append

		# Insert text at the specified index; by default this method is the same as append()
		def insert( str, index = -0 )
			self.text = text.insert( index, str )
		end
		alias :insert_text :insert

		# Returns this component's font
		def font()
			return @font
		end
		alias :get_font :font

		# Sets this component's font
		def font=( f )
			@font = f
		end
		alias :set_font :font=

		# Returns the selected text
		def selected()
			return @text[ @selection ]
		end
		alias :get_selected_text :selected

		# Returns the range of selected characters
		def selection()
			return @selection
		end
		alias :get_selection :selection

		# Sets the selection range
		def selection=( *args )
			args = (0..0) unless args[0]
			@selection = (args.is_a? Range) ? args : (args[0] .. args[1])
		end
		alias :set_selection :selection=
		
		# Returns true if the indicated range is within the selected range
		def selected?( range )
			return selection.include? range
		end
		alias :is_selected? :selected?

		# Returns true if this component is editable
		def editable?()
			return @edit
		end
		alias :can_edit? :editable?

		# Sets the editable flag of this component
		def editable=( flag )
			@edit = flag
		end
		alias :enable_editing :editable=

		# Returns true if this component supports multi-line display
		def multiline?()
			return @multiline
		end
		alias :is_multiline? :multiline?

		# Sets the multi-line flag
		def multiline=( flag )
			@multiline = flag
		end
		alias :enable_multiline :multiline=

		# Returns the text wrapping method
		def wrapping()
			return @wrapping
		end
		alias :get_text_wrapping :wrapping

		# Sets the text wrapping method
		def wrapping=( mode )
			@wrapping = mode
		end
		alias :set_text_wrapping :wrapping=
		
		# Returns the caret position
		def caret()
			return @caret
		end
		
		# Sets the caret position
		def caret=( pos )
			@caret = pos
		end

		def rows()
			# TODO:  Return total rows of text
		end

		def cols()
			# TODO:  Return total cols of text
		end

		def fit()
			# TODO:  Recalculate text rows/cols and fit.
		end
	end

	# Low-level component.  Stores information necessary for layout, sizing, and placement.
	class UIComponent
		include Qube::Tree::Leaf
		
		# Anchor is top
		TOP				= 1
		# Anchor is left
		LEFT			= 2
		# Anchor is bottom
		BOTTOM			= 4
		# Anchor is right
		RIGHT			= 8
		# Anchor is center
		CENTER			= 16
		# Anchor is all sides
		FILL			= TOP | LEFT | BOTTOM | RIGHT

		def initialize( parent, name = 'component')
			@parent = parent
			@name = name
			parent.add( self ) if parent
		end

		# Returns the size of this component
		def size()
			return @size
		end
		alias :get_size :size

		# Sets the size of this component
		def size=( args )
			@size = Size.new( args )
		end
		alias :set_size :size=

		# Returns the location of this component
		def location()
			return @location
		end
		alias :position :location

		# Sets the location of this component
		def location=( args )
			@location = Location.new( args )
		end
		alias :position= :location=

		# Returns the anchoring bits of this component
		def anchor()
			return @anchor
		end
		alias :get_anchoring :anchor

		# Sets the anchoring bits
		def anchor=( val )
			@anchor = val
		end
		alias :set_anchoring :anchor=

		# Returns true if this component is enabled
		def enabled?()
			return @enabled
		end

		# Sets the enabled flag
		def enabled=( flag )
			@enabled = flag
		end
	end

	# Low-level container.  Holds child components within its bounds.
	class Container < UIComponent
		include Qube::Tree::Branch

		def initialize( parent, name = 'container')
			super( parent, name )
			@children = Array.new
		end
	end

	# Expandable separator.  Orientations may be OR'd together (Ex:  HORIZONTAL | SPAN).  Span-types will fill the area
	# around them within the layout, dependent upon their main orientaton (HORIZONTAL or VERTICAL).
	class Separator < UIComponent
		
		# Span is horizontal
		HORIZONTAL 		= 0b00
		# Span is vertical
		VERTICAL 		= 0b01
		# Dynamically fill
		SPAN			= 0b10

		def initialize( parent, orientation )
			super( parent, 'separator')
			@orientation = orientation
		end

		# Returns the orientation
		def orientation()
			return @orientation
		end
		alias :get_orientation :orientation
	end

	# Simple text display field.
	class Label < UIComponent
		include IconComponent, TextComponent
		
		# Left alignment
		LEFT 	= 'left'
		# Right alignment
		RIGHT 	= 'right'
		# Center alignment
		CENTER	= 'center'

		def initialize( parent, name, text, align = LEFT, icon = nil )
			super( parent, name )
			self.icon = icon
			self.text = text
		end
	end

	# Simple progress indicator bar.
	class ProgressBar < UIComponent
		include TextComponent
		
		# Horizontal bar
		HORIZONTAL		= 'h'
		# Vertical bar
		VERTICAL		= 'v'

		def initialize( parent, name, min = 0.0, max = 1.0, show_str = false, orientation = HORIZONTAL, reverse = false )
			super( parent, name )
			@min = min
			@max = max
			@progress = @min.clone
			@show = show_str
			@orientation = oientation
			@reverse = reverse
		end

		# Returns true if the progress string should be drawn
		def show_progress?()
			return @show
		end

		# Sets the progress string display flag
		def show_progress=( enabled )
			@show = enabled
		end

		# Returns the minimum value
		def min()
			return @min
		end

		# Sets the minimum value
		def min=( min )
			@min = min
		end

		# Returns the maximum value
		def max()
			return @max
		end

		# Sets the maximum value
		def max=( max )
			@max = max
		end

		# Returns the current progress
		def progress()
			return @progress
		end

		# Sets the current progress
		def progress=( current )
			@progress = current
		end
		
		# Returns the current progress percentage
		def percent()
			return @progress / @max
		end

		# Returns the current progress percentage as text
		def text()
			return "#{percent * 100.0}"
		end
	end

	# Simple button.  Can contain text and an icon.
	class Button < UIComponent
		include Pressable, TextComponent

		def initialize( parent, name, text, icon = nil )
			super( parent, name )
			self.icon = icon
			self.text = text
		end
	end

	# Simple checkbox.  Can contain text and an icon.
	class Checkbox < UIComponent
		include Selectable, TextComponent

		def initialize( parent, name, text, is_selected = false, icon = nil )
			super( parent, name )
			self.icon = icon
			self.text = text
			@selected = is_selected
		end
	end

	# Simple text area.  Defaults to multi-line display and editing.
	class TextArea < UIComponent
		include TextComponent

		def initialize( parent, name, text, edit = true, multiline = true )
			super( parent, name )
			self.text = text
			@edit = edit
			@multiline = multiline
		end
	end
	
	# Simple scrollable viewport.
	class ScrollPane < Container
	
		# Use horizontal scroll bar
		HORIZONTAL	= 0b01
		# Use vertical scroll bar
		VERTICAL	= 0b10
		# Use both scroll bars
		BOTH		= HORIZONTAL | VERTICAL
		
		def initialize( parent, name, bars = BOTH )
			super( parent, name )
			@bars = bars
		end
		
		# Return the bar setting
		def bars()
			return @bars
		end
		
		# Set the bar setting
		def bars=( bars )
			@bars = bars
		end
	end
	
	# Specifies a font which can be rendered by Cairo.
	class Font
		
		def initialize( name, size, source, type )
			@name = name
			@size = size
			load( type, source )
		end
		
		# Return the name of the font
		def name()
			return @name
		end
		
		# Return the size of the font
		def size()
			return @size
		end
		
		# Return the character height
		def character_height()
			#
		end
		alias :height :character_height

		# Return the character width
		def character_width()
			#
		end
		alias :width :character_width
		
		# Return a scaled instance of the font
		def scale( size )
			# TODO:  Attempt to scale font to new size; return new font instance
		end
	
	private
		def load( type, source )
			# TODO:  Load font data into vectorized array of characters for rendering
		end
	end

	# Simple menu bar.  Contains menus for interacting with the Frame.
	class MenuBar < Container

		def initialize( parent, name )
			super( parent, name )
		end
	end

	# Simple menu.  Contains selectable options.
	class Menu < Container
		include TextComponent

		def initialize( parent, name, text, alt_key = nil )
			super( parent, name )
			self.text = text
			@alt_key = alt_key
		end

		# Return the alt key for selecting this menu
		def alt_key()
			return @alt_key
		end
	end

	# Simple menu item.  Allows for text, an icon, and a mnemonic (hotkey)
	class MenuItem < UIComponent
		include Pressable, IconComponent, TextComponent

		def initialize( parent, name, text, icon = nil, shortcut = nil )
			super( parent, name )
			self.icon = icon
			self.text = text
			@shortcut = shortcut
		end
		
		# Return the hotkey (shortcut) 
		def shortcut()
			return @shortcut
		end
	end

	# Simple Frame (window).
	class Frame < Container
	
		# Close the window
		CLOSE			= 1
		# Roll up into "window shade"
		SHADE			= 2
		# Minimize
		ICONIFY			= 4
		# Maximize
		MAXIMIZE		= 8
		# Restore
		RESTORE			= 16
		# Default configuration
		DEFAULT			= CLOSE | SHADE | ICONIFY
		# All options
		ALL				= DEFAULT | MAXIMIZE | RESTORE

		def initialize( parent, title, buttons = CLOSE, icon = nil )
			super( parent, title )
			# TODO:  Frame setup
		end
	end

	# Simple titlebar.  Displays name of the Frame, a frame icon, and the window buttons.
	class TitleBar < Container
		include IconComponent, TextComponent

		def initialize( parent, text, buttons, icon = nil )
			super( parent, parent.name + ' titlebar')
			self.icon = icon
			self.text = text
			@anchor = TOP | LEFT | RIGHT
			# TODO:  Setup buttons and events
		end
	end
end
