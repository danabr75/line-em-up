require_relative 'setting.rb'
# require_relative "config_settings.rb"

class ResolutionSetting < Setting
  FULLSCREEN_NAME = "fullscreen"
  NAME = "resolution"
  SELECTION = ["480x480", "640x480", "800x600", "960x720", "1024x768", "1280x960", "1400x1050", "1440x1080", "1600x1200", "1856x1392", "1920x1440", "2048x1536", FULLSCREEN_NAME]
  # attr_accessor :x, :y, :font, :max_width, :max_height

  # def initialize fullscreen_height, max_width, max_height, height, config_file_path
  #   @font = Gosu::Font.new(20)
  #   # @x = width
  #   @y = height
  #   @max_width = max_width
  #   @max_height = max_height
  #   @next_x = 15
  #   @prev_x = @max_width - 15 - @font.text_width('>')
  #   @config_file_path = config_file_path
  #   @name = get_name
  #   @value = ConfigSetting.get_setting(@config_file_path, @name, SELECTION[0])
  #   @fullscreen = false
  #   @fullscreen_height = fullscreen_height
  # end

  def get_values
    if @value == FULLSCREEN_NAME
      height = @fullscreen_height
      width = (@fullscreen_height / 3) * 4
      [width, height, true]
    elsif @value
      @value.split('x').collect{|s| s.to_i }
    end
  end

  # def draw
  #   @font.draw("<", @next_x, @y, 1, 1.0, 1.0, 0xff_ffff00)
  #   @font.draw(@value, ((@max_width / 2) - @font.text_width(@value) / 2), @y, 1, 1.0, 1.0, 0xff_ffff00)
  #   @font.draw(">", @prev_x, @y, 1, 1.0, 1.0, 0xff_ffff00)
  # end

  # def update mouse_x, mouse_y
  # end

  # def clicked mx, my
  #   if is_mouse_hovering_next(mx, my)
  #     index = SELECTION.index(@value)
  #     value = @value
  #     if index == 0
  #       value = SELECTION[SELECTION.count - 1]
  #     else
  #       value = SELECTION[index - 1]
  #     end
  #     ConfigSetting.set_setting(@config_file_path, @name, value)
  #     @value = value
  #   elsif is_mouse_hovering_prev(mx, my)
  #     index = SELECTION.index(@value)
  #     value = @value
  #     if index == SELECTION.count - 1
  #       value = SELECTION[0]
  #     else
  #       value = SELECTION[index + 1]
  #     end
  #     ConfigSetting.set_setting(@config_file_path, @name, value)
  #     @value = value
  #   end
  # end
  # def is_mouse_hovering_next mx, my
  #   local_width  = @font.text_width('>')
  #   local_height = @font.height

  #   (mx >= @next_x and my >= @y) and (mx <= @next_x + local_width) and (my <= @y + local_height)
  # end
  # def is_mouse_hovering_prev mx, my
  #   local_width  = @font.text_width('<')
  #   local_height = @font.height

  #   (mx >= @prev_x and my >= @y) and (mx <= @prev_x + local_width) and (my <= @y + local_height)
  # end


end