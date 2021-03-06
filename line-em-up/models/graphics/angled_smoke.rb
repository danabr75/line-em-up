require 'gosu'

# require 'opengl'
# require 'glu'
require 'glut'


require_relative 'angled_particle.rb'

module Graphics

  # include OpenGL # Gl
  # include GLUT   # Glut 
  # include GLU    # Glu


  class AngledSmoke < Graphics::AngledParticle

    attr_reader :is_alive

    NUMBER_OF_PARTICLES = 1

    def self.get_image
      @image = Gosu::Image.new("#{MEDIA_DIRECTORY}/smoke.png")
    end

  end
end