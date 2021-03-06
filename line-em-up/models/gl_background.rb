# Class Needs to be renamed.. 

require 'gosu'
# # # require 'opengl'
# # # require 'glu'

# # require 'opengl'
# require 'glut'

require 'opengl'
require 'glut'

# For opengl-bindings
# OpenGL.load_lib()
# GLUT.load_lib()
require_relative '../lib/global_constants.rb'

class GLBackground
  include OpenGL
  include GLUT
  include GlobalConstants
  # Height map size
  # MAP_HEIGHT_EDGE = 700
  # MAP_WIDTH_EDGE_RIGHT = 450
  # MAP_WIDTH_EDGE_LEFT  = 80
  # EXTERIOR_MAP_HEIGHT = 200
  # EXTERIOR_MAP_WIDTH  = 200
  # POINTS_X = 7
  # outside of view padding

  # HAVE TO BE EVEN NUMBERS
  # POINTS_Y = 7

  # CAN SEE EDGE OF BLACK MAP AT PLAYER Y 583
  # 15 tiles should be on screen
  # HAVE TO BE EVEN NUMBERS
  VISIBLE_MAP_TILE_WIDTH  = 6
  VISIBLE_MAP_TILE_HEIGHT = 6
  EXTRA_MAP_TILE_HEIGHT   = 4
  EXTRA_MAP_TILE_WIDTH    = 4
  # outside of view padding
  # HAVE TO BE EVEN NUMBERS
  # HAVE TO BE EVEN NUMBERS
  # Scrolling speed - higher it is, the slower the map moves
  SCROLLS_PER_STEP = 50
  # TEMP USING THIS, CANNOT FIND SCROLLING SPEED
  SCROLLING_SPEED = 4

  # attr_accessor :player_position_x, :player_position_y
  attr_reader :map_tile_width, :map_tile_height
  attr_accessor :map_pixel_width, :map_pixel_height
  attr_accessor :tile_pixel_width, :tile_pixel_height
  attr_accessor :current_map_pixel_center_x, :current_map_pixel_center_y
  attr_reader :gps_map_center_x, :gps_map_center_y
  attr_reader :map_name
  attr_reader :map_data

  # tile size is 1 GPS (location_x, location_y)
  # Screen size changes. At 900x900, it should be 900 (screen_pixel_width) / 15 (@visible_map_tile_width) = 60 pixels
  # OpenGL size (-1..1) should be (1.0 / 15.0 (@visible_map_tile_width)) - 1.0 

  # This is incorrect.. the map isn't 1..-1 in openGL.. it's more like 0.5..-0.5
  # 225.0, 675.0, 450.0 , 450.0
  # screen_to_opengl_increment: -0.0022222222222222222 - -0.0022222222222222222
  # outputs: {:o_x=>0.5, :o_y=>-0.5, :o_w=>-1.0, :o_h=>-1.0}


  # not sure if include_adjustments_for_not_exact_opengl_dimensions works yet or not
  # def convert_opengl_to_screen opengl_x, opengl_y, include_adjustments_for_not_exact_opengl_dimensions = false
  #   opengl_x = 1.2 / opengl_x if opengl_x != 0 && include_adjustments_for_not_exact_opengl_dimensions
  #   x = ((opengl_x + 1) / 2.0) * @screen_pixel_width.to_f
  #   opengl_y = 0.92 / opengl_y if opengl_y != 0 && include_adjustments_for_not_exact_opengl_dimensions
  #   y = ((opengl_y + 1) / 2.0) * @screen_pixel_height.to_f
  #   return [x, y]
  # end

  #   convert_screen_to_opengl
  # 225.0, 675.0, 450.0 , 450.0
  # RETURNING: {:o_x=>-0.5, :o_y=>0.5, :o_w=>0.0, :o_h=>0.0}
  # def convert_screen_to_opengl x, y, w = nil, h = nil, include_adjustments_for_not_exact_opengl_dimensions = false
  #   # puts "IT's SET RIUGHT HERE2!!: #{@screen_pixel_height} - #{y}"
  #   opengl_x   = ((x / (@screen_pixel_width.to_f )) * 2.0) - 1
  #   # opengl_x   = opengl_x * 1.2 if include_adjustments_for_not_exact_opengl_dimensions
  #   opengl_y   = ((y / (@screen_pixel_height.to_f)) * 2.0) - 1
  #   # opengl_y   = opengl_y * 0.92 if include_adjustments_for_not_exact_opengl_dimensions
  #   if w && h
  #     open_gl_w  = ((w / (@screen_pixel_width.to_f )) * 2.0)
  #     # open_gl_w = open_gl_w - opengl_x
  #     open_gl_h  = ((h / (@screen_pixel_height.to_f )) * 2.0)
  #     # open_gl_h = open_gl_h - opengl_y
  #     # puts "RETURNING: #{{o_x: opengl_x, o_y: opengl_y, o_w: open_gl_w, o_h: open_gl_h}}"
  #     return {o_x: opengl_x, o_y: opengl_y, o_w: open_gl_w, o_h: open_gl_h}
  #   else
  #     # puts "RETURNING: #{{o_x: opengl_x, o_y: opengl_y}}"
  #     return {o_x: opengl_x, o_y: opengl_y}
  #   end
  # end


  def initialize map_name, width_scale, height_scale, screen_pixel_width, screen_pixel_height, resolution_scale, graphics_setting
    # @debug = true
    @save_file_path = CURRENT_SAVE_FILE
    # @debug = false
    @graphics_setting = graphics_setting
    # @y_add_top_tracker = []
    # @image = Gosu::Image.new("#{MEDIA_DIRECTORY}/earth.png", :tileable => true)

    @resolution_scale = resolution_scale

    @visible_map_tile_height = VISIBLE_MAP_TILE_HEIGHT
    @visible_map_tile_width  = (VISIBLE_MAP_TILE_WIDTH * resolution_scale).ceil
    @visible_map_tile_width -= 1 if @visible_map_tile_width % 2 != 0
   # puts "NEW V WIDTH : #{@visible_map_tile_width}"
    @extra_map_tile_width    = EXTRA_MAP_TILE_WIDTH
    @extra_map_tile_height   = EXTRA_MAP_TILE_HEIGHT


    @resolution_scale = resolution_scale
    # These are the width and length of each background tile
    @opengl_increment_y = 1 / (@visible_map_tile_height.to_f / 4.0)
    @opengl_increment_x = 1 / (@visible_map_tile_width.to_f  / 4.0)

    @width_scale  = width_scale
    @height_scale = height_scale

    @map_inited = false

    # background openGLK window size is 0.5 (-.25 .. .25)
    # IN OPENGL terms
    # @open_gl_screen_movement_increment_x = 1 / ((screen_pixel_width.to_f / @visible_map_tile_width.to_f)  - (screen_pixel_width.to_f / @visible_map_tile_width.to_f) / 4.0 )#(screen_pixel_width  / @visible_map_tile_width)  / 4
    # @open_gl_screen_movement_increment_y = 1 / ((screen_pixel_height.to_f / @visible_map_tile_height.to_f)  - (screen_pixel_height.to_f / @visible_map_tile_height.to_f) / 4.0 )#(screen_pixel_height / @visible_map_tile_height) / 4

    # SCREEN COORD SYSTEM 480 x 480
    # @on_screen_movement_increment_x = ((screen_pixel_width.to_f  / @visible_map_tile_width.to_f)  / 2.0)     #(screen_pixel_width  / @visible_map_tile_width)  / 4
    # @on_screen_movement_increment_y = ((screen_pixel_height.to_f / @visible_map_tile_height.to_f) / 2.0)     #(screen_pixel_height / @visible_map_tile_height) / 4

    # OPENGL SYSTEM -1..1
    # @open_gl_screen_movement_increment_x = (1 / (@on_screen_movement_increment_x))  - (@on_screen_movement_increment_x / 2.0)
    # @open_gl_screen_movement_increment_y = (1 / (@on_screen_movement_increment_y))  - (@on_screen_movement_increment_y / 2.0)
    @open_gl_screen_movement_increment_x = (1 / (@visible_map_tile_width.to_f  )) / 2.0
    @open_gl_screen_movement_increment_y = (1 / (@visible_map_tile_height.to_f )) / 2.0
 
    # puts "MOVEMENT INCREMENTS: #{@on_screen_movement_increment_x} - #{@on_screen_movement_increment_y}"
    # raise "STOP HERE"
    # Need to convert on_screen to GPS
    # puts "INIT: @screen_movement_increment: #{@on_screen_movement_increment_x} - #{@on_screen_movement_increment_y}"


    # splits across middle 0  -7..0..7
    # new_x_index = x_index - (x_max / 2.0)
    # new_y_index = y_index - (y_max / 2.0)
    # convert to 
    # split across center index, divided by half of center abs / 2
    # (-7 / 3.5) / 2.0
    # (-1 / 3.5) / 2.0
    # -1

    # Replace scrolling meter
    @global_sized_terrain_width = (@opengl_increment_x * 2)


    @screen_pixel_width = screen_pixel_width
    # puts "IT's SET RIUGHT HERE!!: #{@screen_pixel_width}"
    @screen_pixel_height = screen_pixel_height
    @screen_pixel_height_half = @screen_pixel_height / 2
    @screen_pixel_width_half = @screen_pixel_width / 2

    @tile_pixel_width  = @screen_pixel_width  / (@visible_map_tile_width.to_f)
    @tile_pixel_height = @screen_pixel_height / (@visible_map_tile_height.to_f)

    # @ratio = @screen_pixel_width.to_f / (@screen_pixel_height.to_f)

    # increment_x = (ratio / middle_x) * 0.97
    # # The zoom issue maybe, not quite sure why we need the Y offset.
    # increment_y = (1.0 / middle_y) * 0.55

    @scrolls = 0.0
    @visible_map = Array.new(@visible_map_tile_height + @extra_map_tile_height) { Array.new(@visible_map_tile_width + @extra_map_tile_width) { nil } }
    @local_map_movement_x = 0
    @local_map_movement_y = 0

    # Keeping offsets in pos
    # @gps_tile_offset_y = (@visible_map_tile_height + @extra_map_tile_height) / 2
    # @gps_tile_offset_x = (@visible_map_tile_width  + @extra_map_tile_width ) / 2

    # PRE 
    # @gps_tile_offset_x: 9 - 4 - 0
    # @gps_tile_offset_y: 6 - 3 - 1
    # POST
    # @gps_tile_offset_x: 9
    # @gps_tile_offset_y: 7

    # puts "PRE "
    # puts "@gps_tile_offset_x: #{@gps_tile_offset_x} - #{(@gps_tile_offset_x) % 2 }"
    # puts "@gps_tile_offset_y: #{@gps_tile_offset_y} - #{(@gps_tile_offset_y) % 2 }"

    # @gps_tile_offset_y += 1 if (@gps_tile_offset_y) % 2 == 1
    # @gps_tile_offset_x += 1 if (@gps_tile_offset_x) % 2 == 1

    # puts "POST"
    # puts "@gps_tile_offset_x: #{@gps_tile_offset_x}"
    # puts "@gps_tile_offset_y: #{@gps_tile_offset_y}"

    # @map_tile_height = EXTERIOR_MAP_HEIGHT
    # @map_tile_width  = EXTERIOR_MAP_WIDTH
    # @player_position_x = EXTERIOR_MAP_HEIGHT / 2.0
    # @player_position_y = EXTERIOR_MAP_WIDTH  / 2.0
    # @current_map_pixel_center_y = EXTERIOR_MAP_HEIGHT / 2.0
    # @current_map_pixel_center_x = EXTERIOR_MAP_WIDTH  / 2.0
    # These are in screen units
    @current_map_pixel_center_x = nil# player_x || 0
    @current_map_pixel_center_y = nil#player_y || 0
    # Global units
    @gps_map_center_x = nil # player_x ? (player_x / (@tile_pixel_width)).round : 0
    @gps_map_center_y = nil # player_y ? (player_y / (@tile_pixel_height)).round : 0


    # @map_top_row    = nil
    # @map_bottom_row = nil
    # @map_left_row   = nil
    # @map_right_row  = nil

    if @graphics_setting == :basic
      @dirt_image = Gosu::Image.new(MEDIA_DIRECTORY + '/earth.png')
      @snow_image = Gosu::Image.new(MEDIA_DIRECTORY + '/snow.png')
      @water_image = Gosu::Image.new(MEDIA_DIRECTORY + '/water.png')
      @out_of_bounds_image = Gosu::Image.new(MEDIA_DIRECTORY + '/earth_3.png')
      height_scale_adjustment = (@tile_pixel_height) / (@dirt_image.height)
      @adjusted_height_scale = height_scale_adjustment + (height_scale_adjustment / 80.0)
      # 200 - 200.0 - 1.0 - 2.5
      # width and width and scale: 200 - 160.0 - 0.83125 - 2.406015037593985
      # width and width and scale: 200 - 160.0 - 0.83125 - 1.6625 - 2.0
      # width and width and scale: 133 - 160.0 - 0.83125 - 1.6625 - 2.0
      # width and width and scale:       133 -                 160.0 -               1.2030075187969924 -            2.406015037593985 -          2.0
      # puts "width and width and scale: #{@dirt_image.width} - #{@tile_pixel_width} - #{height_scale_adjustment} - #{@adjusted_height_scale} - #{@height_scale}"
      # @adjusted_height_scale = @adjusted_height_scale / 1.3
    end


    @map_name = map_name
    @map = JSON.parse(File.readlines("#{MAP_DIRECTORY}/#{@map_name}.txt").first)


    existing_map_data = ConfigSetting.get_mapped_setting(@save_file_path, [@map_name, 'map_objects'])
    if existing_map_data
      # puts "existing map data"
      @map_objects = existing_map_data
    else
      # puts "GETTING NEW MAP DATA"
      @map_objects = JSON.parse(File.readlines("#{MAP_DIRECTORY}/#{@map_name}_map_objects.txt").join('').gsub("\n", ''))
      # puts "BMAP Aobjects"
      # puts @map_objects.inspect
    end



    @active_map_objects = []


    @terrains = @map["terrains"]
    puts "TERRAINS HEREL:"
    puts @terrains.inspect
    
    
    # @image = Gosu::Image.new("/Users/bendana/projects/line-em-up/line-em-up/media/earth.png", :tileable => true)
    # @info = @image.gl_tex_info

    # image = Gosu::Image.new("/Users/bendana/projects/line-em-up/line-em-up/media/earth_0.png", :tileable => true)
    # @images << image
    # @infos << image.gl_tex_info

    first_run = true
    found_fault = false
    while first_run || found_fault
      found_fault = false
      @infos = []
      @images = []
      gl_tex_info_ids = []
      @alt_infos = {}

      @terrains.each_with_index do |terrain_path, index|
        image = Gosu::Image.new(MEDIA_DIRECTORY + '/' + terrain_path, :tileable => true)
        @images << image
        test = image.gl_tex_info
        puts "test jere infos: #{test}"
        puts "2 jere: #{test.tex_name}"
        gl_tex_info_ids << test.tex_name
        @infos  << test
        @alt_infos[index.to_s] = test
      end

      out_of_bounds_path = @map["out_of_bounds_terrain_path"]
      image = Gosu::Image.new(MEDIA_DIRECTORY + '/' + out_of_bounds_path, :tileable => true)
      @images << image
      test = image.gl_tex_info
      gl_tex_info_ids << test.tex_name
      puts "3 here: #{test.tex_name}"
      @infos  << test
      @alt_infos[@alt_infos.count.to_s] = test

      first_id_value = gl_tex_info_ids[0]
      gl_tex_info_ids.each do |id|
        found_fault = true if first_id_value != id
        puts "FOUND FAULT IN GL TEX INFO HERE. IF THE IDs DONT MATCH, then the wrong tiles will be loaded." if found_fault
        break if found_fault == true
      end
      first_run = false
    end

    @out_of_bounds_terrain_index = @infos.count - 1

    @off_edge_map_value = {'height' => 3, 'terrain_index' => @out_of_bounds_terrain_index }

    # image = Gosu::Image.new("/Users/bendana/projects/line-em-up/line-em-up/media/earth_3.png", :tileable => true)
    # @images << image
    # @infos << image.gl_tex_info

    @map_tile_width =  @map["map_tile_width"]
    @map_tile_height = @map["map_tile_height"]

    @map_pixel_width  = (@map_tile_width  * @tile_pixel_width ).to_i
    @map_pixel_height = (@map_tile_height * @tile_pixel_height).to_i
    # puts "@map_pixel_height = (EXTERIOR_MAP_HEIGHT * @tile_pixel_height)"
    # puts "#{@map_pixel_height} = (#{EXTERIOR_MAP_HEIGHT} * #{@tile_pixel_height})"

    # @map_tile_width = @map["map_width"]
    # @map_tile_height = @map["map_height"]
    @map_data = @map["data"]
    # if @debug
      @map_data.each_with_index do |e, y|
        e.each_with_index do |v, x|
          @map_data[y][x] = @map_data[y][x].merge({'gps_y' => (@map_tile_height - y) - 1, 'gps_x' => (@map_tile_width - x) - 1 })
        end
      end
    # end
    @visual_map_of_visible_to_map = Array.new(@visible_map_tile_height + @extra_map_tile_height) { Array.new(@visible_map_tile_width + @extra_map_tile_width) { nil } }

    # @y_top_tracker    = nil
    # @y_bottom_tracker = nil

    # @x_right_tracker  = nil
    # @x_left_tracker   = nil

    # if player_x && player_y
    #   raise "This case is no longer supported. Can't return objects like buildings from initialize"
    #   init_map
    # end


    if @debug
      @font = Gosu::Font.new(20)
    end

    # puts "@map_data : #{@map_data[0][0]}" 
    # @visible_map = []
    # puts "TOP TRACKERL = player_y + (@visible_map_tile_height / 2) + (@extra_map_tile_height / 2)"
    # puts "TOP TRACKERL = #{player_y} + (#{@visible_map_tile_height} / 2) + (#{@extra_map_tile_height} / 2)"
    # raise 'stop'

    # @y_add_top_tracker << nil
    # puts @visible_map
  end


  def store_background_data buildings
    map_data = {buildings: {}}
    buildings.each do |b_id, b|
      next if b.class::PRESERVE_ON_MAP_EXIT == false
      map_data[:buildings][b.current_map_tile_y.to_s] ||= {}
      map_data[:buildings][b.current_map_tile_y.to_s][b.current_map_tile_x.to_s] ||= []
      map_data[:buildings][b.current_map_tile_y.to_s][b.current_map_tile_x.to_s] << {klass_name: b.class.to_s, data: {faction_id: b.get_faction_id }}
    end
    ConfigSetting.set_mapped_setting(@save_file_path, [@map_name, 'map_objects'], map_data)
  end

  def get_random_off_map_value
    # DID NOT REALLY WORK....
    # return {'height' => 3, 'terrain_index' => @out_of_bounds_terrain_index }
    return @off_edge_map_value
  end

  # def recenter_map center_target
  #   raise "did not work"
  #   @gps_map_center_x  = center_target.current_map_tile_x
  #   @gps_map_center_y  = center_target.current_map_tile_x

  #   (0..@visible_map_tile_height + @extra_map_tile_height - 1).each_with_index do |visible_height, index_h|
  #     y_offset = visible_height - @visible_map_tile_height / 2
  #     y_offset = y_offset - @extra_map_tile_height / 2
  #     # @y_add_top_tracker << (player_y + y_offset)
  #     (0..@visible_map_tile_width + @extra_map_tile_width - 1).each_with_index do |visible_width, index_w|
  #       x_offset = visible_width  - @visible_map_tile_width  / 2
  #       x_offset = x_offset - @extra_map_tile_width / 2
  #       y_index = @gps_map_center_y + y_offset
  #       x_index = @gps_map_center_x + x_offset
  #       @visible_map[index_h][index_w] = @map_data[y_index][x_index]
  #       @visual_map_of_visible_to_map[index_h][index_w] = "#{y_index}, #{x_index}"
  #     end
  #   end
  #   @current_map_pixel_center_x = center_target.current_map_pixel_x
  #   @current_map_pixel_center_y = center_target.current_map_pixel_y

  #   @local_map_movement_y = @current_map_pixel_center_x
  #   @local_map_movement_x = @current_map_pixel_center_y
  # end

  # @current_map_pixel_center_x and @current_map_pixel_center_y must be defined at this point.
  # Shouldn't use center here.. should use player center..
  def init_map current_target_tile_x, current_target_tile_y, window

    @gps_map_center_x = @map_tile_width - 1 - current_target_tile_x
    @gps_map_center_y = @map_tile_height - 1 - current_target_tile_y

    map_has_a_center_x_square = @map_tile_width  % 2 == 1 #=  @map["map_width"]
    map_has_a_center_y_square = @map_tile_height % 2 == 1 #= @map["map_height"]

    # Keeping offsets in pos
    @gps_tile_offset_x = (@visible_map_tile_width  + @extra_map_tile_width ) / 2
    @gps_tile_offset_y = (@visible_map_tile_height + @extra_map_tile_height) / 2
    is_x_offset_uneven = (@visible_map_tile_width  + @extra_map_tile_width ) % 2 == 1
    is_y_offset_uneven = (@visible_map_tile_height + @extra_map_tile_height) % 2 == 1

    # if map_has_a_center_x_square

    @map_tile_left_row   = @gps_map_center_x + @gps_tile_offset_x - 1
    @map_tile_right_row  = @gps_map_center_x - @gps_tile_offset_x

    @map_tile_top_row    = @gps_map_center_y - @gps_tile_offset_y
    @map_tile_bottom_row = @gps_map_center_y + @gps_tile_offset_y - 1

    @map_tile_bottom_row += 1 if is_y_offset_uneven
    @map_tile_right_row  += 1 if is_x_offset_uneven

    # puts "OFFSETS HERE: #{is_x_offset_uneven} - #{is_y_offset_uneven}"

    # puts "@map_tile_top_row    = #{@map_tile_top_row}"
    # puts "@map_tile_bottom_row = #{@map_tile_bottom_row}"
    # puts "@map_tile_left_row   = #{@map_tile_left_row}"
    # puts "@map_tile_right_row  = #{@map_tile_right_row}"
    # puts "@gps_map_center_x    = #{@gps_map_center_x}"
    # puts "@gps_map_center_y    = #{@gps_map_center_y}"

    # OFFSETS HERE: false - false
    # TOP ROW:    119 # CORRECT
    # BOTTOM ROW: 131 # 130
    # LEFT ROW:   134 # 133
    # RIGHT ROW:  116 # Correct
    # CENTER X: 125
    # CENTER Y: 125


    # @gps_map_center_x =  (@current_map_pixel_center_x / (@tile_pixel_width)).round
    # @gps_map_center_y =  (@current_map_pixel_center_y / (@tile_pixel_height)).round

    buildings = []
    ships = []
    # pickups = []
    # projectiles = []
    # puts "@map_objects"
    # puts @map_objects.inspect

    (0..@visible_map_tile_height + @extra_map_tile_height - 1).each_with_index do |visible_height, index_h|
      y_offset = visible_height - @visible_map_tile_height / 2
      y_offset = y_offset - @extra_map_tile_height / 2
      # @y_add_top_tracker << (player_y + y_offset)
      (0..@visible_map_tile_width + @extra_map_tile_width - 1).each_with_index do |visible_width, index_w|
        x_offset = visible_width  - @visible_map_tile_width  / 2
        x_offset = x_offset - @extra_map_tile_width / 2
        y_index = @gps_map_center_y + y_offset
        x_index = @gps_map_center_x + x_offset

        if @map_data[y_index] && @map_data[y_index][x_index] && x_index >= 0 && y_index >= 0
          @visible_map[index_h][index_w] = @map_data[y_index][x_index]
          @visual_map_of_visible_to_map[index_h][index_w] = "#{y_index}, #{x_index}"
        else
          @visible_map[index_h][index_w] = @off_edge_map_value
        @visual_map_of_visible_to_map[index_h][index_w] = "N/A"
        end

      end
    end

    # When do we delete it from map objects... 
    if @map_objects["buildings"]
      datas = @map_objects["buildings"]
      datas.each do |y_value, data|
        if @map_data[y_value.to_i].nil?
          puts "Could not create building. Y VALUE EXCEEDS MAP LENGTH - #{@map_data.length} < #{y_value}"
          puts data.inspect
          raise "Could not create building. Y VALUE EXCEEDS MAP LENGTH - #{@map_data.length} < #{y_value}"
        end
        # puts "building DATA - #{y_index} - #{x_index}"
        # puts "y_value: #{y_value}, data: #{data}"
        data.each do |x_value, elements|
          if @map_data[y_value.to_i][x_value.to_i].nil?
            puts "Could not create building. X VALUE EXCEEDS MAP LENGTH - #{@map_data[y_value.to_i].length} < #{x_value}"
            puts elements.inspect
            raise "Could not create building. X VALUE EXCEEDS MAP LENGTH - #{@map_data[y_value.to_i].length} < #{x_value}"
          end
          elements.each do |element|
            klass = eval(element["klass_name"])
            data  = element["data"]
            # puts "DATA HERE"
            # puts data.inspect
            # puts "MAP DATA NIL" if @map_data.nil?
            # puts "@map_data[y_value.to_i] NIL" if @map_data[y_value.to_i].nil?
            # puts "@map_data.length: #{@map_data.length} - y_value: #{y_value.to_i}" if @map_data[y_value.to_i].nil?
            # puts "@map_data[y_value.to_i][x_value.to_i] NIL" if @map_data[y_value.to_i][x_value.to_i].nil?

            options = {z: @map_data[y_value.to_i][x_value.to_i]['height']}
            if data
              converted_data = {}
              data.each do |key, value|
                converted_data[key.to_sym] = value
              end
              # puts "2DATA"
              # puts converted_data.inspect
              options.merge!(converted_data)
            end
            # puts "OPTIONS"
            # puts options.inspect
            b = klass.new(x_value.to_i, y_value.to_i, window, options)
            # puts "CREATED NEW B: #{b.class}"
            buildings << b

          end
        end
      end
    end

    # puts "ENEMEIS: #{@map_objects["ships"].count}"
    if @map_objects["ships"]
      datas = @map_objects["ships"]
      datas.each do |y_value, data|
        # puts "building DATA - #{y_index} - #{x_index}"
        # puts "y_value: #{y_value}, data: #{data}"
        data.each do |x_value, elements|
          elements.each do |element|
            klass = eval(element["klass_name"])
            # IF pixels exist in the future, load pixels.... If so, need to multiply pixels by scale., and then divide by scale before saving.
            ships << klass.new(nil, nil, x_value.to_i, y_value.to_i)
          end
        end
      end
    end
    @map_inited = true
    # @only return active objects?
    # Except enemies, cause they can have movement outside of the visible map?
   # puts "RETURING BUILDINGS: #{buildings.count}"
   # puts "RETURING ships: #{ships.count}"
    return {ships: ships, buildings: buildings}
  end

  # def convert_gps_to_screen
  # end

  # How to draw enemies that can move? Projectiles and enemies
  def update_objects_relative_to_map local_map_movement_x, local_map_movement_y, objects, tile_movement_x, tile_movement_y

    delete_index = []
    objects.each do |object_id, object|
      # Objects will move themselves across tiles
      if tile_movement_x
        object.x = object.x + tile_movement_x
      end
      # object.x_offset = local_map_movement_x

      if tile_movement_y
        object.y = object.y + tile_movement_y
      end
      # object.y_offset = local_map_movement_y

      object.update_offsets(local_map_movement_x, local_map_movement_y)
    end

    # delete_index.each do |i|
    #   objects.delete_at(i)
    # end

    return objects
  end


  # bUILDING LOCATION ON TRIGGER : 126 - 125
  # RESULTS HERE: [825.0, 525.0]
  # Don't factor in x or y offset here.
  def gps_tile_coords_to_center_screen_coords tile_x, tile_y
    raise "STOP USING ME"
    # @gps_map_center_y
    # @gps_map_center_x

    x_offset = (@visible_map_tile_width  / 2.0)
    y_offset = (@visible_map_tile_height / 2.0)
    if tile_x < @gps_map_center_x - x_offset && tile_x > @gps_map_center_x + x_offset
      return nil
    else
      # location - Left GPS edge of map. Should be in Integers
      distance_from_left = (@gps_map_center_x + x_offset) - (tile_x)
     # puts "distance_from_left = tile_x - (@gps_map_center_x + x_offset)"
     # puts "#{distance_from_left} = #{tile_x} - (#{@gps_map_center_x} + #{x_offset})"

      # bUILDING LOCATION ON TRIGGER : 126 - 125
      # distance_from_left = tile_x - (@gps_map_center_x - x_offset) - 1
      # 5.0 = 126 - (124 - 4.0) - 1

      # Not sure if the
      distance_from_top  = tile_y - (@gps_map_center_y - y_offset)

      x = (distance_from_left * @tile_pixel_width ) + @tile_pixel_width  / 2.0
      y = (distance_from_top  * @tile_pixel_height) + @tile_pixel_height / 2.0
      return [x, y]
    end
  end

  # This is printing out in the wrong order. 249, 249 is reading as 0,0
  # This is confusing.
  def print_visible_map
     # puts "print_visible_map - #{@visual_map_of_visible_to_map[0].length} x #{@visual_map_of_visible_to_map.length}"
     #  @visual_map_of_visible_to_map.each do |y_row|
     #    output = "|"
     #    y_row.each do |x_row|
     #      output << x_row
     #      output << '|'
     #    end
     #   puts output
     #   puts "_" * 80
     #  end
  end

  # I think this is dependent on the map being square
  def verify_visible_map
    # # Doesn't work with recenter function
    # if @map_inited && @debug

    #   @visual_map_of_visible_to_map.each_with_index do |y_row, index|
    #     # print_visible_map if y_row.nil? || y_row.empty? || y_row.length != @visible_map_tile_width + @extra_map_tile_width - 1
    #     raise "Y Column was nil" if y_row.nil? || y_row.empty?
    #     raise "Y Column size wasn't correct. Expected #{@visible_map_tile_width + @extra_map_tile_width}. GOT: #{y_row.length}" if y_row.length != @visible_map_tile_width + @extra_map_tile_width
    #   end

    #   # puts "verify_visible_map"
    #   y_length = @visual_map_of_visible_to_map.length - 1
    #   x_length = @visual_map_of_visible_to_map[0].length - 1
    #   raise "MAP IS TOO SHORT Y: #{@visual_map_of_visible_to_map.length} != #{@visible_map_tile_height + @extra_map_tile_height}"  if @visual_map_of_visible_to_map.length    != @visible_map_tile_height + @extra_map_tile_height
    #   raise "MAP IS TOO SHORT X: #{@visual_map_of_visible_to_map[0].length} != #{@visible_map_tile_width + @extra_map_tile_width}" if @visual_map_of_visible_to_map[0].length != @visible_map_tile_width  + @extra_map_tile_width
    #   element = @visual_map_of_visible_to_map[0][0]
    #   int = 0
    #   outer_int = 0
    #   while element == "N/A" && outer_int <= x_length
    #     while element == "N/A" && int < @visual_map_of_visible_to_map.length - 1
    #       int += 1
    #       element = @visual_map_of_visible_to_map[int][outer_int]
    #     end
    #     outer_int += 1
    #   end
    #   if element && element != "N/A"
    #     comp_y, do_nothing = element.split(', ').collect{|v| v.to_i}
    #     (1..y_length).each do |y|
    #       first_x_element = @visual_map_of_visible_to_map[y][0]
    #       next if first_x_element == "N/A"
    #       value_y, value_x = first_x_element.split(', ').collect{|v| v.to_i}
    #       (1..x_length).each do |x|
    #         element = @visual_map_of_visible_to_map[y][x]
    #         next if element == "N/A"
    #         do_nothing, comp_x = element.split(', ').collect{|v| v.to_i}
    #         if value_x + x == comp_x
    #           # All Good
    #         else
    #           print_visible_map
    #           raise "1ISSUE WITH MAP AT X value Y: #{y} and X: #{x} -> #{value_x + x} != #{comp_x}"
    #         end
    #         if value_y == comp_y + y - int
    #           # All Good
    #         else
    #           print_visible_map
    #           raise "2ISSUE WITH MAP AT Y Value Y: #{y} and X: #{x} -> #{value_y} != #{comp_y + y - int}"
    #         end
    #       end
    #     end
    #   else
    #     # puts "START MAP NOT VERIFIABLE"
    #     # print_visible_map
    #     # puts "END   MAP NOT VERIFIABLE"
    #   end
    # end
  end


  def update center_target_map_pixel_movement_x, center_target_map_pixel_movement_y, buildings, pickups, viewable_pixel_offset_x, viewable_pixel_offset_y
    raise "WRONG MAP WIDTH!  Expected #{@visible_map_tile_width  + @extra_map_tile_width } Got #{@visible_map[0].length}" if @visible_map[0].length != @visible_map_tile_width  + @extra_map_tile_width
    raise "WRONG MAP HEIGHT! Expected #{@visible_map_tile_height + @extra_map_tile_height} Got #{@visible_map.length}"    if @visible_map.length    != @visible_map_tile_height + @extra_map_tile_height

