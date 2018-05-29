require_relative 'general_object.rb'

class Pickup < GeneralObject
  POINT_VALUE_BASE = 0
  attr_reader :x, :y

  def initialize(scale, screen_width, screen_height, x = nil, y = nil, options = {})
    super(scale, x, y, screen_width, screen_height, options = {})
    @current_speed = SCROLLING_SPEED * @scale
  end

  def get_draw_ordering
    ZOrder::Pickups
  end

  # Most classes will want to just override this
  def draw
    @image.draw_rot(@x, @y, ZOrder::Pickups, @y, 0.5, 0.5, 1, 1)
  end


  def update mouse_x = nil, mouse_y = nil, player = nil
    @y += @current_speed

    super(mouse_x, mouse_y)
  end

  def collected_by_player player
    raise "Override me!"
  end

end