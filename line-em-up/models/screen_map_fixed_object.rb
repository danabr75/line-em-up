# A 2D object, can move around the map.
# Uses current_map_pixel_x and current_map_pixel_y for tracking.
# Only uses X and Y for pixel placement, not for location tracking. X and Y depend on where they are in relation to the player.
# Used by projectiles, enemies, tumbleweeds, player, etc.
class ScreenMapFixedObject < GeneralObject
 # def initialize(current_map_pixel_x, current_map_pixel_y, screen_pixel_width, screen_pixel_height, width_scale, height_scale, map_pixel_width, map_pixel_height, options = {})
 # Use tile tracking so we know when to load them into the visible map
 def initialize(screen_pixel_width, screen_pixel_height, width_scale, height_scale, current_map_pixel_x, current_map_pixel_y, current_map_tile_x, current_map_tile_y, map_pixel_width, map_pixel_height, options = {})
    # validate_array([], self.class.name, __callee__)
    # validate_string([], self.class.name, __callee__)
    # validate_float([], self.class.name, __callee__)
    # validate_int([], self.class.name, __callee__)
    # validate_not_nil([], self.class.name, __callee__)

    validate_int([screen_pixel_width, screen_pixel_height, current_map_pixel_x, current_map_pixel_y, current_map_tile_x, current_map_tile_y, map_pixel_width, map_pixel_height], self.class.name, __callee__)
    validate_float([width_scale, height_scale], self.class.name, __callee__)
    validate_not_nil([screen_pixel_width, screen_pixel_height, width_scale, height_scale, current_map_tile_x, current_map_tile_y, map_pixel_width, map_pixel_height], self.class.name, __callee__)

    super(width_scale, height_scale, screen_pixel_width, screen_pixel_height, options)
    @map_pixel_width   = map_pixel_width
    @map_pixel_height  = map_pixel_height
    # Only use ID in debug\test
    @current_map_pixel_x = current_map_pixel_x
    @current_map_pixel_y = current_map_pixel_y
    @current_map_tile_x  = current_map_tile_x
    @current_map_tile_y  = current_map_tile_y


    if @current_map_pixel_x.nil? || @current_map_pixel_y.nil?
      if options[:tile_width] && options[:tile_height]
        @current_map_pixel_x = ((@current_map_tile_x * options[:tile_width])  + options[:tile_width]  / 2).to_i
        @current_map_pixel_y = ((@current_map_tile_y * options[:tile_height]) + options[:tile_height] / 2).to_i
      else
        raise "missing information"
      end
    end
    # For objects that don't take damage, they'll never get hit by anything due to having 0 health
    @health = 0
  end
end