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

		ATTACHED = true
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

		def width()
			return size.width
		end

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

		def x()
			return bounds.x
		end

		def y()
			return bounds.y
		end
	end

	# State mixin that denotes a component can be pressed.
	module Pressable

		def on_press( evt )
			@press_func.call( evt )
		end

		def register_press_event( func )
			@press_func = func
		end
	end

	# State mixin that denotes a component can be selected or deselected.
	module Selectable

		@state = false

		def on_selection( evt )
			@select_func.call( evt )
		end
		
		def register_select_event( func )
			@select_func = func
		end

		def selected?()
			return @state
		end
		alias :get_selected :selected?

		def selected=( flag )
			@state = flag
		end
		alias :set_selected :selected=
	end

	# State mixin that denotes a component's state changes when hovered over.
	module Hover

		def on_hover( evt )
			@hover_func.call( evt )
		end
		
		def register_hover_event( func )
			@hover_func = func
		end

		def on_exit( evt )
			@uhover_func.call( evt )
		end
		
		def register_exit_event( func )
			@uhover_func = func
		end
	end

	# State mixin that denotes a component can be enabled or disabled.
	module Toggle
		
		def enable( flag )
			@enabled = flag
		end

		def enabled?()
			return @enabled
		end
		alias :is_enabled? :enabled?
	end

	# Allows a component to have a border.
	module Border

		# Border Styles
		NONE		= 0b00000000		# Turns off the border property if added
		SOLID		= 0b00000001		# Solid, monochrome border
		DASHED		= 0b00000010		# Dashed, monochrome border
		INSET		= 0b00000100		# Inset beveled edge
		RAISED		= 0b00000101		# Raised beveled edge
		HOVER		= 0b00000110		# Drop-shadow
		

		# Options (ORd)
		TITLED		= 0b00010000
		CAPPED		= 0b00100000
		MITERED		= 0b01000000
		ROUNDED		= 0b10000000

		@border_style = ROUNDED | SOLID
		@thickness = 1.0
		@title = ''

		def style()
			return @border_style
		end

		def style=( s )
			@border_style = s
		end

		def thickness()
			return @thickness
		end

		def thickness=( pix )
			@thickness = pix
		end

		def title()
			return @title
		end

		def title=( txt )
			@title = txt
		end
	end

	# Allows a component to have an icon, which can be aligned.
	module IconComponent
	
		LEFT	= 'left'
		RIGHT	= 'right'
		TOP		= 'top'

		@icon = nil
		@icon_align = LEFT

		def icon()
			return @icon
		end
		alias :get_icon :icon

		def icon=( val )
			@icon = val		# TODO:  Setup icon via Textures
		end
		alias :set_icon :icon=

		def icon_alignment()
			return @icon_align
		end

		def icon_alignment=( val )
			@icon_align = val
		end
	end

	# Allows a component to contain text or display text.  Editing and display options are provided.
	module TextComponent
		
		WRAP_BY_WORD	=  1
		WRAP_BY_CHAR	= -1
		NO_LINE_WRAP	=  0

		@text = ''
		@font = nil
		@edit = false
		@wrapping = WRAP_BY_WORD
		@multiline = false
		@selection = (0..0)
		@caret = 0

		def text()
			return @text
		end
		alias :get_text :text

		def text=( str )
			@text = str
		end
		alias :set_text :text=

		def append( str )
			self.text = text << str
		end
		alias :append_text :append

		def insert( str, index = -0 )
			self.text = text.insert( index, str )
		end
		alias :insert_text :insert

		def font()
			return @font
		end
		alias :get_font :font

		def font=( f )
			@font = f
		end
		alias :set_font :font=

		def selected()
			return @text[ @selection ]
		end
		alias :get_selected_text :selected

		def selection()
			return @selection
		end
		alias :get_selection :selection

		def selection=( *args )
			args = (0..0) unless args[0]
			@selection = (args.is_a? Range) ? args : (args[0] .. args[1])
		end
		alias :set_selection :selection=
		
		def selected?( range )
			return selection.include? range
		end
		alias :is_selected? :selected?

		def editable?()
			return @edit
		end
		alias :can_edit? :editable?

		def editable=( flag )
			@edit = flag
		end
		alias :enable_editing :editable=

		def multiline?()
			return @multiline
		end
		alias :is_multiline? :multiline?

		def multiline=( flag )
			@multiline = flag
		end
		alias :enable_multiline :multiline=

		def wrapping()
			return @wrapping
		end
		alias :get_text_wrapping :wrapping

		def wrapping=( mode )
			@wrapping = mode
		end
		alias :set_text_wrapping :wrapping=
		
		def caret()
			return @caret
		end
		
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
		
		# Anchor constants
		TOP				= 1
		LEFT			= 2
		BOTTOM			= 4
		RIGHT			= 8
		CENTER			= 16
		FILL			= TOP | LEFT | BOTTOM | RIGHT

		def initialize( parent, name = 'component')
			@parent = parent
			@name = name
			parent.add( self ) if parent
		end

		def size()
			return @size
		end
		alias :get_size :size

		def size=( args )
			@size = Size.new( args )
		end
		alias :set_size :size=

		def location()
			return @location
		end
		alias :get_location :location

		def location=( args )
			@location = Location.new( args )
		end
		alias :set_location :location=

		def anchor()
			return @anchor
		end
		alias :get_anchoring :anchor

		def anchor=( val )
			@anchor = val
		end
		alias :set_anchoring :anchor=

		def enabled?()
			return @enabled
		end
		alias :get_enabled :enabled?

		def enabled=( flag )
			@enabled = flag
		end
		alias :set_enabled :enabled=
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
		
		HORIZONTAL 		= 0b00
		VERTICAL 		= 0b01
		SPAN 			= 0b10

		def initialize( parent, orientation )
			super( parent, 'separator')
			@orientation = orientation
		end

		def orientation()
			return @orientation
		end
		alias :get_orientation :orientation
	end

	# Simple text display field.
	class Label < UIComponent
		include IconComponent, TextComponent
		
		LEFT 	= 'left'
		RIGHT 	= 'right'
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
		
		HORIZONTAL		= 'h'
		VERTICAL		= 'v'

		def initialize( parent, name, min = 0.0, max = 1.0, show_progress = false, orientation = HORIZONTAL )
			super( parent, name )
			@min = min
			@max = max
			@progress = @min
			@show = show_progress
		end

		def show_progress?()
			return @show
		end

		def show_progress=( enabled )
			@show = enabled
		end

		def min()
			return @min
		end

		def min=( min )
			@min = min
		end

		def max()
			return @max
		end

		def max=( max )
			@max = max
		end

		def progress()
			return @progress
		end

		def progress=( current )
			@progress = current
		end

		def text( chop = false )
			return (progress / max) * 100.0
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
	
		HORIZONTAL	= 0b01
		VERTICAL	= 0b10
		BOTH		= HORIZONTAL | VERTICAL
		
		def initialize( parent, name, bars = BOTH )
			super( parent, name )
			@bars = bars
		end
		
		def bars()
			return @bars
		end
		
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
		
		def name()
			return @name
		end
		
		def size()
			return @size
		end
		
		def character_height()
			#
		end
		alias :height :character_height

		def character_width()
			#
		end
		alias :width :character_width
		
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

		def shortcut()
			return @shortcut
		end
	end

	# Simple Frame (window).
	class Frame < Container
	
		# Window Buttons
		CLOSE			= 1
		SHADE			= 2
		ICONIFY			= 4
		RESIZE			= 8
		RESTORE			= 16
		DEFAULT			= CLOSE | SHADE | ICONIFY
		ALL				= DEFAULT | RESIZE | RESTORE

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
