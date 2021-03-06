# A 3D object. Currently Can't move around the map.
# Used location_x, location_y to occupy that tile on the background map
# Only uses X and Y for pixel placement. X and Y depend on where they are in relation to the player.
# Doesn't use X and Y for pixel placement, the background object will insert them.
# Used by buildings, pickups
require_relative "general_object.rb"

class BackgroundFixedObject < GeneralObject


  # def x_and_y_update x, y
  #   @x = x
  #   @y = y
  # end

  def initialize(current_map_tile_x, current_map_tile_y, options = {})
    # validate_array([], self.class.name, __callee__)
    # validate_string([], self.class.name, __callee__)
    # validate_float([], self.class.name, __callee__)
    # validate_int([], self.class.name, __callee__)
    # validate_not_nil([], self.class.name, __callee__)

    # validate_int([screen_pixel_width, screen_pixel_height, current_map_tile_x, current_map_tile_y], self.class.name, __callee__)
    # validate_float([width_scale, height_scale], self.class.name, __callee__)
    # validate_not_nil([width_scale, height_scale, screen_pixel_width, screen_pixel_height, current_map_tile_x, current_map_tile_y], self.class.name, __callee__)

    super(options)

    @current_map_tile_x  = current_map_tile_x
    @current_map_tile_y  = current_map_tile_y


    if options[:current_map_pixel_x] && options[:current_map_pixel_y]
      @current_map_pixel_x = options[:current_map_pixel_x]
      @current_map_pixel_y = options[:current_map_pixel_y]

      # @x_offset, @y_offset = get_tile_pixel_remainder
      # puts "PIXEL: #{[@current_map_pixel_x, @current_map_pixel_y]}"
      # puts "GPS: #{[@current_map_tile_x, @current_map_tile_y]}"
      # puts "TILE PIXEL: #{[@tile_pixel_width, @tile_pixel_height]}"

      # raise "GOT THESE AS OFFSET: #{[@x_offset, @y_offset]}"

    else
      get_map_pixel_location_from_map_tile_location
    end

    # if options[:relative_y_padding]
      # puts "options[:relative_y_padding]: #{options[:relative_y_padding]}"
    # end

    # For objects that don't take damage, they'll never get hit by anything due to having 0 health
    @health = self.class.get_initial_health

    # @x_offset_base = relative_object_offset_x || 0
    # @y_offset_base = relative_object_offset_y || 0
  end

  def update mouse_x, mouse_y, player_map_pixel_x, player_map_pixel_y, options = {}
    # @time_alive += 1
    # Might not be necessary for buildings....
    convert_map_pixel_location_to_screen(player_map_pixel_x, player_map_pixel_y)
    options[:block_tile_from_pixel_update] = true
    result = super(mouse_x, mouse_y, player_map_pixel_x, player_map_pixel_y, options)
    # no need to update tile or pixel location
    # super(mouse_x, mouse_y, player_map_pixel_x, player_map_pixel_y)
    return options[:persist_even_if_not_alive] ? true : result
  end
end