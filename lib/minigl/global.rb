require 'gosu'

# The main module of the library, used only as a namespace.
module MiniGL
  # This class represents a point or vector in a bidimensional space.
  class Vector
    # The x coordinate of the vector
    attr_accessor :x

    # The y coordinate of the vector
    attr_accessor :y

    # Creates a new bidimensional vector.
    #
    # Parameters:
    # [x] The x coordinate of the vector
    # [y] The y coordinate of the vector
    def initialize(x = 0, y = 0)
      @x = x
      @y = y
    end

    # Returns +true+ if both coordinates of this vector are equal to the
    # corresponding coordinates of +other_vector+, with +precision+ decimal
    # places of precision.
    def ==(other_vector, precision = 6)
      @x.round(precision) == other_vector.x.round(precision) and
          @y.round(precision) == other_vector.y.round(precision)
    end

    # Returns +true+ if at least one coordinate of this vector is different from
    # the corresponding coordinate of +other_vector+, with +precision+ decimal
    # places of precision.
    def !=(other_vector, precision = 6)
      @x.round(precision) != other_vector.x.round(precision) or
          @y.round(precision) != other_vector.y.round(precision)
    end

    # Sums this vector with +other_vector+, i.e., sums each coordinate of this
    # vector with the corresponding coordinate of +other_vector+.
    def +(other_vector)
      Vector.new @x + other_vector.x, @y + other_vector.y
    end

    # Subtracts +other_vector+ from this vector, i.e., subtracts from each
    # coordinate of this vector the corresponding coordinate of +other_vector+.
    def -(other_vector)
      Vector.new @x - other_vector.x, @y - other_vector.y
    end

    # Multiplies this vector by a scalar, i.e., each coordinate is multiplied by
    # the given number.
    def *(scalar)
      Vector.new @x * scalar, @y * scalar
    end

    # Divides this vector by a scalar, i.e., each coordinate is divided by the
    # given number.
    def /(scalar)
      Vector.new @x / scalar.to_f, @y / scalar.to_f
    end

    # Returns the euclidean distance between this vector and +other_vector+.
    def distance(other_vector)
      dx = @x - other_vector.x
      dy = @y - other_vector.y
      Math.sqrt(dx ** 2 + dy ** 2)
    end

    # Returns a vector corresponding to the rotation of this vector around the
    # origin (0, 0) by +radians+ radians.
    def rotate(radians)
      sin = Math.sin radians
      cos = Math.cos radians
      Vector.new cos * @x - sin * @y, sin * @x + cos * @y
    end

    # Rotates this vector by +radians+ radians around the origin (0, 0).
    def rotate!(radians)
      sin = Math.sin radians
      cos = Math.cos radians
      prev_x = @x
      @x = cos * @x - sin * @y
      @y = sin * prev_x + cos * @y
    end
  end

  # This class represents a rectangle by its x and y coordinates and width and
  # height.
  class Rectangle
    # The x-coordinate of the rectangle.
    attr_accessor :x

    # The y-coordinate of the rectangle.
    attr_accessor :y

    # The width of the rectangle.
    attr_accessor :w

    # The height of the rectangle.
    attr_accessor :h

    # Creates a new rectangle.
    #
    # Parameters:
    # [x] The x-coordinate of the rectangle.
    # [y] The y-coordinate of the rectangle.
    # [w] The width of the rectangle.
    # [h] The height of the rectangle.
    def initialize(x, y, w, h)
      @x = x; @y = y; @w = w; @h = h
    end

    # Returns whether this rectangle intersects another.
    #
    # Parameters:
    # [r] The rectangle to check intersection with.
    def intersect?(r)
      @x < r.x + r.w && @x + @w > r.x && @y < r.y + r.h && @y + @h > r.y
    end
  end

  # This module contains references to global objects/constants used by MiniGL.
  module G
    class << self
      # A reference to the game window.
      attr_accessor :window

      # Gets or sets the value of gravity. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :gravity

      # Gets or sets the value of min_speed. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :min_speed

      # Gets or sets the value of ramp_contact_threshold. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :ramp_contact_threshold

      # Gets or sets the value of ramp_slip_threshold. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :ramp_slip_threshold

      # Gets or sets the value of ramp_slip_force. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :ramp_slip_force

      # Gets or sets the value of kb_held_delay. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :kb_held_delay

      # Gets or sets the value of kb_held_interval. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :kb_held_interval

      # Gets or sets the value of double_click_delay. See
      # <code>GameWindow#initialize</code> for details.
      attr_accessor :double_click_delay
    end
  end

  # The main class for a MiniGL game, holds references to globally accessible
  # objects and constants.
  class GameWindow < Gosu::Window
    # Creates a game window (initializing a game with all MiniGL features
    # enabled).
    #
    # Parameters:
    # [scr_w] Width of the window, in pixels.
    # [scr_h] Height of the window, in pixels.
    # [fullscreen] Whether the window must be initialized in full screen mode.
    # [gravity] A Vector object representing the horizontal and vertical
    #           components of the force of gravity. Essentially, this force
    #           will be applied to every object which calls +move+, from the
    #           Movement module.
    # [min_speed] A Vector with the minimum speed for moving objects, i.e., the
    #             value below which the speed will be rounded to zero.
    # [ramp_contact_threshold] The maximum horizontal movement an object can
    #                          perform in a single frame and keep contact with a
    #                          ramp when it's above one.
    # [ramp_slip_threshold] The maximum ratio between height and width of a ramp
    #                       above which the objects will always slip down when
    #                       trying to 'climb' that ramp.
    # [ramp_slip_force] The force that will be applied in the horizontal
    #                   direction when the object is slipping from a steep ramp.
    # [kb_held_delay] The number of frames a key must be held by the user
    #                 before the "held" event (that can be checked with
    #                 <code>KB.key_held?</code>) starts to trigger.
    # [kb_held_interval] The interval, in frames, between each triggering of
    #                    the "held" event, after the key has been held for
    #                    more than +kb_held_delay+ frames.
    # [double_click_delay] The maximum interval, in frames, between two
    #                      clicks, to trigger the "double click" event
    #                      (checked with <code>Mouse.double_click?</code>).
    #
    # *Obs.:* This method accepts named parameters, but +scr_w+ and +scr_h+ are
    # mandatory.
    def initialize(scr_w, scr_h = nil, fullscreen = true,
                   gravity = Vector.new(0, 1), min_speed = Vector.new(0.01, 0.01),
                   ramp_contact_threshold = 4, ramp_slip_threshold = 1, ramp_slip_force = 1,
                   kb_held_delay = 40, kb_held_interval = 5, double_click_delay = 8)
      if scr_w.is_a? Hash
        scr_h = scr_w[:scr_h]
        fullscreen = scr_w.fetch(:fullscreen, true)
        gravity = scr_w.fetch(:gravity, Vector.new(0, 1))
        min_speed = scr_w.fetch(:min_speed, Vector.new(0.01, 0.01))
        ramp_contact_threshold = scr_w.fetch(:ramp_contact_threshold, 4)
        ramp_slip_threshold = scr_w.fetch(:ramp_slip_threshold, 1.1)
        ramp_slip_force = scr_w.fetch(:ramp_slip_force, 0.1)
        kb_held_delay = scr_w.fetch(:kb_held_delay, 40)
        kb_held_interval = scr_w.fetch(:kb_held_interval, 5)
        double_click_delay = scr_w.fetch(:double_click_delay, 8)
        scr_w = scr_w[:scr_w]
      end

      super scr_w, scr_h, fullscreen
      G.window = self
      G.gravity = gravity
      G.min_speed = min_speed
      G.ramp_contact_threshold = ramp_contact_threshold
      G.ramp_slip_threshold = ramp_slip_threshold
      G.ramp_slip_force = ramp_slip_force
      G.kb_held_delay = kb_held_delay
      G.kb_held_interval = kb_held_interval
      G.double_click_delay = double_click_delay
      KB.initialize
      Mouse.initialize
      Res.initialize
    end

    # Draws a rectangle with the size of the entire screen, in the given color.
    #
    # Parameters:
    # [color] Color of the rectangle to be drawn, in hexadecimal RRGGBB format.
    def clear(color)
      color |= 0xff000000
      draw_quad 0, 0, color,
                width, 0, color,
                width, height, color,
                0, height, color, 0
    end

    # Toggles the window between windowed and full screen mode.
    def toggle_fullscreen
      self.fullscreen = !fullscreen?
    end
  end

  #class JSHelper

  # Exposes methods for controlling keyboard events.
  module KB
    class << self
      # This is called by <code>GameWindow.initialize</code>. Don't call it
      # explicitly.
      def initialize
        @keys = [
          Gosu::KB_A, Gosu::KB_B, Gosu::KB_C, Gosu::KB_D, Gosu::KB_E, Gosu::KB_F,
          Gosu::KB_G, Gosu::KB_H, Gosu::KB_I, Gosu::KB_J, Gosu::KB_K, Gosu::KB_L,
          Gosu::KB_M, Gosu::KB_N, Gosu::KB_O, Gosu::KB_P, Gosu::KB_Q, Gosu::KB_R,
          Gosu::KB_S, Gosu::KB_T, Gosu::KB_U, Gosu::KB_V, Gosu::KB_W, Gosu::KB_X,
          Gosu::KB_Y, Gosu::KB_Z, Gosu::KB_1, Gosu::KB_2, Gosu::KB_3, Gosu::KB_4,
          Gosu::KB_5, Gosu::KB_6, Gosu::KB_7, Gosu::KB_8, Gosu::KB_9, Gosu::KB_0,
          Gosu::KB_NUMPAD_1, Gosu::KB_NUMPAD_2, Gosu::KB_NUMPAD_3, Gosu::KB_NUMPAD_4,
          Gosu::KB_NUMPAD_5, Gosu::KB_NUMPAD_6, Gosu::KB_NUMPAD_7, Gosu::KB_NUMPAD_8,
          Gosu::KB_NUMPAD_9, Gosu::KB_NUMPAD_0, Gosu::KB_F1, Gosu::KB_F2,
          Gosu::KB_F3, Gosu::KB_F4, Gosu::KB_F5, Gosu::KB_F6, Gosu::KB_F7,
          Gosu::KB_F8, Gosu::KB_F9, Gosu::KB_F10, Gosu::KB_F11, Gosu::KB_F12,
          Gosu::KB_APOSTROPHE, Gosu::KB_BACKSLASH, Gosu::KB_BACKSPACE,
          Gosu::KB_BACKTICK, Gosu::KB_COMMA, Gosu::KB_DELETE, Gosu::KB_DOWN,
          Gosu::KB_END, Gosu::KB_ENTER, Gosu::KB_EQUALS, Gosu::KB_ESCAPE,
          Gosu::KB_HOME, Gosu::KB_INSERT, Gosu::KB_ISO, Gosu::KB_LEFT,
          Gosu::KB_LEFT_ALT, Gosu::KB_LEFT_BRACKET, Gosu::KB_LEFT_CONTROL,
          Gosu::KB_LEFT_META, Gosu::KB_LEFT_SHIFT, Gosu::KB_MINUS,
          Gosu::KB_NUMPAD_DIVIDE, Gosu::KB_NUMPAD_MINUS,
          Gosu::KB_NUMPAD_MULTIPLY, Gosu::KB_NUMPAD_PLUS, Gosu::KB_PAGE_DOWN,
          Gosu::KB_PAGE_UP, Gosu::KB_PERIOD, Gosu::KB_RETURN, Gosu::KB_RIGHT,
          Gosu::KB_RIGHT_ALT, Gosu::KB_RIGHT_BRACKET, Gosu::KB_RIGHT_CONTROL,
          Gosu::KB_RIGHT_META, Gosu::KB_RIGHT_SHIFT, Gosu::KB_SEMICOLON,
          Gosu::KB_SLASH, Gosu::KB_SPACE, Gosu::KB_TAB, Gosu::KB_UP
        ]
        @down = []
        @prev_down = []
        @held_timer = {}
        @held_interval = {}
      end

      # Updates the state of all keys.
      def update
        @held_timer.each do |k, v|
          if v < G.kb_held_delay; @held_timer[k] += 1
          else
            @held_interval[k] = 0
            @held_timer.delete k
          end
        end

        @held_interval.each do |k, v|
          if v < G.kb_held_interval; @held_interval[k] += 1
          else; @held_interval[k] = 0; end
        end

        @prev_down = @down.clone
        @down.clear
        @keys.each do |k|
          if G.window.button_down? k
            @down << k
            @held_timer[k] = 0 if @prev_down.index(k).nil?
          elsif @prev_down.index(k)
            @held_timer.delete k
            @held_interval.delete k
          end
        end
      end

      # Returns whether the given key is down in the current frame and was not
      # down in the frame before.
      #
      # Parameters:
      # [key] Code of the key to be checked. The available codes are all the
      #       constants in +Gosu+ started with +KB_+.
      def key_pressed?(key)
        @prev_down.index(key).nil? and @down.index(key)
      end

      # Returns whether the given key is down in the current frame.
      #
      # Parameters:
      # [key] Code of the key to be checked. The available codes are all the
      #       constants in +Gosu+ started with +KB_+.
      def key_down?(key)
        @down.index(key)
      end

      # Returns whether the given key is not down in the current frame but was
      # down in the frame before.
      #
      # Parameters:
      # [key] Code of the key to be checked. The available codes are all the
      #       constants in +Gosu+ started with +KB_+.
      def key_released?(key)
        @prev_down.index(key) and @down.index(key).nil?
      end

      # Returns whether the given key is being held down. See
      # <code>GameWindow.initialize</code> for details.
      #
      # Parameters:
      # [key] Code of the key to be checked. The available codes are all the
      #       constants in +Gosu+ started with +KB_+.
      def key_held?(key)
        @held_interval[key] == G.kb_held_interval
      end
    end
  end

  # Exposes methods for controlling mouse events.
  module Mouse
    class << self
      # The current x-coordinate of the mouse cursor in the screen.
      attr_reader :x

      # The current y-coordinate of the mouse cursor in the screen.
      attr_reader :y

      # This is called by <code>GameWindow.initialize</code>. Don't call it
      # explicitly.
      def initialize
        @down = {}
        @prev_down = {}
        @dbl_click = {}
        @dbl_click_timer = {}
      end

      # Updates the mouse position and the state of all buttons.
      def update
        @prev_down = @down.clone
        @down.clear
        @dbl_click.clear

        @dbl_click_timer.each do |k, v|
          if v < G.double_click_delay; @dbl_click_timer[k] += 1
          else; @dbl_click_timer.delete k; end
        end

        k1 = [Gosu::MsLeft, Gosu::MsMiddle, Gosu::MsRight]
        k2 = [:left, :middle, :right]
        (0..2).each do |i|
          if G.window.button_down? k1[i]
            @down[k2[i]] = true
            @dbl_click[k2[i]] = true if @dbl_click_timer[k2[i]]
            @dbl_click_timer.delete k2[i]
          elsif @prev_down[k2[i]]
            @dbl_click_timer[k2[i]] = 0
          end
        end

        @x = G.window.mouse_x.round
        @y = G.window.mouse_y.round
      end

      # Returns whether the given button is down in the current frame and was
      # not down in the frame before.
      #
      # Parameters:
      # [btn] Button to be checked. Valid values are +:left+, +:middle+ and
      #       +:right+
      def button_pressed?(btn)
        @down[btn] and not @prev_down[btn]
      end

      # Returns whether the given button is down in the current frame.
      #
      # Parameters:
      # [btn] Button to be checked. Valid values are +:left+, +:middle+ and
      #       +:right+
      def button_down?(btn)
        @down[btn]
      end

      # Returns whether the given button is not down in the current frame, but
      # was down in the frame before.
      #
      # Parameters:
      # [btn] Button to be checked. Valid values are +:left+, +:middle+ and
      #       +:right+
      def button_released?(btn)
        @prev_down[btn] and not @down[btn]
      end

      # Returns whether the given button has just been double clicked.
      #
      # Parameters:
      # [btn] Button to be checked. Valid values are +:left+, +:middle+ and
      #       +:right+
      def double_click?(btn)
        @dbl_click[btn]
      end

      # Returns whether the mouse cursor is currently inside the given area.
      #
      # Parameters:
      # [x] The x-coordinate of the top left corner of the area.
      # [y] The y-coordinate of the top left corner of the area.
      # [w] The width of the area.
      # [h] The height of the area.
      #
      # <b>Alternate syntax</b>
      #
      # <code>over?(rectangle)</code>
      #
      # Parameters:
      # [rectangle] A rectangle representing the area to be checked.
      def over?(x, y = nil, w = nil, h = nil)
        return @x >= x.x && @x < x.x + x.w && @y >= x.y && @y < x.y + x.h if x.is_a? Rectangle
        @x >= x && @x < x + w && @y >= y && @y < y + h
      end
    end
  end

  # This class is responsible for resource management. It keeps references to
  # all loaded resources until a call to +clear+ is made. Resources can be
  # loaded as global, so that their references won't be removed even when
  # +clear+ is called.
  #
  # It also provides an easier syntax for loading resources, assuming a
  # particular folder structure. All resources must be inside subdirectories
  # of a 'data' directory, so that you will only need to specify the type of
  # resource being loaded and the file name (either as string or as symbol).
  # There are default extensions for each type of resource, so the extension
  # must be specified only if the file is in a format other than the default.
  module Res
    class << self
      # Get the current prefix for searching data files. This is the directory
      # under which 'img', 'sound', 'song', etc. folders are located.
      attr_reader :prefix

      # Gets the current path to image files (under +prefix+). Default is 'img'.
      attr_reader :img_dir

      # Gets the current path to tileset files (under +prefix+). Default is
      # 'tileset'.
      attr_reader :tileset_dir

      # Gets the current path to sound files (under +prefix+). Default is 'sound'.
      attr_reader :sound_dir

      # Gets the current path to song files (under +prefix+). Default is 'song'.
      attr_reader :song_dir

      # Gets the current path to font files (under +prefix+). Default is 'font'.
      attr_reader :font_dir

      # Gets or sets the character that is currently being used in the +id+
      # parameter of the loading methods as a folder separator. Default is '_'.
      # Note that if you want to use symbols to specify paths, this separator
      # should be a valid character in a Ruby symbol. On the other hand, if you
      # want to use only slashes in Strings, you can specify a 'weird' character
      # that won't appear in any file name.
      attr_accessor :separator

      # Gets or sets a flag that indicates whether images will be loaded with
      # the 'retro' option set (see +Gosu::Image+ for details), when this
      # option is not specified in a 'Res.img' or 'Res.imgs' call.
      attr_accessor :retro_images

      # This is called by <code>GameWindow.initialize</code>. Don't call it
      # explicitly.
      def initialize
        @imgs = {}
        @global_imgs = {}
        @tilesets = {}
        @global_tilesets = {}
        @sounds = {}
        @global_sounds = {}
        @songs = {}
        @global_songs = {}
        @fonts = {}
        @global_fonts = {}

        @prefix = File.expand_path(File.dirname($0)) + '/data/'
        @img_dir = 'img/'
        @tileset_dir = 'tileset/'
        @sound_dir = 'sound/'
        @song_dir = 'song/'
        @font_dir = 'font/'
        @separator = '_'
        @retro_images = false
      end

      # Set a custom prefix for loading resources. By default, the prefix is the
      # directory of the game script. The prefix is the directory under which
      # 'img', 'sound', 'song', etc. folders are located.
      def prefix=(value)
        value += '/' if value != '' and value[-1] != '/'
        @prefix = value
      end

      # Sets the path to image files (under +prefix+). Default is 'img'.
      def img_dir=(value)
        value += '/' if value != '' and value[-1] != '/'
        @img_dir = value
      end

      # Sets the path to tilset files (under +prefix+). Default is 'tileset'.
      def tileset_dir=(value)
        value += '/' if value != '' and value[-1] != '/'
        @tileset_dir = value
      end

      # Sets the path to sound files (under +prefix+). Default is 'sound'.
      def sound_dir=(value)
        value += '/' if value != '' and value[-1] != '/'
        @sound_dir = value
      end

      # Sets the path to song files (under +prefix+). Default is 'song'.
      def song_dir=(value)
        value += '/' if value != '' and value[-1] != '/'
        @song_dir = value
      end

      # Sets the path to font files (under +prefix+). Default is 'font'.
      def font_dir=(value)
        value += '/' if value != '' and value[-1] != '/'
        @font_dir = value
      end

      # Returns a <code>Gosu::Image</code> object.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the image. If the file
      #      is inside +prefix+/+img_dir+, only the file name is needed. If it's
      #      inside a subdirectory of +prefix+/+img_dir+, the id must be
      #      prefixed by each subdirectory name followed by +separator+. Example:
      #      to load 'data/img/sprite/1.png', with the default values of +prefix+,
      #      +img_dir+ and +separator+, provide +:sprite_1+ or "sprite_1".
      # [global] Set to true if you want to keep the image in memory until the
      #          game execution is finished. If false, the image will be
      #          released when you call +clear+.
      # [tileable] Whether the image should be loaded in tileable mode, which is
      #            proper for images that will be used as a tile, i.e., that
      #            will be drawn repeated times, side by side, forming a
      #            continuous composition.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than '.png'.
      # [retro] Whether the image should be loaded with the 'retro' option set
      #         (see +Gosu::Image+ for details). If the value is omitted, the
      #         +Res.retro_images+ value will be used.
      def img(id, global = false, tileable = false, ext = '.png', retro = nil)
        a = global ? @global_imgs : @imgs
        return a[id] if a[id]
        s = @prefix + @img_dir + id.to_s.split(@separator).join('/') + ext
        retro = Res.retro_images if retro.nil?
        img = Gosu::Image.new s, tileable: tileable, retro: retro
        a[id] = img
      end

      # Returns an array of <code>Gosu::Image</code> objects, using the image as
      # a spritesheet. The image with index 0 will be the top left sprite, and
      # the following indices raise first from left to right and then from top
      # to bottom.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the image. See +img+
      #      for details.
      # [sprite_cols] Number of columns in the spritesheet.
      # [sprite_rows] Number of rows in the spritesheet.
      # [global] Set to true if you want to keep the image in memory until the
      #          game execution is finished. If false, the image will be
      #          released when you call +clear+.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than ".png".
      # [retro] Whether the image should be loaded with the 'retro' option set
      #         (see +Gosu::Image+ for details). If the value is omitted, the
      #         +Res.retro_images+ value will be used.
      def imgs(id, sprite_cols, sprite_rows, global = false, ext = '.png', retro = nil, tileable = false)
        a = global ? @global_imgs : @imgs
        return a[id] if a[id]
        s = @prefix + @img_dir + id.to_s.split(@separator).join('/') + ext
        retro = Res.retro_images if retro.nil?
        imgs = Gosu::Image.load_tiles s, -sprite_cols, -sprite_rows, tileable: tileable, retro: retro
        a[id] = imgs
      end

      # Returns an array of <code>Gosu::Image</code> objects, using the image as
      # a tileset. Works the same as +imgs+, except you must provide the tile
      # size instead of the number of columns and rows, and that the images will
      # be loaded as tileable.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the image. It must be
      #      specified the same way as in +img+, but the base directory is
      #      +prefix+/+tileset_dir+.
      # [tile_width] Width of each tile, in pixels.
      # [tile_height] Height of each tile, in pixels.
      # [global] Set to true if you want to keep the image in memory until the
      #          game execution is finished. If false, the image will be
      #          released when you call +clear+.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than ".png".
      # [retro] Whether the image should be loaded with the 'retro' option set
      #         (see +Gosu::Image+ for details). If the value is omitted, the
      #         +Res.retro_images+ value will be used.
      def tileset(id, tile_width = 32, tile_height = 32, global = false, ext = '.png', retro = nil)
        a = global ? @global_tilesets : @tilesets
        return a[id] if a[id]
        s = @prefix + @tileset_dir + id.to_s.split(@separator).join('/') + ext
        retro = Res.retro_images if retro.nil?
        tileset = Gosu::Image.load_tiles s, tile_width, tile_height, tileable: true, retro: retro
        a[id] = tileset
      end

      # Returns a <code>Gosu::Sample</code> object. This should be used for
      # simple and short sound effects.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the sound. It must be
      #      specified the same way as in +img+, but the base directory is
      #      +prefix+/+sound_dir+.
      # [global] Set to true if you want to keep the sound in memory until the
      #          game execution is finished. If false, the sound will be
      #          released when you call +clear+.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than ".wav".
      def sound(id, global = false, ext = '.wav')
        a = global ? @global_sounds : @sounds
        return a[id] if a[id]
        s = @prefix + @sound_dir + id.to_s.split(@separator).join('/') + ext
        sound = Gosu::Sample.new s
        a[id] = sound
      end

      # Returns a <code>Gosu::Song</code> object. This should be used for the
      # background musics of your game.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the song. It must be
      #      specified the same way as in +img+, but the base directory is
      #      +prefix+/+song_dir+.
      # [global] Set to true if you want to keep the song in memory until the
      #          game execution is finished. If false, the song will be released
      #          when you call +clear+.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than ".ogg".
      def song(id, global = false, ext = '.ogg')
        a = global ? @global_songs : @songs
        return a[id] if a[id]
        s = @prefix + @song_dir + id.to_s.split(@separator).join('/') + ext
        song = Gosu::Song.new s
        a[id] = song
      end

      # Returns a <code>Gosu::Font</code> object. Fonts are needed to draw text
      # and used by MiniGL elements like buttons, text fields and TextHelper
      # objects.
      #
      # Parameters:
      # [id] A string or symbol representing the path to the song. It must be
      #      specified the same way as in +img+, but the base directory is
      #      +prefix+/+font_dir+.
      # [size] The size of the font, in pixels. This will correspond,
      #        approximately, to the height of the tallest character when drawn.
      # [global] Set to true if you want to keep the font in memory until the
      #          game execution is finished. If false, the font will be released
      #          when you call +clear+.
      # [ext] The extension of the file being loaded. Specify only if it is
      #       other than ".ttf".
      def font(id, size, global = true, ext = '.ttf')
        a = global ? @global_fonts : @fonts
        id_size = "#{id}_#{size}"
        return a[id_size] if a[id_size]
        s = @prefix + @font_dir + id.to_s.split(@separator).join('/') + ext
        font = Gosu::Font.new size, name: s
        a[id_size] = font
      end

      # Releases the memory used by all non-global resources.
      def clear
        @imgs.clear
        @tilesets.clear
        @sounds.clear
        @songs.clear
        @fonts.clear
      end
    end
  end
end