# player 0 - 1
# @gps_map_center_x: 0
# @gps_map_center_y: -2
# @map_tile_left_row    = 6
# @map_tile_right_row = -7
# @map_tile_top_row   = -7
# @map_tile_bottom_row  = 2

    # puts "UPDATE --------------------- UPDATE"
    # puts "@gps_map_center_x: #{@gps_map_center_x}"
    # puts "@gps_map_center_y: #{@gps_map_center_y}"
    # puts "@map_tile_left_row    = #{@map_tile_left_row}"
    # puts "@map_tile_right_row = #{@map_tile_right_row}"
    # puts "@map_tile_top_row   = #{@map_tile_top_row}"
    # puts "@map_tile_bottom_row  = #{@map_tile_bottom_row}"
    # puts "@gps_map_center_x    = #{@gps_map_center_x}"
    # puts "@gps_map_center_y    = #{@gps_map_center_y}"
    print_visible_map
    # @map_tile_left_row   = @gps_map_center_x + @gps_tile_offset_x - 1
    # @map_tile_right_row  = @gps_map_center_x - @gps_tile_offset_x

    # @map_tile_top_row    = @gps_map_center_y - @gps_tile_offset_y
    # @map_tile_bottom_row = @gps_map_center_y + @gps_tile_offset_y - 1


    if @debug
      # puts "@gps_map_center_y: #{@gps_map_center_y}, @gps_map_center_x: #{@gps_map_center_x}"
    end

    # viewable_pixel_offset_x, viewable_pixel_offset_y

    @current_map_pixel_center_x = center_target_map_pixel_movement_x if @current_map_pixel_center_x.nil?
    @current_map_pixel_center_y = center_target_map_pixel_movement_y if @current_map_pixel_center_y.nil?

    # puts "PLAYER: #{player_x} - #{player_y} against #{@current_map_pixel_center_x} - #{@current_map_pixel_center_y}"
    @local_map_movement_y = (center_target_map_pixel_movement_y + viewable_pixel_offset_y) - @current_map_pixel_center_y
    # puts "@local_map_movement_y = #{@local_map_movement_y}"
    # puts "#{@local_map_movement_y} = #{player_y} -#{ @current_map_pixel_center_y}"
    @local_map_movement_x = (center_target_map_pixel_movement_x + viewable_pixel_offset_x) - @current_map_pixel_center_x
    # puts "HERE:#{ @local_map_movement_x} = (#{center_target_map_pixel_movement_x} + #{viewable_offset_x}) - #{@current_map_pixel_center_x}"
    # puts "@local_map_movement_x = #{@local_map_movement_x}"

    # player.relative_object_offset_x = @local_map_movement_x
    # player.relative_object_offset_y = @local_map_movement_y

    tile_movement = false

    tile_movement_x = nil
    tile_movement_y = nil

    # 1 should be 1 GPS coord unit. No height scale should be on it.
    if @local_map_movement_y >= @tile_pixel_height# / @visible_map_tile_height.to_f# * @height_scale * 1.1
     puts "ADDING IN ARRAY 1 - SOUTH"
      tile_movement = true
      if @current_map_pixel_center_y < (@map_pixel_height)
        # puts "CURRENT WAS LESS THAN EXTERNIOR: #{@current_map_pixel_center_y} - #{EXTERIOR_MAP_HEIGHT}"
        @gps_map_center_y -= 1 # Should this be getting smaller... maybe amybe not
        # @y_add_top_tracker << @y_top_tracker
        # Show edge of map
        # @map_tile_left_row  
        # @map_tile_right_row 
        # @map_tile_top_row    
        # @map_tile_bottom_row

        @map_tile_bottom_row -= 1
        @map_tile_top_row    -= 1

        # if @gps_map_center_y + @gps_tile_offset_y > (@map_tile_height)
        if @map_tile_top_row < 0
         # puts "ADDING IN EDGE OF MAP"
          @visual_map_of_visible_to_map.pop
          @visual_map_of_visible_to_map.unshift(Array.new(@visible_map_tile_width + @extra_map_tile_width) { "N/A" })

          @visible_map.pop
          if @map_tile_top_row == -1
            @visible_map.unshift(Array.new(@visible_map_tile_width + @extra_map_tile_width) { @off_edge_map_value })
          else
            @visible_map.unshift(Array.new(@visible_map_tile_width + @extra_map_tile_width) { get_random_off_map_value })
          end
        else
         # puts "ADDING NORMALLY"
          @visible_map.pop
          @visual_map_of_visible_to_map.pop
          # @y_add_top_tracker << (player_y + y_offset)
          new_array = []
          new_debug_array = []
          (0..@visible_map_tile_width + @extra_map_tile_width - 1).each_with_index do |visible_width, index_w|
            # x_index = @map_tile_width - @gps_map_center_x + visible_width - @gps_tile_offset_x
            x_index = @map_tile_right_row + index_w
            if x_index < @map_tile_width && x_index >= 0
              # Flipping Y Axis when retrieving from map data
              # y_index = (@map_tile_height - ((@gps_map_center_y) + @gps_tile_offset_y))
              y_index = @map_tile_top_row
              # puts "(@map_tile_height - ((@gps_map_center_y) + @gps_tile_offset_y)) - 1"
              # puts "(#{@map_tile_height} - ((#{@gps_map_center_y}) + #{@gps_tile_offset_y})) - 1"
              # (250 - ((126) + 9)) - 1
              # puts y_index
              new_array << @map_data[y_index][x_index]
              new_debug_array << "#{y_index}, #{x_index}"
            else
              # puts "ARRAY 1 - X WAS OUT OF BOUNDS - #{clean_gps_map_center_x + x_offset}"
              new_debug_array << "N/A"
              if x_index == -1 || x_index == @map_tile_width
                new_array << @off_edge_map_value
              else
                new_array << get_random_off_map_value
              end
              
            end
            # puts "VISIBLE_MAX 0 X #{index_w} = @map_data[#{( @map_tile_height - @y_top_tracker )}][#{clean_gps_map_center_x + x_offset}]"
          end

          # X is coming in on the wrong side?
          # new_array.reverse!

          @visible_map.unshift(new_array)

          @visual_map_of_visible_to_map.unshift(new_debug_array)

          # verify_visible_map

          # value = "INSIDE MAP"
        end
        # puts "MAP ADDED at #{@current_map_pixel_center_y} w/ - top tracker: #{@y_top_tracker}"
        tile_movement_y       = -@tile_pixel_height
        @current_map_pixel_center_y = @current_map_pixel_center_y + @tile_pixel_height# / @visible_map_tile_height.to_f
        @local_map_movement_y = @local_map_movement_y - @tile_pixel_height# / @visible_map_tile_height.to_f
      else
        # Without this, you stick to the edge of the map?
        @local_map_movement_y = 0 if @local_map_movement_y > 0
      end
    end






    # Adding to bottom of map
    # Convert on screen movement to map
    if @local_map_movement_y <= -@tile_pixel_height# / @visible_map_tile_height.to_f
     puts "ADDING IN ARRAY 2 - NORTH - #{@map_tile_top_row}"
      tile_movement = true
      if @current_map_pixel_center_y > 0
       # puts "PRE gps_map_center_y: #{@gps_map_center_y}"
        @gps_map_center_y += 1
        # @map_tile_left_row  
        # @map_tile_right_row 
        @map_tile_top_row    += 1
        @map_tile_bottom_row += 1

        # Have to increment by one, or else duplicating row
        # local_gps_map_center_y = @gps_map_center_y + 1
       # puts "POST gps_map_center_y: #{@gps_map_center_y}"

        # @gps_tile_offset_y = @visible_map_tile_height / 2 + @extra_map_tile_height / 2
        # @gps_tile_offset_x = @visible_map_tile_width/ 2 + @extra_map_tile_width / 2

        # Show edge of map 
        # if local_gps_map_center_y - @gps_tile_offset_y <= 0
       # puts "@map_tile_top_row <= 0"
       # puts "#{@map_tile_top_row} <= 0"
        if @map_tile_bottom_row >= @map_tile_height
         # puts "CASE 1"
          @visible_map.shift
          @visual_map_of_visible_to_map.shift

          if @map_tile_bottom_row == @map_tile_height
            @visible_map.push(Array.new(@visible_map_tile_width + @extra_map_tile_width) { @off_edge_map_value })
          else
            @visible_map.push(Array.new(@visible_map_tile_width + @extra_map_tile_width) { get_random_off_map_value })
          end

          # @visible_map.push(Array.new(@visible_map_tile_width + @extra_map_tile_width) { @off_edge_map_value })
          @visual_map_of_visible_to_map.push(Array.new(@visible_map_tile_width + @extra_map_tile_width) { "N/A" })
          # puts "HERE WHAT WAS IT? visible_map.last.length #{@visible_map.last.length}"
          # puts "HERE WHAT WAS IT? visible_map.last[0].length #{@visible_map.last[0].length}"
        else
         # puts "CASE 2"
          # puts "ADDING NORMALLY - #{@current_map_pixel_center_y} -#{ @gps_tile_offset_y} > 0"
          @visible_map.shift
          @visual_map_of_visible_to_map.shift
          # @y_add_top_tracker << (player_y + y_offset)
          new_array = []
          new_debug_array = []
          (0..@visible_map_tile_width + @extra_map_tile_width - 1).each_with_index do |visible_width, index_w|
            # x_index = @map_tile_width - @gps_map_center_x + visible_width - @gps_tile_offset_x
            x_index = @map_tile_right_row + index_w
           # puts "X_INDEX: #{x_index}"
            if x_index < @map_tile_width && x_index >= 0
              # y_index = (@map_tile_height - ((local_gps_map_center_y ) - @gps_tile_offset_y))
             # puts "YINDEX CREATED: #{@map_tile_height} - #{@map_tile_top_row}"
              y_index = @map_tile_bottom_row
             # puts "Y:INDEX: #{y_index}"
              new_array << @map_data[y_index][x_index]
              new_debug_array << "#{y_index}, #{x_index}"
            else
              # puts "ARRAY 1 - X WAS OUT OF BOUNDS - #{clean_gps_map_center_x + x_offset}"
              new_debug_array << "N/A"
              if x_index == @map_tile_width && x_index == -1
                new_array << @off_edge_map_value
              else
                new_array << get_random_off_map_value
              end
            end
            # puts "VISIBLE_MAX 0 X #{index_w} = @map_data[#{( @map_tile_height - @y_top_tracker )}][#{clean_gps_map_center_x + x_offset}]"
          end

          # X is coming in on the wrong side?
          # new_array.reverse!

          @visible_map.push(new_array)

          @visual_map_of_visible_to_map.push(new_debug_array)

          # verify_visible_map

          # value = "INSIDE MAP"
        end
        # puts "MAP ADDED at #{@current_map_pixel_center_y} w/ - top tracker: #{@y_top_tracker}"
        tile_movement_y       = @tile_pixel_height
        @current_map_pixel_center_y = @current_map_pixel_center_y - @tile_pixel_height# / @visible_map_tile_height.to_f
        @local_map_movement_y = @local_map_movement_y + @tile_pixel_height# / @visible_map_tile_height.to_f
      else
        # Without this, you stick to the edge of the map?
        @local_map_movement_y = 0 if @local_map_movement_y > 0
      end
    end


    # Moving to the RIGHT
    # if @local_map_movement_x >= @tile_pixel_width 
    #  # puts "TEST HERE: #{@gps_map_center_x} - #{@map_tile_width}"
    # end
    if @local_map_movement_x >= @tile_pixel_width && @gps_map_center_x < @map_tile_width
     puts "ADDING IN ARRAY 3 - WEST"
     # puts "!(@gps_map_center_x >= @map_tile_width)"
     # puts "!(#{@gps_map_center_x} >= #{@map_tile_width})"
     # puts "#{!(@gps_map_center_x >= @map_tile_width)}"
      tile_movement = true
      # print_visible_map
      if @current_map_pixel_center_x < (@map_pixel_width)
       # puts "PRE GPS MAP CENTER X: #{@gps_map_center_x}"
        @gps_map_center_x    -= 1
        # @map_tile_left_row  
        # @map_tile_right_row 
        # @map_tile_top_row    
        # @map_tile_bottom_row
        @map_tile_right_row  -= 1
        @map_tile_left_row   -= 1


        # puts "POST GPS MAP CENTER X #{@gps_map_center_x}"

        # if @map_tile_right_row > (@map_tile_width)
       # puts "@map_tile_right_row <= 0"
       # puts "#{@map_tile_right_row} <= 0"
        # @map_tile_right_row <= 0
        # -8 <= 0
        if @map_tile_right_row < 0
         puts "RIGHT EDGE OF MAP"

          @visible_map.each do |row|
            row.pop
            if @map_tile_right_row == -1
              row.unshift(@off_edge_map_value)
            else
              row.unshift(get_random_off_map_value)
            end
          end
          @visual_map_of_visible_to_map.each do |y_row|
            y_row.pop
            y_row.unshift("N/A")
          end

        else
         puts "NORMAL MAP EDGE:"
         # puts "@map_tile_right_row > (@map_tile_width)"
         # puts "#{@map_tile_right_row} <= #{(@map_tile_width)}"
          # START
          # ASDDING NORMAL MAP EDGE:
          # @map_tile_right_row > (@map_tile_width)
          # 100 <= 250
          # EDGE
          # @map_tile_right_row > (@map_tile_width)
          # -8 <= 250

          @visible_map.each do |y_row|
            y_row.pop
          end
          @visual_map_of_visible_to_map.each do |y_row|
            y_row.pop
          end

          new_array       = []
          new_debug_array = []
          (0..@visible_map_tile_height + @extra_map_tile_height - 1).each_with_index do |visible_height, index_w|
            # x_index = @map_tile_right_row + index_w
            y_index = @map_tile_top_row + index_w
           # puts "TEST111"
           # puts "#{y_index} = #{@map_tile_bottom_row} + #{index_w}"
            # START
            # TEST111
            # 119 = 130 + 0 .. 130 = 130 + 11
            # EDGE
            # TEST111
            # 119 = 130 + 0 .. 130 = 130 + 11

            if y_index < @map_tile_height && y_index >= 0
             # puts "WAS NOT OFF MAP EDGE: y_index < @map_tile_height && y_index >= 0"
             # puts "#{y_index} < #{@map_tile_height} && y_index >= #{0}"
              # IMPLEMENT!!!
              x_index = @map_tile_right_row
              new_array << @map_data[y_index][x_index]
              new_debug_array << "#{y_index}, #{x_index}"
            else
              # puts "ARRAY 1 - X WAS OUT OF BOUNDS - #{clean_gps_map_center_x + x_offset}"
              new_debug_array << "N/A"
              if y_index == @map_tile_height && y_index == -1
                new_array << @off_edge_map_value
              else
                new_array << get_random_off_map_value
              end
            end
            # puts "VISIBLE_MAX 0 X #{index_w} = @map_data[#{( @map_tile_height - @y_top_tracker )}][#{clean_gps_map_center_x + x_offset}]"
          end

          new_array.each_with_index do |element, index|
            @visible_map[index].unshift(element)
          end
          new_debug_array.each_with_index do |element, index|
            @visual_map_of_visible_to_map[index].unshift(element)
          end
          # verify_visible_map
        end
        # puts "MAP ADDED at #{@current_map_pixel_center_y} w/ - top tracker: #{@y_top_tracker}"
        tile_movement_x       = @tile_pixel_height
        @current_map_pixel_center_x = @current_map_pixel_center_x + @tile_pixel_width# / @visible_map_tile_height.to_f
        @local_map_movement_x = @local_map_movement_x - @tile_pixel_width# / @visible_map_tile_height.to_f
      else
        # Without this, you stick to the edge of the map?
        @local_map_movement_x = 0 if @local_map_movement_x > 0
      end
    else
      # puts "TEST HERE FAIL"
      # puts "@gps_map_center_x >= @map_tile_width - 1"
      # puts "#{@gps_map_center_x} >= #{@map_tile_width - 1}"
    end
  

    # MOVING TO THE LEFT
    if @local_map_movement_x <= -@tile_pixel_width# * @width_scale * 1.1
     puts "ADDING IN ARRAY 4 - EAST"
      # print_visible_map
      if @current_map_pixel_center_x < (@map_pixel_width)
       # puts "PRE GPS MAP CENTER X: #{@gps_map_center_x}"
        @gps_map_center_x    += 1
        @map_tile_left_row   += 1
        @map_tile_right_row  += 1
        # @map_tile_top_row    
        # @map_tile_bottom_row

       # puts "POST GPS MAP CENTER X #{@gps_map_center_x}"

        if @map_tile_left_row >= @map_tile_width
         # puts "ADDING IN RIGHT EDGE OF MAP"
          @visible_map.each do |row|
            row.shift
            if @map_tile_left_row == @map_tile_width
              row.push(@off_edge_map_value)
            else
              row.push(get_random_off_map_value)
            end
          end
          @visual_map_of_visible_to_map.each do |y_row|
            y_row.shift
            y_row.push("N/A")
          end

        else
         # puts "ASDDING NORMAL MAP EDGE:"

          @visible_map.each do |y_row|
            y_row.shift
          end
          @visual_map_of_visible_to_map.each do |y_row|
            y_row.shift
          end

          new_array       = []
          new_debug_array = []
          (0..@visible_map_tile_height + @extra_map_tile_height - 1).each_with_index do |visible_height, index_w|
            # y_index = (@map_tile_height - @gps_map_center_y + visible_height - @gps_tile_offset_x)
            y_index = @map_tile_top_row + index_w
            # y_offset = visible_height  - @visible_map_tile_height  / V
            # y_offset = y_offset - @extra_map_tile_height / 2
            # y_index = @map_tile_height - @gps_map_center_y + y_offset
            if y_index < @map_tile_height && y_index >= 0
              # IMPLEMENT!!!
              x_index = @map_tile_left_row
              new_array << @map_data[y_index][x_index]
              new_debug_array << "#{y_index}, #{x_index}"
            else
              # puts "ARRAY 1 - X WAS OUT OF BOUNDS - #{clean_gps_map_center_x + x_offset}"
              new_debug_array << "N/A"
              if y_index == @map_tile_height && y_index == 0
                new_array << @off_edge_map_value
              else
                new_array << get_random_off_map_value
              end
            end
            # puts "VISIBLE_MAX 0 X #{index_w} = @map_data[#{( @map_tile_height - @y_top_tracker )}][#{clean_gps_map_center_x + x_offset}]"
          end

          new_array.each_with_index do |element, index|
            @visible_map[index].push(element)
          end
          new_debug_array.each_with_index do |element, index|
            @visual_map_of_visible_to_map[index].push(element)
          end
          # verify_visible_map
        end
        tile_movement_x       = -@tile_pixel_height
        @current_map_pixel_center_x = @current_map_pixel_center_x - @tile_pixel_width# / @visible_map_tile_height.to_f
        @local_map_movement_x = @local_map_movement_x + @tile_pixel_width# / @visible_map_tile_height.to_f
      else
        # Without this, you stick to the edge of the map?
        @local_map_movement_x = 0 if @local_map_movement_x > 0
      end
    end

    # puts "aFTER EVERYTING"
    # print_visible_map
    verify_visible_map
    # puts "aFTER EVERYTING"
    # Reject here or in game_window, if off of map? Still need to update enemies that can move while off-screen

    # ADD BACK IN AFTER MAP FIXED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Not buildings though, they are updated elsewhere - in exec_gl
    # projectiles = update_objects_relative_to_map(@local_map_movement_x, @local_map_movement_y, projectiles, tile_movement_x, tile_movement_y)
    # projectiles.reject!{|p| p == false }

    # raise "OFFSET IS OFF @y_top_tracker - offset_y != @gps_map_center_y: #{@y_top_tracker} - #{offset_y} != #{@gps_map_center_y}"       if @y_top_tracker     - offset_y != @gps_map_center_y
    # raise "OFFSET IS OFF @y_bottom_tracker + offset_y != @gps_map_center_y: #{@y_bottom_tracker} + #{offset_y} != #{@gps_map_center_y}" if @y_bottom_tracker  + offset_y != @gps_map_center_y
    # raise "OFFSET IS OFF @x_right_tracker - offset_x != @gps_map_center_x: #{@x_right_tracker} - #{offset_x} != #{@gps_map_center_x}"   if @x_right_tracker   - offset_x != @gps_map_center_x
    # raise "OFFSET IS OFF @x_left_tracker + offset_x != @gps_map_center_x: #{@x_left_tracker} + #{offset_x} != #{@gps_map_center_x}"     if @x_left_tracker    + offset_x != @gps_map_center_x
    return {pickups: pickups, buildings: buildings}
  end

  
  def draw player, player_x, player_y, buildings, pickups
    return false if @graphics_setting != :basic

    # @dirt_image = Gosu::Image.new(MEDIA_DIRECTORY + '/earth.png')
    # @snow_image = Gosu::Image.new(MEDIA_DIRECTORY + '/snow.png')
    # @water_image = Gosu::Image.new(MEDIA_DIRECTORY + '/snow.png')
    # @out_of_bounds_image = Gosu::Image.new(MEDIA_DIRECTORY + '/earth_3.png')
    # {"height"=>2.402866873199251, "terrain_type"=>"dirt", "terrain_index"=>0, "corner_heights"=>{"top_left"=>2.3248380114363396, "top_right"=>2.5335181135447193, "bottom_left"=>1.990020819472701, "bottom_right"=>2.3316200544175043}, "terrain_paths_and_weights"=>{"top_left"=>{"0"=>1.0}, "top_right"=>{"0"=>1.0}, "bottom_left"=>{"0"=>1.0}, "bottom_right"=>{"0"=>1.0}}, "gps_y"=>130, "gps_x"=>6}

    tile_row_y_max = @visible_map.length #@visible_map.length - 1 - (@extra_map_tile_height)
    @visible_map.each_with_index do |y_row, y_index|
      tile_row_x_max = y_row.length # y_row.length - 1 - (@extra_map_tile_width)
      y_row.each_with_index do |x_element, x_index|
        # splits across middle 0  -7..0..7 if visible map is 15
        new_x_index = x_index - (tile_row_x_max / 2.0)
        new_y_index = y_index - (tile_row_y_max / 2.0)

        screen_x = @tile_pixel_width   * new_x_index
        screen_x += @tile_pixel_width  * 4.0
        screen_y = @screen_pixel_height - @tile_pixel_height  * new_y_index
        screen_y -= @tile_pixel_height  * 4.0

        case x_element['terrain_type']
        when 'dirt'
          @dirt_image.draw(screen_x + @local_map_movement_x, screen_y - @local_map_movement_y, ZOrder::Background, @adjusted_height_scale, @adjusted_height_scale)
        when 'snow'
          @snow_image.draw(screen_x + @local_map_movement_x, screen_y - @local_map_movement_y, ZOrder::Background, @adjusted_height_scale, @adjusted_height_scale)
        when 'water'
          @water_image.draw(screen_x + @local_map_movement_x, screen_y - @local_map_movement_y, ZOrder::Background, @adjusted_height_scale, @adjusted_height_scale)
        else
          @out_of_bounds_image.draw(screen_x + @local_map_movement_x, screen_y - @local_map_movement_y, ZOrder::Background, @adjusted_height_scale, @adjusted_height_scale)
        end
      end
    end
  end
  
  # include Gl
  NEAR_VALUE = 1
  FAR_VALUE  = 12
  NDC_X_LENGTH  = 0.1
  NDC_Y_LENGTH  = 0.1
  
  # player param is soley used for debugging
  def exec_gl player, player_x, player_y, buildings, pickups
    return false if @graphics_setting != :advanced

    glClearDepth(0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    # player_x, player_y = [player_x.to_i, player_y.to_i]
    glDepthFunc(GL_GEQUAL)
    glEnable(GL_DEPTH_TEST)

        # radius
        # The radius of the sphere.
        # slices
        # The number of subdivisions around the Z axis (similar to lines of longitude).
        # stacks
        # The number of subdivisions along the Z axis (similar to lines of latitude).
    # glMatrixMode(GL_MODELVIEW);
    # glLoadIdentity
    # # glutSolidSphere(600,1,2)
    # glutSolidSphere(1.0, 20, 16)

    
    # glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    # void glFrustum( GLdouble left,
    #   GLdouble right,
    #   GLdouble bottom,
    #   GLdouble top,
    #   GLdouble nearVal,
    #   GLdouble farVal);

    # nearVal = 1
    # farVal = 100
    glFrustum(-NDC_X_LENGTH, NDC_X_LENGTH, -NDC_Y_LENGTH, NDC_Y_LENGTH, NEAR_VALUE, FAR_VALUE)
    # gluPerspective(45.0, 800 / 600 , 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity

    # // Move the scene back so we can see everything
    # glTranslatef( 0.0f, 0.0f, -100.0f );
    # -10 is as far back as we can go.
    glTranslated(0, 0, -FAR_VALUE)


#     # TEST

# VERT ONE: -0.25 X -0.1
# VERT TWO: -0.25 X 0.1
# VERT THREE: -0.083 X -0.1
# VERT FOUR: -0.083 X 0.1
# glEnable(GL_TEXTURE_2D)
# glBindTexture(GL_TEXTURE_2D, @info.tex_name)
# glBegin(GL_TRIANGLE_STRIP)
#     glTexCoord2d(@info.left, @info.top)
#     # puts "VERT ONE: #{opengl_x} X #{opengl_y}"
#     # edges of screen are 0.5?
#     # 0, 0 is center.
#     # 1, 1 is top RIGHT
#     # -1, 1, is TOP LEFT
#     # 1, -1 is BOTTOM RIGHT
#     # -1, -1, is bottom LEFT

#     # BOTTOM RIGHT VERT
#     glVertex3d(0.25, -0.25, 0.5)
#     glTexCoord2d(@info.left, @info.bottom)
#     # TOP RIGHT VERT
#     glVertex3d(0.25, 0.25, 0.5)
#     glTexCoord2d(@info.right, @info.top)
#     # BOTTOM LEFT VERT
#     glVertex3d(-0.25, -0.25, 0.5)
#     glTexCoord2d(@info.right, @info.bottom)
#     # TOP LEFT VERT
#     glVertex3d(-0.25, 0.25, 0.5)

#     # glVertex3d(-0.25, -0.1, 0.5)
#     # glTexCoord2d(@info.left, @info.bottom)
#     # glVertex3d(-0.25, 0.1, 0.5)
#     # glTexCoord2d(@info.right, @info.top)
#     # glVertex3d(-0.083, -0.1, 0.5)
#     # glTexCoord2d(@info.right, @info.bottom)
#     # glVertex3d(-0.083, 0.1, 0.5)

# glEnd

    # END TEST

    # This is the width and height of each individual terrain segments.
                            # @screen_movement_increment_x == 8 
    # opengl_increment_y = 1 / (@visible_map_tile_height.to_f / 4.0)
    # opengl_increment_y = @open_gl_screen_movement_increment_y
    # opengl_increment_x = 1 / (@visible_map_tile_width.to_f  / 4.0)
    # opengl_increment_x = @open_gl_screen_movement_increment_x

    # offs_y = 1.0 * @local_map_movement_y / (@screen_movement_increment_y)
    # offs_x = 1.0 * @local_map_movement_x / (@screen_movement_increment_x)
    gps_offs_y = @local_map_movement_y / (@tile_pixel_height )
    gps_offs_x = @local_map_movement_x / (@tile_pixel_width )
    # puts "gps_offs_y = @local_map_movement_y / (@tile_pixel_height )"
    # puts "#{gps_offs_y} = #{@local_map_movement_y} / (#{@tile_pixel_height} )"
    screen_offset_x = @tile_pixel_width  * gps_offs_x * -1
    screen_offset_y = @tile_pixel_height * gps_offs_y * -1
    # puts "@screen_pixel_width, @screen_pixel_height, screen_offset_x, screen_offset_y"
    # puts [@screen_pixel_width, @screen_pixel_height, screen_offset_x, screen_offset_y  ]
    offset_result = GeneralObject.convert_screen_pixels_to_opengl(@screen_pixel_width, @screen_pixel_height, screen_offset_x, screen_offset_y)
    opengl_offset_x = offset_result[:o_x]# >= @tile_pixel_width ? 0 : offset_result[:o_x]
    opengl_offset_y = offset_result[:o_y]# >= @tile_pixel_height ? 0 : offset_result[:o_y]
    # raise "SHOUD NOT BE NIL" if opengl_offset_x.nil? || opengl_offset_y.nil?

    # puts "OFF_Y: #{@local_map_movement_y / (@tile_pixel_height ) }= #{@local_map_movement_y} / (#{@tile_pixel_height} )" 
    # offs_x = offs_x + 0.1

    # Cool lighting
    # glEnable(GL_LIGHTING)

    #   glLightfv(GL_LIGHT0, GL_AMBIENT, [0.5, 0.5, 0.5, 1])
    #   glLightfv(GL_LIGHT0, GL_DIFFUSE, [1, 1, 1, 1])
    #   glLightfv(GL_LIGHT0, GL_POSITION, [1, 1, 1,1])
    #   glLightfv(GL_LIGHT1, GL_AMBIENT, [0.5, 0.5, 0.5, 1])
    #   glLightfv(GL_LIGHT1, GL_DIFFUSE, [1, 1, 1, 1])
    #   glLightfv(GL_LIGHT1, GL_POSITION, [100, 100, 100,1])
  
    # @enable_dark_mode = true
    # @enable_dark_mode = false

    # if @enable_dark_mode
    #   # glLightfv(GL_LIGHT6, GL_AMBIENT, [0.5, 0.5, 0.5, 1])
    #   # glLightfv(GL_LIGHT6, GL_DIFFUSE, [0.5, 0.5, 0.5, 1])
    #   # # Dark lighting effect?
    #   # glLightfv(GL_LIGHT6, GL_POSITION, [0, 0, 0,-1])
    #   # glEnable(GL_LIGHT6)
    # else
    #   # glLightfv(GL_LIGHT6, GL_AMBIENT, [1, 1, 1, 1])
    #   # glLightfv(GL_LIGHT6, GL_DIFFUSE, [1, 1, 1, 1])
    #   # # Dark lighting effect?
    #   # glLightfv(GL_LIGHT6, GL_POSITION, [0, 0, 0,-1])
    #   # glEnable(GL_LIGHT6)
    # end

   #  @test = false
   #  if @test



   #    # glEnable(GL_LIGHT0)
   #    # glEnable(GL_LIGHT1)
   #    if true

   #      glLightfv(GL_LIGHT1, GL_SPECULAR, [1.0, 1.0, 1.0, 1.0])
   #      glLightfv(GL_LIGHT1, GL_POSITION, [0, 0, 1.0, 1.0])
   #      glLightf(GL_LIGHT1, GL_CONSTANT_ATTENUATION, 1.5)
   #      glLightf(GL_LIGHT1, GL_LINEAR_ATTENUATION, 0.5)
   #      glLightf(GL_LIGHT1, GL_QUADRATIC_ATTENUATION, 0.2)


   #      glLightf(GL_LIGHT1, GL_SPOT_CUTOFF, 15.0)
   #      glLightfv(GL_LIGHT1, GL_SPOT_DIRECTION, [-1.0, -1.0, 0.0])
   #      glLightf(GL_LIGHT1, GL_SPOT_EXPONENT, 2.0)
   #      glEnable(GL_LIGHT1)
   #    end
   #    glMaterialfv(GL_FRONT, GL_SPECULAR, [1.0, 1.0, 1.0, 1.0])
   #    glMaterialfv(GL_FRONT, GL_SHININESS, [50.0])


   #    glShadeModel( GL_SMOOTH )

   #    # // Renormalize scaled normals so that lighting still works properly.
   #    glEnable( GL_NORMALIZE )
   #    glEnable(GL_COLOR_MATERIAL)

   #   glBegin(GL_TRIANGLES);
   #    # glTexCoord2d(info.left, info.top)
   #    glColor4d(0, 0, 1, 1)
   #    glVertex3f(-0.2, 0.2, 1); 
   #    # glTexCoord2d(info.left, info.bottom)
   #    glColor4d(0, 1, 0, 1)
   #    glVertex3f(-0.2, -0.2, 1); 
   #    # glTexCoord2d(info.right, info.top)
   #    glColor4d(1, 0, 1, 1)
   #    glVertex3f(0.2, 0, 3); 
   #    # glTexCoord2d(info.right, info.bottom)
   #    # glColor4d(1, 1, 1, 1)
   #    # glVertex3f(0.5, -0.5, 3); 
   #   glEnd
   # end

    # START Documentation!
    #                                    # 3 These change colors. 
    #                                       # RGBA - The alpha parameter is a number between 0.0 (fully transparent) and 1.0 (fully opaque).
    #   glLightfv(GL_LIGHT2, GL_AMBIENT, [1, 1, 1, 1])
    #                                    # 3 These change colors. 
    #                                       # RGBA - The alpha parameter is a number between 0.0 (fully transparent) and 1.0 (fully opaque).
    #   glLightfv(GL_LIGHT2, GL_DIFFUSE, [1, 1, 1, 1])
    #   glLightfv(GL_LIGHT2, GL_SPECULAR, [1.0, 1.0, 1.0, 1.0]);

    #   # The vector has values x, y, z, and w.  If w is 1.0, we are defining a light at a point in space.  If w is 0.0, the light is at infinity.  As an example, try adding this code right after you enable the light:
    #   # w is not really a dimension but a scaling factor (used to get some matrix stuff easier done - means you can calculate translations by matrix multiplication instead of an addition)
    #   # kartesian coordiantes its:
    #   # x’=x/w
    #   # y’=y/w
    #   # z’=z/w
    #   glLightfv(GL_LIGHT2, GL_POSITION, [0, 0,0,1])

    #   glEnable(GL_LIGHT2)
    # END Documentation


    # SET MAX LIGHTS HERE
    # glGetIntegerv( GL_MAX_LIGHTS, 1 );
    # @test = true

    # gluProject(world_coords[0], world_coords[1], world_coords[2],
    # modelview.data(), projection.data(),
    # screen_coords.data(), screen_coords.data() + 1, screen_coords.data() + 2);

    if true #!@test
      glEnable(GL_TEXTURE_2D)
      glEnable(GL_BLEND)

      # Not sure the next 3 methods do anything
      # glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE )
      # glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE )
      # glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE)
      tile_row_y_max = @visible_map.length #@visible_map.length - 1 - (@extra_map_tile_height)
      @visible_map.each_with_index do |y_row, y_index|
        tile_row_x_max = y_row.length # y_row.length - 1 - (@extra_map_tile_width)
        y_row.each_with_index do |x_element, x_index|
          # puts "element - #{x_index} #{y_index} "

          # splits across middle 0  -7..0..7 if visible map is 15
          new_x_index = x_index - (tile_row_x_max / 2.0)
          new_y_index = y_index - (tile_row_y_max / 2.0)

          # Screen coords width and height here.
          screen_x = @tile_pixel_width   * new_x_index
          # puts "screen_x = @tile_pixel_width   * new_x_index"
          # puts "#{screen_x} = #{@tile_pixel_width}   * #{new_x_index}"
          screen_y = @tile_pixel_height  * new_y_index
          # puts "screen_y = @tile_pixel_height  * new_y_index"
          # puts "#{screen_y} = #{@tile_pixel_height}  * #{new_y_index}"

          # result = convert_screen_to_opengl(screen_x, screen_y, @tile_pixel_width, @tile_pixel_height)
          result = GeneralObject.convert_screen_pixels_to_opengl(@screen_pixel_width, @screen_pixel_height, screen_x, screen_y, @tile_pixel_width, @tile_pixel_height)
          # puts "X and Y INDEX: #{x_index} - #{y_index}"
          # puts "RESULT HERE: #{result}"
          opengl_coord_x = result[:o_x]
          opengl_coord_y = result[:o_y]
          # opengl_coord_y = opengl_coord_y * -1
          # opengl_coord_x = opengl_coord_x * -1
          opengl_increment_x = result[:o_w]
          opengl_increment_y = result[:o_h]

          # raise "SHOUD NOT BE NIL" if opengl_coord_x.nil? || opengl_coord_y.nil?
          # raise "SHOUD NOT BE NIL" if opengl_increment_x.nil? || opengl_increment_y.nil?
          # puts "NEW DATA TILE OPENGL DATA: #{[opengl_coord_x, opengl_coord_y, opengl_increment_x, opengl_increment_y]}"

          # result = convert_screen_to_opengl(screen_x, screen_y, @tile_pixel_width, @tile_pixel_height)
          # opengl_coord_x = result[:o_x]
          # opengl_coord_y = result[:o_y]
          # # opengl_coord_y = opengl_coord_y * -1
          # # opengl_coord_x = opengl_coord_x * -1
          # opengl_increment_x = result[:o_w]
          # opengl_increment_y = result[:o_h]

          # raise "SHOUD NOT BE NIL" if opengl_coord_x.nil? || opengl_coord_y.nil?
          # raise "SHOUD NOT BE NIL" if opengl_increment_x.nil? || opengl_increment_y.nil?
          # puts "ORIGINAL DATA TILE OPENGL DATA: #{[opengl_coord_x, opengl_coord_y, opengl_increment_x, opengl_increment_y]}"


          if x_element['corner_heights']
            z = x_element['corner_heights']
          else
            z = {'bottom_right' =>  x_element['height'], 'bottom_left' =>  x_element['height'], 'top_right' =>  x_element['height'], 'top_left' =>  x_element['height']}
          end



          # if @debug
          #   # puts "x_element: #{x_element}"
          #   # puts "CONVERTING OPENGL TO SCREEN"
          #   # puts "OX: #{opengl_coord_x - opengl_offset_x} = #{opengl_coord_x} - #{opengl_offset_x}"
          #   # puts "OY: #{opengl_coord_y - opengl_offset_y} = #{opengl_coord_y} - #{opengl_offset_y}"
          #   # x, y = convert_opengl_to_screen(opengl_coord_x - opengl_offset_x, opengl_coord_y - opengl_offset_y)
          #   # puts "@font: x, y = #{x}, #{y}"

          #   # get2dPoint(o_x, o_y, o_z, viewMatrix, projectionMatrix, screen_pixel_width, screen_pixel_height)
          #   # result = get2dPoint(x, y , x_element["height"], glGetFloatv(GL_MODELVIEW_MATRIX), glGetFloatv(GL_PROJECTION_MATRIX), @screen_pixel_width, @screen_pixel_height)
          #   # @font.draw("X #{x_element["gps_x"]} & Y #{x_element["gps_y"]}", result[0], @screen_pixel_height - result[1], ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
          # end



          lights = [{pos: [0,0], brightness: 0.4, radius: 0.5}]
          # Too slow.. FPS droppage
          # projectiles.each do |p|
            # Needs to be updated from x y to map x and map y
            # results = convert_screen_to_opengl(p.x, p.y, nil, nil, true)
            # lights << {pos: [(results[:o_x]), (results[:o_y] * -1)], brightness: 0.3, radius: 0.5}
          # end

          if @enable_dark_mode
            default_colors = [0.3, 0.3, 0.3, 0.3]
          else
            default_colors = [1, 1, 1, 1]
          end
          # left-top, left-bottom, right-top, right-bottom

          # {"top_left"=>{"0"=>1.0}, "top_right"=>{"0"=>0.5, "1"=>0.5}, "bottom_left"=>{"0"=>0.5, "2"=>0.5}, "bottom_right"=>{"0"=>0.25, "1"=>0.25, "2"=>0.5}}

          # if x_element['terrain_paths_and_weights']
          #   terrains = ['terrain_paths_and_weights']
          #  # puts "TERRAINS HERE: ---"
          #  # puts terrains.inspect
          #   # info_top_left
          #   # TERRAINS HERE: ---
          #   # {"top_left"=>{"0"=>1.0}, "top_right"=>{"0"=>0.5, "1"=>0.5}, "bottom_left"=>{"0"=>0.5, "2"=>0.5}, "bottom_right"=>{"0"=>0.25, "1"=>0.25, "2"=>0.5}}

          # else
          #   # z = {'bottom_right' =>  1, 'bottom_left' =>  1, 'top_right' =>  1, 'top_left' =>  1}
          # end

          # error = glGetError
          # if error != 0
          #  puts "FOUND ERROR: #{error}"
          # end
          vert_pos1, vert_pos2, vert_pos3, vert_pos4 = [nil,nil,nil,nil]
          vert_pos1 = [opengl_coord_x - opengl_offset_x, opengl_coord_y - opengl_offset_y, z['top_left']]
          vert_pos2 = [opengl_coord_x - opengl_offset_x, opengl_coord_y + opengl_increment_y - opengl_offset_y, z['bottom_left']]
          vert_pos3 = [opengl_coord_x + opengl_increment_x - opengl_offset_x, opengl_coord_y - opengl_offset_y, z['top_right']]
          vert_pos4 = [opengl_coord_x + opengl_increment_x - opengl_offset_x, opengl_coord_y + opengl_increment_y - opengl_offset_y, z['bottom_right']]
          @alt_infos.each do |index_key, info|
            glBindTexture(GL_TEXTURE_2D, info.tex_name)
          end
          # glDepthMask(GL_FALSE);
          # glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
          if x_element['terrain_paths_and_weights']
            # glBegin(GL_QUAD_STRIP)
              # index_key, info = @alt_infos.first
              @alt_infos.each do |index_key, info|
              # index_key, info = @alt_infos.first
                # # glBindTexture(GL_TEXTURE_2D, info.tex_name)
                # # index_to_s = index.to_s # Could be done in the infos field, on init
                # puts "INDEX KEYS HERE: #{index_key}"
                # puts index_key.inspect
                info_top_left_opacity     = x_element['terrain_paths_and_weights']['top_left'][index_key]     #|| 0.0
                # puts "X ELEMENT: "
                # puts x_element.inspect


                info_top_right_opacity    = x_element['terrain_paths_and_weights']['top_right'][index_key]    #|| 0.0
                info_bottom_left_opacity  = x_element['terrain_paths_and_weights']['bottom_left'][index_key]  #|| 0.0
                info_bottom_right_opacity = x_element['terrain_paths_and_weights']['bottom_right'][index_key] #|| 0.0
                # # Next unless there's at least one in there that's not nil
                next if info_top_left_opacity.nil? && info_top_right_opacity.nil? && info_bottom_left_opacity.nil? && info_bottom_right_opacity.nil?
                # # next unless [info_top_left_opacity, info_top_right_opacity, info_bottom_left_opacity, info_bottom_right_opacity].any?{ |e| !e.nil? }
                info_top_left_opacity     ||= 0.0
                info_top_right_opacity    ||= 0.0
                info_bottom_left_opacity  ||= 0.0
                info_bottom_right_opacity ||= 0.0

                # info_top_left_opacity     = 1
                # info_top_right_opacity    = 1
                # info_bottom_left_opacity  = 1
                # info_bottom_right_opacity = 1

                glBegin(GL_TRIANGLE_STRIP)
                  glTexCoord2d(info.left, info.top)
                  colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
                  glColor4d(colors[0], colors[1], colors[2], info_top_left_opacity)
                  glVertex3d(vert_pos1[0], vert_pos1[1], vert_pos1[2])

                  glTexCoord2d(info.left, info.bottom)
                  colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
                  glColor4d(colors[0], colors[1], colors[2], info_bottom_left_opacity)
                  glVertex3d(vert_pos2[0], vert_pos2[1], vert_pos2[2])

                  glTexCoord2d(info.right, info.top)
                  colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
                  glColor4d(colors[0], colors[1], colors[2], info_top_right_opacity)
                  glVertex3d(vert_pos3[0], vert_pos3[1], vert_pos3[2])

                  glTexCoord2d(info.right, info.bottom)
                  colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
                  glColor4d(colors[0], colors[1], colors[2], info_bottom_right_opacity)
                  glVertex3d(vert_pos4[0], vert_pos4[1], vert_pos4[2])
                glEnd
              end
            # glEnd
          else
            info =  @infos[x_element['terrain_index']]
            # glBindTexture(GL_TEXTURE_2D, info.tex_name)
            glBegin(GL_TRIANGLE_STRIP)
              glTexCoord2d(info.left, info.top)
              colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
              glColor4d(colors[0], colors[1], colors[2], colors[3])
              glVertex3d(vert_pos1[0], vert_pos1[1], vert_pos1[2])

              glTexCoord2d(info.left, info.bottom)
              colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
              glColor4d(colors[0], colors[1], colors[2], colors[3])
              glVertex3d(vert_pos2[0], vert_pos2[1], vert_pos2[2])

              glTexCoord2d(info.right, info.top)
              colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
              glColor4d(colors[0], colors[1], colors[2], colors[3])
              glVertex3d(vert_pos3[0], vert_pos3[1], vert_pos3[2])

              glTexCoord2d(info.right, info.bottom)
              colors = @enable_dark_mode ? apply_lighting(default_colors, vert_pos, lights) : default_colors
              glColor4d(colors[0], colors[1], colors[2], colors[3])
              glVertex3d(vert_pos4[0], vert_pos4[1], vert_pos4[2])
            glEnd
          end


          # Both these buildings and pickups drawing methods work. Building is more attached to the terrain.
          # Building draw the tile here
          # Pickups update the x and y coords, and then the pickup draws itself.
          buildings.each do |building_id, building|
            # puts "NEXTING BUILDING: #{building.current_map_tile_x} - to #{x_element['gps_x']} and maybe: #{x_element[:gps_x]}" if building.current_map_tile_x != x_element['gps_x'] || building.current_map_tile_y != x_element['gps_y']
            # puts x_element.inspect
            next if building.current_map_tile_x != x_element['gps_x'] || building.current_map_tile_y != x_element['gps_y']

            # @local_map_movement_y
            # @local_map_movement_x
            # current_map_tile_x
            # current_map_tile_y
            # y_index
            # x_index
            # @tile_pixel_width 
            # @tile_pixel_height
            # screen_pixel_width
            # screen_pixel_height
            # puts "BUILDING UPDATE INDEX: #{x_index} - #{y_index}"
            # puts "BUILDING PIXEL ESTIMATION:"
            # puts "#{x_index * @tile_pixel_width } - #{y_index * @tile_pixel_height}"

            # building.alt_draw((x_index * @tile_pixel_width) + @local_map_movement_x, (y_index * @tile_pixel_height) + @local_map_movement_y)
            # building.alt_draw((x_index * @tile_pixel_width), (y_index * @tile_pixel_height))
            # building.alt_draw((x_index * @tile_pixel_width) - @local_map_movement_x, (y_index * @tile_pixel_height) + @local_map_movement_y)

            # building.update_from_3D(vert_pos1, vert_pos2, vert_pos3, vert_pos4, x_element['height'], glGetFloatv(GL_MODELVIEW_MATRIX), glGetFloatv(GL_PROJECTION_MATRIX), glGetFloatv(GL_VIEWPORT))



            # if building.kind_of?(Landwreck) || building.kind_of?(OffensiveStore)
            #   # puts "UPDATING BUILDING ALT ALT"
            # end
              # building.alt_draw(opengl_coord_x, opengl_coord_y, opengl_increment_x, opengl_increment_y, x_element['height'])

              # building.alt_draw(opengl_coord_x, opengl_coord_y, opengl_increment_x, opengl_increment_y, x_element['height'])
            if !building.kind_of?(Buildings::Landwreck) #&& !building.kind_of?(OffensiveStore)
              # puts "BUILDING DRAW TILE HERE: #{building.class}"
              building.tile_draw_gl(vert_pos1, vert_pos2, vert_pos3, vert_pos4)
            #   # building.x_and_y_update((x_index * @tile_pixel_width) - @local_map_movement_x, (y_index * @tile_pixel_height) + @local_map_movement_y)
            else
              # puts "NOT BUILDING DRAW TILE HERE: #{building.class}"
              # building.tile_draw_gl(vert_pos1, vert_pos2, vert_pos3, vert_pos4)
              # building.update_from_3D(vert_pos1, vert_pos2, vert_pos3, vert_pos4, x_element['height'], glGetFloatv(GL_MODELVIEW_MATRIX), glGetFloatv(GL_PROJECTION_MATRIX), glGetFloatv(GL_VIEWPORT))
            end
            # building.update_from_3D(vert_pos1, vert_pos2, vert_pos3, vert_pos4, x_element['height'], glGetFloatv(GL_MODELVIEW_MATRIX), glGetFloatv(GL_PROJECTION_MATRIX), glGetFloatv(GL_VIEWPORT))
          end

          # pickups.each do |pickup|
          #   next if pickup.current_map_tile_x != x_element['gps_x'] || pickup.current_map_tile_y != x_element['gps_y']
          # end

          
          if player.current_map_tile_x == x_element['gps_x'] && player.current_map_tile_y == x_element['gps_y']
            # puts "XELEMENT of Current Player: #{x_element}"
            # XELEMENT of Current Player: {"height"=>0.23451606664978608, "terrain_index"=>0,
            #   "corner_heights"=>{"top_left"=>0.0, "top_right"=>0.0, "bottom_left"=>0.0, "bottom_right"=>0.25},
            #   "gps_y"=>122, "gps_x"=>115}
          end

          # error = glGetError
          # if error != 0
          #  puts "FOUND ERROR: #{error}"
          # end

        end
      end
    end
  end
 
  # def get2dPoint(o_x, o_y, o_z, viewMatrix, projectionMatrix, screen_pixel_width, screen_pixel_height)
  #  # puts "viewMatrix"
  #   viewMatrix.matrix_to_s
  #  # puts "projectionMatrix"
  #   projectionMatrix.matrix_to_s
  #   viewProjectionMatrix = projectionMatrix * viewMatrix;
  #   # //transform world to clipping coordinates
  #  # puts "viewProjectionMatrix"
  #  # puts viewProjectionMatrix.matrix_to_s
  #  # puts "VECTOR HERE: #{[o_x, o_y, o_z]}"
  #   point3D = viewProjectionMatrix.vector_mult([o_x, o_y, o_z, 0.999])
  #   x = ((( point3D[0] + 1 ) / 2.0) * screen_width )
  #   x = x / point3D[3]
  #   # //we calculate -point3D.getY() because the screen Y axis is
  #   # //oriented top->down 
  #   y = ((( 1 - point3D[1] ) / 2.0) * screen_height )
  #   y = y / point3D[3]
  #   # doesn't point3D[2] do anything? Depth?
  #  # puts "RETURNING: #{[x, y]}"
  #   return [x, y];
  # end

# def orldToScreen(vector = [1,2,3], )
#     {
#       Matrix4 model, proj;
#       int[] view = new int[4];

#       GL.GetFloat(GetPName.ModelviewMatrix, out model);
#       GL.GetFloat(GetPName.ProjectionMatrix, out proj);
#       GL.GetInteger(GetPName.Viewport, view);

#       double wx = 0, wy = 0, wz = 0;

#       int d = Glu.gluProject
#                       (
#                         p.X, 
#                         p.Y, 
#                         p.Z, 
#                         model, 
#                         proj, 
#                         view, 
#                         ref wx, 
#                         ref wy, 
#                         ref wz
#                       );

#       return new Point((int)wx, (int)wy);
#     }
# int gluProject
#   (
#    float objx, 
#    float objy, 
#    float objz, 
#    Matrix4 modelMatrix, 
#    Matrix4 projMatrix, 
#    int[] viewport, 
#    ref double winx, 
#    ref double winy, 
#    ref double winz
#   )
#   {
#       Vector4 _in;
#       Vector4 _out;

#       _in.X = objx;
#       _in.Y = objy;
#       _in.Z = objz;
#       _in.W = 1.0f;
#       //__gluMultMatrixVecd(modelMatrix, in, out); // Commented out by code author
#       //__gluMultMatrixVecd(projMatrix, out, in);  // Commented out by code author
#       //TODO: check if multiplication is in right order
#       _out = Vector4.Transform(_in, modelMatrix);
#       _in = Vector4.Transform(_out, projMatrix);

#       if (_in.W == 0.0)
#         return (0);
#       _in.X /= _in.W;
#       _in.Y /= _in.W;
#       _in.Z /= _in.W;
#       /* Map x, y and z to range 0-1 */
#       _in.X = _in.X * 0.5f + 0.5f;
#       _in.Y = _in.Y * 0.5f + 0.5f;
#       _in.Z = _in.Z * 0.5f + 0.5f;

#       /* Map x,y to viewport */
#       _in.X = _in.X * viewport[2] + viewport[0];
#       _in.Y = _in.Y * viewport[3] + viewport[1];

#       winx = _in.X;
#       winy = _in.Y;
#       winz = _in.Z;
#       return (1);
#   }

#   test1 = [
#     [1, 2, 0],
#     [0, 1, 1],
#     [2, 0, 1]
#   ]

#   test2 = [
#     [1, 1, 2],
#     [2, 1, 1],
#     [1, 2, 1]
#   ]
#   test3 = test1 * test2
# # class Array
# #   def * array2
# #     max_length = array1.length
# #     new_array = Array.new(max_length) { Array.new(max_length) { nil } }

# #     # for (c = 0; c < m; c++) {
# #     (0..max_length - 1) do |c|
# #       # for (d = 0; d < q; d++) {
# #       (0..max_length - 1) do |d|
# #         # for (k = 0; k < p; k++) {
# #         sum = 0
# #         (0..max_length - 1) do |k|
# #           sum += self[c][k] * array2[k][d];
# #         end
 
# #         new_array[c][d] = sum;
# #         sum = 0;
# #       end
# #     end

# #     return new_array
# #   end
# # end

  # All coords are in openGL
  # Use light attenuation
  # def apply_lighting colors_array, vertex = [], lights = [{pos: [0,0], brightness: 0.1, radius: 0.3}, {pos: [0,0], brightness: 0.3, radius: 0.1}]
  def apply_lighting colors_array, vertex = [], lights = [{pos: [0,0], brightness: 0.2, radius: 0.3}]
    # Operates in screen coords
    # Gosu.distance(@x, @y, object.x, object.y) < self.get_radius + object.get_radius
    # Wee ned to operate in opengl coords
    lights.each do |light|
      distance = Gosu.distance(vertex[0], vertex[1], light[:pos][0], light[:pos][1])

      if distance <= light[:radius]
        # Attenuation here
        new_brightness_factor = light[:brightness] - (light[:brightness] / (light[:radius] / distance))
        colors_array[0] = clamp_brightness(colors_array[0] + new_brightness_factor)
        colors_array[1] = clamp_brightness(colors_array[1] + new_brightness_factor)
        colors_array[2] = clamp_brightness(colors_array[2] + new_brightness_factor)
      end
    end
    return colors_array
  end

  def clamp_brightness(comp_value)
    return clamp(comp_value, 0, 1)
  end

  def clamp(comp_value, min, max)
    if comp_value >= min && comp_value <= max
      return comp_value
    elsif comp_value < min
      return min
    else
      return max
    end
  end

end