require 'luit'

require_relative 'setting.rb'
require_relative '../models/basic_ship.rb'
require_relative '../models/launcher.rb'
# require "#{MODEL_DIRECTORY}/basic_ship.rb"
# require_relative "config_settings.rb"

class ShipLoadoutSetting < Setting
  # MEDIA_DIRECTORY
  # SELECTION = ::Launcher.descendants
  NAME = "ship_loadout"

  # def self.get_weapon_options
  #   ::Launcher.descendants
  # end

  # attr_accessor :x, :y, :font, :max_width, :max_height, :selection, :value, :ship_value
  attr_accessor :value, :ship_value
  attr_accessor :mouse_x, :mouse_y
  attr_reader :active
  attr_accessor :refresh_player_ship
  def initialize window, max_width, max_height, current_height, config_file_path, width_scale, height_scale, options = {}
    @width_scale  = width_scale
    @height_scale = height_scale
    @refresh_player_ship = false
    LUIT.config({window: window || self, z: 25})
    # @window = window # Want relative to self, not window. Can't do that from settting, not a window.
    @mouse_x, @mouse_y = [0,0]
    @window = window # ignoring outer window here? Want actions relative to this window.
    @scale = options[:scale] || 1
    # puts "SHIP LOADOUT SETTING SCALE: #{@scale}"
    @font = Gosu::Font.new(20)
    # @x = width
    @y = current_height
    @max_width = max_width
    @max_height = max_height
    @next_x = 5 * @scale
    @prev_x = @max_width - 5 * @scale - @font.text_width('>')
    @selection = []
    # @launchers = ::Launcher.descendants.collect{|d| d.name}
    @meta_launchers = {}
    @filler_items = []
    # @launchers.each_with_index do |klass_name, index|
    #   klass = eval(klass_name)
    #   image = klass.get_hardpoint_image
    #   button_key = "clicked_launcher_#{index}".to_sym
    #   @meta_launchers[button_key] = {follow_cursor: false, klass: klass, image: image}
    #   @filler_items << {follow_cursor: false, klass: klass, image: image}
    #   @button_id_mapping[button_key] = lambda { |setting, id| setting.click_inventory(id) }
    # end
    @hardpoint_image_z = 50
    # puts "SELECTION: #{@selection}"
    # puts "INNITING #{config_file_path}"
    @config_file_path = config_file_path
    @name = self.class::NAME
    # @ship_value = ship_value
    # implement hide_hardpoints on pilotable ship class

    # Used to come from loadout window
    @ship_value = ConfigSetting.get_setting(@config_file_path, "ship", @selection[0])
    klass = eval(@ship_value)

    @ship = klass.new(@max_width / 2, @max_height / 2, 0, {use_large_image: true, hide_hardpoints: true, block_initial_angle: true})

    puts "SHIP HERE: #{@ship.x} - #{@ship.y}"

    # puts "RIGHT HERE!@!!!"
    # puts "@ship.right_broadside_hard_points"
    # puts @ship.right_broadside_hard_points
    @value = ConfigSetting.get_setting(@config_file_path, @name, @selection[0])
    # @window = window
    # first array is rows at the top, 2nd goes down through the rows
    @inventory_matrix = []
    @inventory_matrix_max_width = 4
    @inventory_matrix_max_height = 7
    @cell_width  = 25 * @width_scale
    @cell_height = 25 * @height_scale
    @cell_width_padding = 5 * @width_scale
    @cell_height_padding = 5 * @height_scale
    @button_id_mapping = self.class.get_id_button_mapping
    init_matrix
    # puts "FILLER ITEMS: #{@filler_items}"
    # @inventory_items = retrieve_inventory_items
    # fill_matrix(@filler_items)
    @cursor_object = nil
    @ship_hardpoints = init_hardpoints(@ship)
    @active = false
    # @button = LUIT::Button.new(@window, :test, 450, 450, "test", 30, 30)
    @button = LUIT::Button.new(@window, :back, max_width / 2, max_height - 50, "Return to Game", 30, 30)
  end

  def enable
    @active = true
  end
  def disable
    @active = false
  end

  # def retrieve_inventory_items
  # end

  def self.get_id_button_mapping
    values = {
      next:     lambda { |window, menu, id| menu.next_clicked },
      previous: lambda { |window, menu, id| menu.previous_clicked },
      back:     lambda { |window, menu, id| window.cursor_object.nil? ? (menu.refresh_player_ship = true;  menu.disable;) : nil }
    }
  end

  # Use to fill when dropped on screen somewhere..
  # Currently not used
  def fill_matrix elements
    elements.each do |element|
      space = find_next_matrix_space
      if space
        # puts "ASSIGNING ELEMENT:"
        # puts element.inspect
        @inventory_matrix[space[:x]][space[:y]][:item] = element.merge({key: space[:key]})
      else
        puts "NO SPACE LEFT"
      end
    end
  end

  def find_next_matrix_space
    found_space = nil
    (0..@inventory_matrix_max_height - 1).each do |y|
      (0..@inventory_matrix_max_width - 1).each do |x|
        if @inventory_matrix[x][y][:item].nil?
          key = "matrix_#{x}_#{y}"            
          found_space = {x: x, y: y, key: key}
        end
        break if found_space
      end
      break if found_space
    end
    return found_space
  end

  def init_matrix
    (0..@inventory_matrix_max_width - 1).each do |i|
      @inventory_matrix[i] = Array.new(@inventory_matrix_max_height)
    end
    current_y = @y + @cell_height_padding
    current_x = @next_x
    (0..@inventory_matrix_max_height - 1).each do |y|
      (0..@inventory_matrix_max_width - 1).each do |x|
        key = "matrix_#{x}_#{y}"
        click_area = LUIT::ClickArea.new(@window, key, current_x, current_y, @cell_width, @cell_height)
        klass_name = ConfigSetting.get_mapped_setting(@config_file_path, ['Inventory', x.to_s, y.to_s])
        item = nil
        if klass_name
          klass = eval(klass_name)
          image = klass.get_hardpoint_image
          item = {key: key, klass: klass, image: image}
        end
        # @filler_items << {follow_cursor: false, klass: klass, image: image}
        @inventory_matrix[x][y] = {x: current_x, y: current_y, click_area: click_area, key: key, item: item}
        current_x = current_x + @cell_width + @cell_width_padding
        @button_id_mapping[key] = lambda { |window, menu, id| menu.click_inventory(id) }
      end
      current_x = @next_x
      current_y = current_y + @cell_height + @cell_height_padding
    end
  end

  def matrix_draw
    (0..@inventory_matrix_max_height - 1).each do |y|
      (0..@inventory_matrix_max_width - 1).each do |x|
        element = @inventory_matrix[x][y]
        element[:click_area].draw(0,0)
        # puts "element[:item]: #{element[:item]}"
        if !element[:item].nil? && element[:item][:follow_cursor] != true
          image = element[:item][:image]
          image.draw(element[:x] - (image.width / 2) + @cell_width / 2, element[:y] - (image.height / 2) + @cell_height / 2, @hardpoint_image_z, @width_scale, @height_scale)
        end
      end
    end
  end

  def hardpoint_draw
    @ship_hardpoints.each do |key, list|
      if list.any?
        list.each do |value|
          click_area = value[:click_area]
          if click_area
            click_area.draw(0, 0)
          else
            # puts " NO CLICK AREA FOUND"
          end
          item = value[:item]
          if item
            image = item[:image]
            if image
              # puts "TEST: #{[@hardpoint_image_z, @width_scale, @height_scale]}"
              image.draw(
                value[:x] - (image.width  / 2)  + @cell_width  / 2,
                value[:y] - (image.height / 2)  + @cell_height / 2,
                @hardpoint_image_z,
                @width_scale, @height_scale
              )
            end
          end
        end
      else
        # puts " KEY DID NOT HAVE Value"
      end
    end
  end

  def matrix_update
    (0..@inventory_matrix_max_height - 1).each do |y|
      (0..@inventory_matrix_max_width - 1).each do |x|
        @inventory_matrix[x][y][:click_area].update(0,0)
      end
    end
  end

  def print_out_matrix
    (0..@inventory_matrix_max_height - 1).each do |y|
      row_value = []
      (0..@inventory_matrix_max_width - 1).each do |x|
        value = @inventory_matrix[x][y]
        if value.nil?
          value = 'O'
        else
          value = 'X'
        end
        row_value << value
      end
      puts row_value.join(', ')
    end
  end

