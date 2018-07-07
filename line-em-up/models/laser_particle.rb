require_relative 'dumb_projectile.rb'
require_relative 'laser_particle.rb'
require 'opengl'
require 'glu'
require 'glut'

class LaserParticle < DumbProjectile
  DAMAGE = 5
  COOLDOWN_DELAY = 0.001
  # Friendly projects are + speeds
  MAX_SPEED      = 15

  def get_image
    # Gosu::Image.new("#{MEDIA_DIRECTORY}/laserbolt.png")
    Gosu::Image.new("#{MEDIA_DIRECTORY}/bullet-mini.png")
  end

  def update mouse_x = nil, mouse_y = nil, player = nil
    puts "ON LAStER PARTICLE, updating: @y: #{@y} and current_speed: #{@current_speed} and time_alive: #{@time_alive}"
    @y -= @current_speed
    puts "NEW Y: #{@y}"
    @x = player.x if player
    @time_alive += 1
    @y > 0 && @y < @screen_height
  end


  include Gl
  include Glu 
  include Glut

  def draw
    # draw nothing
  end

  def draw_gl
    new_pos_x, new_pos_y, increment_x, increment_y = convert_x_and_y_to_opengl_coords

    height = 15 * increment_y * @scale

    z = ZOrder::Projectile

    # glLineWidth(5 * @scale)
    glLineWidth((10000))
    glBegin(GL_LINES)
    # 22.4% red, 100% green and 7.8% blue
      glColor3f(1, 1.0, 1.0)
      glVertex3d(new_pos_x, new_pos_y, z)
      glVertex3d(new_pos_x, new_pos_y + height, z)
    glEnd
  end

end