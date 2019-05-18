require 'gosu'
# # require 'opengl'
# # require 'glu'

# require 'opengl'
# require 'glut'

require 'opengl'
require 'glut'

include OpenGL
include GLUT
# For opengl-bindings
# OpenGL.load_lib()
# GLUT.load_lib()


class GLBackground
  # Height map size
  MAP_HEIGHT_EDGE = 700
  MAP_WIDTH_EDGE_RIGHT = 450
  MAP_WIDTH_EDGE_LEFT  = 80
  EXTERIOR_MAP_HEIGHT = 1000
  EXTERIOR_MAP_WIDTH  = 1000
  POINTS_X = 7
  VISIBLE_MAP_WIDTH = 15
  POINTS_Y = 7
  VISIBLE_MAP_HEIGHT = 15
  # Scrolling speed - higher it is, the slower the map moves
  SCROLLS_PER_STEP = 50
  # TEMP USING THIS, CANNOT FIND SCROLLING SPEED
  SCROLLING_SPEED = 4

  attr_accessor :player_position_x, :player_position_y, :map_width, :map_height

  def initialize player_x, player_y
    # @image = Gosu::Image.new("#{MEDIA_DIRECTORY}/earth.png", :tileable => true)
    @scrolls = 0.0
    @visible_map = Array.new(VISIBLE_MAP_HEIGHT) { Array.new(VISIBLE_MAP_WIDTH) { nil } }
    @local_map_movement_x = 0
    @local_map_movement_y = 0

    # @map_height = EXTERIOR_MAP_HEIGHT
    # @map_width  = EXTERIOR_MAP_WIDTH
    @player_position_x = EXTERIOR_MAP_HEIGHT / 2.0
    @player_position_y = EXTERIOR_MAP_WIDTH  / 2.0
    @current_map_center_y = EXTERIOR_MAP_HEIGHT / 2.0
    @current_map_center_x = EXTERIOR_MAP_WIDTH  / 2.0
    @map = JSON.parse(File.readlines("/Users/bendana/projects/line-em-up/line-em-up/maps/desert.txt").first)
    @terrains = @map["terrains"]
    @images = []
    @infos = []
    @image = Gosu::Image.new("/Users/bendana/projects/line-em-up/line-em-up/media/earth.png", :tileable => true)
    @info = @image.gl_tex_info
    @terrains.each do |terrain_path|
      image = Gosu::Image.new(terrain_path, :tileable => true)
      @images << image
      @infos  << image.gl_tex_info
    end
    @map_width = @map["map_width"]
    @map_height = @map["map_height"]
    @map_data = @map["data"]
    # puts "@map_data : #{@map_data[0][0]}" 
    # @visible_map = []
    (0..VISIBLE_MAP_HEIGHT - 1).each_with_index do |visible_height, index_h|
      (0..VISIBLE_MAP_WIDTH - 1).each_with_index do |visible_width, index_w|
        y_offset = visible_height - VISIBLE_MAP_HEIGHT / 2
        x_offset = visible_width  - VISIBLE_MAP_WIDTH  / 2
        @visible_map[index_h][index_w] = @map_data[player_y + y_offset][player_x + x_offset]
        # puts "MAP GOT: #{@visible_map[index_h][index_w]}" if index_w == 0 && index_h == 0
      end
    end
    # puts @visible_map
  end

  def update player_x, player_y
    # (0..VISIBLE_MAP_HEIGHT - 1).each_with_index do |visible_height, index_h|
    #   (0..VISIBLE_MAP_WIDTH - 1).each_with_index do |visible_width, index_w|
    #     y_offset = visible_height - VISIBLE_MAP_HEIGHT / 2
    #     x_offset = visible_width  - VISIBLE_MAP_WIDTH  / 2
    #     @visible_map[index_h][index_w] = @map_data[player_y + y_offset][player_x + x_offset]
    #   end
    # end


    @local_map_movement_y = player_y - @current_map_center_y
    # Adding to bottom of map
    # SCROLLS_PER_STEP !!!!! Need to factor in scale factor here!
    if @local_map_movement_y <= SCROLLS_PER_STEP
      @visible_map.shift
      @visible_map.push Array.new(VISIBLE_MAP_WIDTH) { {'height' => rand, 'terrain_index' => rand(2) } }
      @current_map_center_y = player_y
      @local_map_movement_y = 0
    end

    # Adding to top of map 
    if @local_map_movement_y >= -SCROLLS_PER_STEP
      @visible_map.pop
      @visible_map.unshift(Array.new(VISIBLE_MAP_HEIGHT) { {'height' => rand, 'terrain_index' => rand(2) } })
      @current_map_center_y = player_y
      @local_map_movement_y = 0
    end

  end

  # def scroll factor = 1, movement_x, movement_y
  #   @scrolls += 1.0 * factor
  #   if @scrolls >= SCROLLS_PER_STEP
  #     @scrolls = 0
  #     @visible_map.shift
  #     @visible_map.push Array.new(POINTS_X) { rand }
  #   end
  # end

  # movement x and y reset for the map
  # player x and y does not.
  # UPDATE SCROLL FROM DATA MAP
  # def scroll factor = 1, player_x, player_y

  #   # @current_map_center_y
  #   # @current_map_center_x
  #   @local_map_movement_y = player_y - @current_map_center_y
  #   # Adding to bottom of map
  #   if @local_map_movement_y <= SCROLLS_PER_STEP
  #     @visible_map.shift
  #     @visible_map.push Array.new(VISIBLE_MAP_WIDTH) { {'height' rand, :'terrain_index' => rand(2) } }
  #     @current_map_center_y = player_y
  #     @local_map_movement_y = 0
  #   end

  #   # Adding to top of map 
  #   if @local_map_movement_y >= -SCROLLS_PER_STEP
  #     @visible_map.pop
  #     @visible_map.unshift(Array.new(VISIBLE_MAP_HEIGHT) { {'height' rand, :'terrain_index' => rand(2) } })
  #     @current_map_center_y = player_y
  #     @local_map_movement_y = 0
  #   end

  #   # if movement_x >= SCROLLS_PER_STEP
  #   #   # @visible_map.shift
  #   #   # @visible_map.push Array.new(POINTS_X) { rand }
  #   #   @visible_map.each do |row|
  #   #     row.shift
  #   #     row.push({'height' x_value, :'terrain_index' => rand(2) })
  #   #   end
  #   #   movement_x = 0
  #   # end
  #   # if movement_x <= -SCROLLS_PER_STEP
  #   #   @visible_map.each do |row|
  #   #     row.pop
  #   #     row.unshift({'height' x_value, :'terrain_index' => rand(2) })
  #   #   end
  #   #   movement_x = 0
  #   # end

  #   # @local_map_movement_y = movement_y
  #   # @local_map_movement_x = movement_x

  #   return nil
  # end

  
  # Not needed
  def draw(z)
    # # gl will execute the given block in a clean OpenGL environment, then reset
    # # everything so Gosu's rendering can take place again.
    # Gosu.gl(z) do
    #   glClearColor(0.0, 0.2, 0.5, 1.0)
    #   glClearDepth(0)
    #   glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    #   exec_gl
    # end
  end
  
  # include Gl
  
  def exec_gl player_x, player_y
    player_x, player_y = [player_x.to_i, player_y.to_i]

    
    glDepthFunc(GL_GEQUAL)
    glEnable(GL_DEPTH_TEST)
    # glEnable(GL_BLEND)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    glFrustum(-0.10, 0.10, -0.075, 0.075, 1, 100)
    # gluPerspective(45.0, 800 / 600 , 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity
    glTranslated(0, 0, -4)

    opengl_increment_y = 1 / VISIBLE_MAP_HEIGHT.to_f
    opengl_increment_x = 1 / VISIBLE_MAP_WIDTH.to_f