# front-SHIP LOADOUT: 412 => 474 + -38.671875 - (46.875/ 2) ; 111.56828170050284 => 291.09953170050284 + -156.09375 - 46.875 / 2
# front-SHIP LOADOUT: 412 => 397 + 38.671875 - (46.875/ 2) ; 118.40304726635867 => 297.93429726635867 + -156.09375 - 46.875 / 2

  def init_hardpoints ship
    # Populate ship hardpoints from save file here.
    # will be populated from the ship, don't need to here.
    value = {}
    groups = [
      {hardpoints: ship.right_broadside_hard_points, location: :right},
      {hardpoints: ship.left_broadside_hard_points,  location: :left},
      {hardpoints: ship.front_hard_points,           location: :front}
    ]
    groups.each do |group|
      value[group[:location]] = []
      group[:hardpoints].each_with_index do |hp, index|
        button_key = "#{group[:location].to_s}_hardpoint_#{index}"
        # click_area = LUIT::ClickArea.new(@window, key, current_x, current_y, @cell_width, @cell_height)
# image.draw(value[:x] - (image.width / 2) + @cell_width / 2, value[:y] - (image.height / 2)  + @cell_height / 2, @hardpoint_image_z)
        # if group[:location] == :front
        #   puts "FRONT HERE!!!!!"
        #   puts "HP X and Y: #{hp.x} and #{hp.y}"
        #   puts "hp.x_offset and hp.y_offset: #{hp.x_offset} and #{hp.y_offset}"
        # end
        # puts "#{group[:location]}-SHIP LOADOUT: #{hp.x + hp.x_offset - (@cell_width / 2)} => #{hp.x} + #{hp.x_offset} - (#{@cell_width }/ 2) ; #{hp.y + hp.y_offset - @cell_height / 2} => #{hp.y} + #{hp.y_offset} - #{@cell_height} / 2"
        # click_area = LUIT::ClickArea.new(@window, button_key, hp.x + hp.x_offset - (@cell_width / 2), hp.y + hp.y_offset - @cell_height / 2, @cell_width, @cell_height)
        # OFFSET is already built into the HP X and Y, taking it out

        # CLICK AREA: [474.7267846530563, 291.09953170050284] - group: front
        # CLICK AREA: [397.6856161538535, 297.93429726635867] - group: front

        puts "CLICK AREA: #{[hp.x, hp.y]} - group: #{group[:location]}"
        click_area = LUIT::ClickArea.new(@window, button_key, hp.x, hp.y, @cell_width, @cell_height)
        @button_id_mapping[button_key] = lambda { |window, menu, id| menu.click_ship_hardpoint(id) }
        if hp.assigned_weapon_class
          image = hp.assigned_weapon_class.get_hardpoint_image
          item = {
            image: image, key: button_key, 
            klass: hp.assigned_weapon_class
          }

        else
        end
        value[group[:location]] << {item: item, x: hp.x, y: hp.y, click_area: click_area, key: button_key}
      end
    end
    # puts "VALUES HERE FRONT:"
    # puts value[:front]
    # puts "VALUES HERE RIGHT:"
    # puts value[:right].count
    # puts "VALUES HERE LEFT:"
    # puts value[:left].count

    # ship.left_broadside_hard_points.each do |hp|
    #   value[:left] << {weapon_klass: hp.assigned_weapon_class, x: hp.x + hp.x_offset, y: hp.y + hp.y_offset}
    # end

    # ship.front_hard_points.each do |hp|
    #   value[:front] << {weapon_klass: hp.assigned_weapon_class, x: hp.x + hp.x_offset, y: hp.y + hp.y_offset}
    # end
    return value
  end

  def click_ship_hardpoint id
    puts "click_ship_hardpoint: #{id}"
    # Key is front, right, or left
    # left_hardpoint_0


    port, i = id.scan(/(\w+)_hardpoint_(\d+)/).first
    port, i = [port.to_sym, i.to_i]
    puts "PORT AND I: #{port} and #{i}"

    hardpoint_element = @ship_hardpoints[port][i]
    element = hardpoint_element ? hardpoint_element[:item] : nil

    if @cursor_object && element
      puts "@cursor_object[:key]: #{@cursor_object[:key]}"
      puts "ID: #{id}"
      puts "== #{@cursor_object[:key] == id}"
      if @cursor_object[:key] == id
        # Same Object, Unstick it, put it back
        # element[:follow_cursor] = false
        # @inventory_matrix[x][y][:item][:follow_cursor] =
        hardpoint_element[:item] = @cursor_object
        puts "CONFIG SETTING 1"
        ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "#{port}_hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
        hardpoint_element[:item][:key] = id
        @cursor_object = nil
      else
        # Else, drop object, pick up new object
        # @cursor_object[:follow_cursor] = false
        # element[:follow_cursor] = true
        temp_element = element
        hardpoint_element[:item] = @cursor_object
        hardpoint_element[:item][:key] = id
        puts "CONFIG SETTING 2 "
        ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "#{port}_hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
        @cursor_object = temp_element
        @cursor_object[:key] = nil # Original home lost, no last home of key present
        # @cursor_object[:follow_cursor] = true
        # WRRROOOONNGGG!
        # element = 
      end
    elsif element
      # Pick up element, no current object
      # element[:follow_cursor] = true
      @cursor_object = element
      hardpoint_element[:item] = nil
        puts "CONFIG SETTING 3 "
        # Not working.. 
      puts [@ship.class.name, "#{port}_hardpoint_locations", i.to_s].to_s
      ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "#{port}_hardpoint_locations", i.to_s], nil)
    elsif @cursor_object
      # Placeing something new in inventory
      hardpoint_element[:item] = @cursor_object
      puts "PUTTING ELEMENT IN: #{hardpoint_element[:item]}"
        puts "CONFIG SETTING 4 "
      puts [@ship.class.name, "#{port}_hardpoint_locations", i.to_s].to_s
      puts hardpoint_element[:item][:klass]
      ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "#{port}_hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
      hardpoint_element[:item][:key] = id
      # matrix_element[:item][:follow_cursor] = false
      @cursor_object = nil
    end
  end

  def click_inventory id
    puts "LUANCHER: #{id}"
    puts "click_inventory: "
    x, y = id.scan(/matrix_(\d+)_(\d+)/).first
    x, y = [x.to_i, y.to_i]
    puts "LCICKED: #{x} and #{y}"
    matrix_element = @inventory_matrix[x][y]
    element = matrix_element ? matrix_element[:item] : nil

    # Resave new key when dropping element in.

    if @cursor_object && element
      puts "@cursor_object[:key]: #{@cursor_object[:key]}"
      puts "ID: #{id}"
      puts "== #{@cursor_object[:key] == id}"
      if @cursor_object[:key] == id
        # Same Object, Unstick it, put it back
        # element[:follow_cursor] = false
        # @inventory_matrix[x][y][:item][:follow_cursor] =
        matrix_element[:item] = @cursor_object
        ConfigSetting.set_mapped_setting(@config_file_path, ['Inventory', x.to_s, y.to_s], matrix_element[:item][:klass])
        matrix_element[:item][:key] = id
        @cursor_object = nil
      else
        # Else, drop object, pick up new object
        # @cursor_object[:follow_cursor] = false
        # element[:follow_cursor] = true
        temp_element = element
        matrix_element[:item] = @cursor_object
        matrix_element[:item][:key] = id
        ConfigSetting.set_mapped_setting(@config_file_path, ['Inventory', x.to_s, y.to_s], matrix_element[:item][:klass])
        @cursor_object = temp_element
        @cursor_object[:key] = nil # Original home lost, no last home of key present
        # @cursor_object[:follow_cursor] = true
        # WRRROOOONNGGG!
        # element = 
      end
    elsif element
      # Pick up element, no current object
      # element[:follow_cursor] = true
      @cursor_object = element
      matrix_element[:item] = nil
      ConfigSetting.set_mapped_setting(@config_file_path, ['Inventory', x.to_s, y.to_s], nil)
    elsif @cursor_object
      # Placeing something new in inventory
      matrix_element[:item] = @cursor_object
      ConfigSetting.set_mapped_setting(@config_file_path, ['Inventory', x.to_s, y.to_s], matrix_element[:item][:klass])
      matrix_element[:item][:key] = id
      # matrix_element[:item][:follow_cursor] = false
      @cursor_object = nil
    end
  end


  def get_values
    # puts "GETTING DIFFICULTY: #{@value}"
    if @value
      @value
    end
  end

  def hardpoint_update
    @ship_hardpoints.each do |key, list|
      if list.any?
        list.each do |value|
          click_area = value[:click_area]
          # puts "CLICK AREA: #{click_area.y}"
          if click_area
            click_area.update(0, 0)
          end
        end
      end
    end
  end

  def update mouse_x, mouse_y, player
    if @active
      @mouse_x, @mouse_y = [mouse_x, mouse_y]

      hardpoint_update

      matrix_update

      # @button.draw(-(@button.w / 2), -(@y_offset - @button.h / 2))
      # @button.update
      @button.update(-(@button.w / 2), -(@button.h / 2))

      # get ship value from player. used to come from update
      # if ship_value != @ship_value
      #   @ship_value = ship_value
      #   klass = eval(@ship_value)
      #   @ship = klass.new(1, @max_width / 2, @max_height / 2, @max_width, @max_height, {use_large_image: true, hide_hardpoints: true})
      #   @ship_hardpoints = init_hardpoints(@ship)
      # else
      #   # Do nothing
      # end
      return @cursor_object
    else
      return nil
    end
  end

  # Not used
  # def get_hardpoints
  #   klass = eval(@ship_value)
  #   return {
  #     front: klass::FRONT_HARDPOINT_LOCATIONS,
  #     right: klass::RIGHT_BROADSIDE_HARDPOINT_LOCATIONS,
  #     left:  klass::LEFT_BROADSIDE_HARDPOINT_LOCATIONS
  #   }
  # end

  def get_image
    klass = eval(@ship_value)
    return klass.get_right_broadside_image(klass::SHIP_MEDIA_DIRECTORY)
  end

  def get_large_image
    klass = eval(@ship_value)
    return klass.get_large_image(klass::SHIP_MEDIA_DIRECTORY)
  end

  # deprecated
  def clicked mx, my
    raise "Deperected?"
    puts "SHIP LOADOUT CLICKED"
    if is_mouse_hovering_next(mx, my)

    elsif is_mouse_hovering_prev(mx, my)

    end
  end

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

  def draw
    if @active
      if @cursor_object
        @cursor_object[:image].draw(@mouse_x, @mouse_y, @hardpoint_image_z, @width_scale, @height_scale)
      end

      hardpoint_draw

      matrix_draw

      # @button.draw(-(@button.w / 2), -(@y_offset - @button.h / 2))
      @button.draw(-(@button.w / 2), -(@button.h / 2))

      @font.draw(@value, ((@max_width / 2) - @font.text_width(@value) / 2), @y, 1, 1.0, 1.0, 0xff_ffff00)

      @ship.draw
      @font.draw(@value, ((@max_width / 2) - @font.text_width(@value) / 2), @y, 1, 1.0, 1.0, 0xff_ffff00)
      @font.draw(">", @prev_x, @y, 1, 1.0, 1.0, 0xff_ffff00)
    end
  end

end