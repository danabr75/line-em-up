require_relative 'general_object.rb'
require 'gosu'

require 'opengl'
require 'glut'


include OpenGL
include GLUT

# Not intended to be overridden
class Hardpoint < GeneralObject
  attr_accessor :x, :y, :assigned_weapon_class, :slot_type, :radius, :angle, :center_x, :center_y
  attr_accessor :group_number, :y_offset, :x_offset, :main_weapon, :image_hardpoint, :image_hardpoint_width_half, :image_hardpoint_height_half, :image_angle


  # MISSILE_LAUNCHER_MIN_ANGLE = 75
  # MISSILE_LAUNCHER_MAX_ANGLE = 105
  # MISSILE_LAUNCHER_INIT_ANGLE = 90

  def initialize(scale, x, y, screen_width, screen_height, group_number, x_offset, y_offset, item, slot_type, options = {})
    # puts "GHARDPOINT INIT: #{y_offset}"
    @group_number = group_number
    @x_offset = x_offset# * scale
    @y_offset = y_offset# * scale
    @center_x = x
    @center_y = y
    @radius = Gosu.distance(@center_x, @center_y, x + @x_offset, y + @y_offset)
    puts "NEW RADIUS FOR HARDPOINT: #{@radius}"
    @slot_type = slot_type
    super(scale, x + @x_offset, y + @y_offset, screen_width, screen_height, options)
    @main_weapon = nil
    @drawable_items_near_self = []

    if item
      @assigned_weapon_class = item
      @image_hardpoint = item.get_hardpoint_image
    else
      @image_hardpoint = Gosu::Image.new("#{MEDIA_DIRECTORY}/hardpoint_empty.png")
    end
    @image_hardpoint_width_half = @image_hardpoint.width  / 2
    @image_hardpoint_height_half = @image_hardpoint.height  / 2
    @image_angle = options[:image_angle] || 0# 180
    start_point = OpenStruct.new(:x => x,        :y => y)
    end_point   = OpenStruct.new(:x => x_offset, :y => y_offset)
    @angle = calc_angle(start_point, end_point)
    @radian = calc_radian(start_point, end_point)
  end


  # Needs more precision, we're losing angle.
  def increment_angle
    if @angle >= 360.0
      @angle = 1
    else
      @angle += 1
    end
  end

  def decrement_angle
    if @angle <= 0.0
      @angle = 359
    else
      @angle -= 1
    end
  end


  def stop_attack
    # puts "HARDPOINT STOP ATTACK"
    @main_weapon.deactivate if @main_weapon

  end

  def attack pointer, opts = {}
    # puts "HARDPOINT ATTACK"
    attack_projectile = nil
    if @main_weapon.nil?
      # options = {damage_increase: @damage_increase, relative_y_padding: @image_height_half}
      options = {}
      options[:damage_increase] = opts[:damage_increase] if opts[:damage_increase]
      options[:image_angle] = @image_angle
      if @assigned_weapon_class
        @main_weapon = @assigned_weapon_class.new(@scale, @screen_width, @screen_height, self, options)
        @drawable_items_near_self << @main_weapon
        attack_projectile = @main_weapon.attack(pointer)
      end
    else
      @main_weapon.active = true if @main_weapon.active == false
      @drawable_items_near_self << @main_weapon
      attack_projectile = @main_weapon.attack(pointer)
    end
    if attack_projectile
      return {
        projectiles: [attack_projectile],
        cooldown: @assigned_weapon_class::COOLDOWN_DELAY
      }
    else
      return nil
    end
  end

  def get_x
    @x
  end

  def get_y
    @y
  end

  def get_draw_ordering
    ZOrder::Hardpoint
  end

  def draw
    # puts "DRAWING HARDPOINT: #{@x} and #{@y}"
    @drawable_items_near_self.reject! { |item| item.draw }

    # if @image_angle != nil
    angle = @angle# + @image_angle
      @image_hardpoint.draw_rot(@x, @y, get_draw_ordering, angle, 0.5, 0.5, @scale, @scale)
    # else
    #   @image_hardpoint.draw(@x - @image_hardpoint_width_half, @y - @image_hardpoint_height_half, get_draw_ordering, @scale, @scale)
    # end

  end

  def draw_gl
    @drawable_items_near_self.reject! { |item| item.draw_gl }
  end


  def update mouse_x = nil, mouse_y = nil, player = nil, scroll_factor = 1
    @center_y = player.y
    @center_x = player.x
    # Update these after angle is working (for when player is on edge of the map.)
    # @x = player.x + @x_offset# * @scale
    # @y = player.y + @y_offset# * @scale

    # Update list of weapons for special cases like beans. Could iterate though an association in the future.
    @main_weapon.update(mouse_x, mouse_y, self, scroll_factor) if @main_weapon
    # @cooldown_wait -= 1              if @cooldown_wait > 0
    # @secondary_cooldown_wait -= 1    if @secondary_cooldown_wait > 0
    # @grapple_hook_cooldown_wait -= 1 if @grapple_hook_cooldown_wait > 0
    # @time_alive += 1 if self.is_alive
  end

end