#     # TEST

# # VERT ONE: -0.25 X -0.1
# # VERT TWO: -0.25 X 0.1
# # VERT THREE: -0.083 X -0.1
# # VERT FOUR: -0.083 X 0.1
# glEnable(GL_TEXTURE_2D)
# glBindTexture(GL_TEXTURE_2D, @info.tex_name)
# glBegin(GL_TRIANGLE_STRIP)
#     glTexCoord2d(@info.left, @info.top)
#     # puts "VERT ONE: #{opengl_x} X #{opengl_y}"
#     glVertex3d(-0.25, -0.1, 0.5)
#     glTexCoord2d(@info.left, @info.bottom)
#     glVertex3d(-0.25, 0.1, 0.5)
#     glTexCoord2d(@info.right, @info.top)
#     glVertex3d(-0.083, -0.1, 0.5)
#     glTexCoord2d(@info.right, @info.bottom)
#     glVertex3d(-0.083, 0.1, 0.5)
# glEnd

#     # END TEST

    glEnable(GL_TEXTURE_2D)
    y_length = @visible_map.length
    @visible_map.each_with_index do |y_row, y_index|
      x_length = y_row.length
      y_row.each_with_index do |x_element, x_index|
        y_offset = 0
        if y_index == 0 
          y_offset = (1 / VISIBLE_MAP_HEIGHT / 2) 
        elsif (y_index - VISIBLE_MAP_HEIGHT / 2) == 0
          y_offset = 0
        else
          y_offset = (1 / (y_index - VISIBLE_MAP_HEIGHT / 2))
        end
        x_offset = 0
        if x_index == 0 
          x_offset = (1 / VISIBLE_MAP_HEIGHT / 2) 
        elsif (x_index - VISIBLE_MAP_HEIGHT / 2) == 0
          x_offset = 0
        else
          x_offset = (1 / (x_index - VISIBLE_MAP_HEIGHT / 2))
        end
        # x_offset = x_index == 0 ? (1 / VISIBLE_MAP_WIDTH  / 2) : (1 / (x_index - VISIBLE_MAP_WIDTH  / 2))
        puts "x_element: #{x_element}"
        opengl_x = (1 / (x_index + 1.0 + x_offset) )
        opengl_y = (1 / (y_index + 1.0 + y_offset) )


        z = x_element['height']
        #testing
        # info =  @infos[x_element['terrain_index']]
        info = @info

        glBindTexture(GL_TEXTURE_2D, info.tex_name)
        # -.5 ... +.5
        puts "Z: #{z}"
        glBegin(GL_TRIANGLE_STRIP)
          # Apply scale factor here?
          glTexCoord2d(info.left, info.top)
          puts "V2 VERT ONE: #{opengl_x} X #{opengl_y}"
          glVertex3d(opengl_x, opengl_y, z)
          glTexCoord2d(info.left, info.bottom)
          puts "V2 VERT TWO: #{opengl_x} X #{opengl_y} + #{opengl_increment_y}"
          glVertex3d(opengl_x, opengl_y + opengl_increment_y, z)
          glTexCoord2d(info.right, info.top)
          puts "V2 VERT THREE: #{opengl_x} + #{opengl_increment_x} X #{opengl_y}"
          glVertex3d(opengl_x + opengl_increment_x, opengl_y, z)
          glTexCoord2d(info.right, info.bottom)
          puts "V2 VERT FOUR: #{opengl_x} + #{opengl_increment_x} X #{opengl_y} + #{opengl_increment_y}"
          glVertex3d(opengl_x + opengl_increment_x, opengl_y + opengl_increment_y, z)
        glEnd
      end
    end
    # raise "STOP HERE"


  end
end