require_relative 'animation.rb'

module Graphics
  class Explosion < Graphics::Animation
    def self.get_frames
      return Gosu::Image.load_tiles("#{MEDIA_DIRECTORY}/explosion.png", FRAME_WIDTH, FRAME_HEIGHT)
    end
  end
end