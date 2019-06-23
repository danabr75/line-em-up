# require 'luit' # overridding

# require_relative '../../vendors/lib/luit'
# require "#{vendor_directory}/lib/luit.rb"


require_relative 'setting.rb'
require_relative '../models/basic_ship.rb'
require_relative '../models/launcher.rb'
require_relative '../models/ship_inventory.rb'
require_relative '../models/object_inventory.rb'

require 'gosu'
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

  # attr_accessor :cursor_object

  def initialize window, max_width, max_height, current_height, config_file_path, width_scale, height_scale, options = {}
    @width_scale  = width_scale
    @height_scale = height_scale
    @average_scale = (@width_scale + @height_scale) / 2.0

    @refresh_player_ship = false
    # @z = ZOrder::HardPointClickableLocation
    LUIT.config({window: window || self})
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
    # @next_x = 5 * @scale
    @prev_x = @max_width - 5 * @scale - @font.text_width('>')
    @selection = []

    @ship_inventory = ShipInventory.new(window)
    # @launchers = ::Launcher.descendants.collect{|d| d.name}
    # @meta_launchers = {}
    # @filler_items = []
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


    hardpoint_data = Player.get_hardpoint_data(@ship_value)
    @ship = klass.new(@max_width / 2, @max_height / 2, ZOrder::Player, ZOrder::Hardpoint, 0, "INVENTORY_WINDOW", {use_large_image: true, hide_hardpoints: true, block_initial_angle: true}.merge(hardpoint_data))

    # puts "SHIP HERE: #{@ship.x} - #{@ship.y}"

    # puts "RIGHT HERE!@!!!"
    # puts "@ship.starboard_hard_points"
    # puts @ship.starboard_hard_points
    @value = ConfigSetting.get_setting(@config_file_path, @name, @selection[0])
    # @window = window
    # first array is rows at the top, 2nd goes down through the rows
    # @inventory_matrix = []
    # @inventory_matrix_max_width = 4
    # @inventory_matrix_max_height = 7
    @cell_width  = 25 * @width_scale
    @cell_height = 25 * @height_scale
    @cell_width_padding = 5 * @width_scale
    @cell_height_padding = 5 * @height_scale
    @button_id_mapping = self.class.get_id_button_mapping

    # @inventory_height = nil
    # @inventory_width  = nil
    # init_matrix
    # puts "FILLER ITEMS: #{@filler_items}"
    # @inventory_items = retrieve_inventory_items
    # fill_matrix(@filler_items)
    # @window.cursor_object = nil
    @hardpoints_height = nil
    @hardpoints_width  = nil
    @ship_hardpoints = init_hardpoints_clickable_areas(@ship)
    @active = false
    # @button = LUIT::Button.new(@window, :test, 450, 450, "test", 30, 30)
    @button = LUIT::Button.new(@window, :back, max_width / 2, 50, ZOrder::UI, "Return to Game", 30, 30)
    @font_height  = (12 * @average_scale).to_i
    @font_padding = (4 * @average_scale).to_i
    @font = Gosu::Font.new(@font_height)
    @hover_object = nil

    @object_inventory = nil
  end

  def loading_object_inventory object, drops = []
    # puts "WHAT FUCKING DROPS DID WE GET HERE? #{drops}"
    # puts "WHAT WAS ON THE OBHECT: #{object.drops}"
    @object_inventory = ObjectInventory.new(@window, object.class.to_s, object.drops, object)
  end 

  def unloading_object_inventory
    # puts "TRYING TO UNLOAD OBJECT INVENTORY"
    if @object_inventory
      # puts 'GET HERE'
      # puts "IT HAS CURRENTLY: #{@object_inventory.attached_to.drops}"
      # # puts "WERE GIVING IT:"
      # # puts @object_inventory.get_matrix_items
      # puts "@object_inventory.attached_to.class: #{@object_inventory.attached_to.class}"
      # @object_inventory.attached_to.set_drops(@object_inventory.get_matrix_items)
      # puts "POST HERE: #{@object_inventory.attached_to.drops}"
      @object_inventory.unload_inventory
      @object_inventory = nil
    end
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
      # next:     lambda { |window, menu, id| menu.next_clicked },
      # previous: lambda { |window, menu, id| menu.previous_clicked },
      back:     lambda { |window, menu, id| window.block_all_controls = true; window.cursor_object.nil? ? (menu.unloading_object_inventory ;menu.refresh_player_ship = true;  menu.disable;) : nil }
    }
  end

  def onClick element_id
    found_button = @ship_inventory.onClick(element_id)
    found_button = @object_inventory.onClick(element_id) if !found_button && @object_inventory
    super(element_id) if !found_button
  end

  def hardpoint_draw
    @ship_hardpoints.each do |value|
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
            value[:x] - (image.width  / 2),
            value[:y] - (image.height / 2),
            # value[:x] - (image.width  / 2)  + @cell_width  / 2,
            # value[:y] - (image.height / 2)  + @cell_height / 2,
            @hardpoint_image_z,
            @width_scale, @height_scale
          )
        end
      end
    end
  end

  def init_hardpoints_clickable_areas ship
    # Populate ship hardpoints from save file here.
    # will be populated from the ship, don't need to here.

    value = []
    ship.hardpoints.each_with_index do |hp, index|
      button_key = "hardpoint_#{index}"

      color, hover_color = [nil,nil]
      if hp.slot_type    == :generic
        # color, hover_color = [Gosu::Color.argb(0x8aff82), Gosu::Color.argb(0xc3ffba)]
        color, hover_color = [Gosu::Color.argb(0xff_8aff82), Gosu::Color.argb(0xff_c3ffbf)]
      elsif hp.slot_type == :offensive
        color, hover_color = [Gosu::Color.argb(0xff_ff3232), Gosu::Color.argb(0xff_ffb5b5)]
      end
      click_area = LUIT::ClickArea.new(@window, button_key, hp.x - @cell_width  / 2, hp.y - @cell_width  / 2, ZOrder::HardPointClickableLocation, @cell_width, @cell_height, color, hover_color)
      @button_id_mapping[button_key] = lambda { |window, menu, id| menu.click_ship_hardpoint(id) }
      if hp.assigned_weapon_class
        image = hp.assigned_weapon_class.get_hardpoint_image
        item = {
          image: image, key: button_key, 
          klass: hp.assigned_weapon_class
        }

      else
        item = nil
      end

      value << {item: item, x: hp.x, y: hp.y, click_area: click_area, key: button_key, hp: hp}
    end
    # puts "VALUES HERE FRONT:"
    # puts value[:front]
    # puts "VALUES HERE RIGHT:"
    # puts value[:right].count
    # puts "VALUES HERE LEFT:"
    # puts value[:left].count

    # ship.port_hard_points.each do |hp|
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
    # current_object = @window.cursor_object || @ship_inventory.cursor_object


    result = id.scan(/hardpoint_(\d+)/).first
    raise "Could not find hardpoint ID" if result.nil?
    i = result.first.to_i
    # puts "PORT AND I: #{port} and #{i}"

    hardpoint_element = @ship_hardpoints[i]
    element = hardpoint_element ? hardpoint_element[:item] : nil

    if @window.cursor_object && element
      puts "@window.cursor_object[:key]: #{@window.cursor_object[:key]}"
      puts "ID: #{id}"
      puts "== #{@window.cursor_object[:key] == id}"
      if @window.cursor_object[:key] == id
        # Same Object, Unstick it, put it back
        # element[:follow_cursor] = false
        # @inventory_matrix[x][y][:item][:follow_cursor] =
        hardpoint_element[:item] = @window.cursor_object
        puts "CONFIG SETTING 1"
        ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
        hardpoint_element[:item][:key] = id
        @window.cursor_object = nil
      else
        # Else, drop object, pick up new object
        # @window.cursor_object[:follow_cursor] = false
        # element[:follow_cursor] = true
        temp_element = element
        hardpoint_element[:item] = @window.cursor_object
        hardpoint_element[:item][:key] = id
        puts "CONFIG SETTING 2 "
        ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
        @window.cursor_object = temp_element
        @window.cursor_object[:key] = nil # Original home lost, no last home of key present
        # @window.cursor_object[:follow_cursor] = true
        # WRRROOOONNGGG!
        # element = 
      end
    elsif element
      # Pick up element, no current object
      # element[:follow_cursor] = true
      @window.cursor_object = element
      hardpoint_element[:item] = nil
        puts "CONFIG SETTING 3 "
        # Not working.. 
      # puts [@ship.class.name, "#{port}_hardpoint_locations", i.to_s].to_s
      ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "hardpoint_locations", i.to_s], nil)
    elsif @window.cursor_object
      # Placeing something new in inventory
      hardpoint_element[:item] = @window.cursor_object
      # puts "PUTTING ELEMENT IN: #{hardpoint_element[:item]}"
        # puts "CONFIG SETTING 4 "
      # puts [@ship.class.name, "#{port}_hardpoint_locations", i.to_s].to_s
      # puts hardpoint_element[:item][:klass]
      ConfigSetting.set_mapped_setting(@config_file_path, [@ship.class.name, "hardpoint_locations", i.to_s], hardpoint_element[:item][:klass])
      hardpoint_element[:item][:key] = id
      # matrix_element[:item][:follow_cursor] = false
      @window.cursor_object = nil
    end
  end

  def get_values
    if @value
      @value
    end
  end

  def hardpoint_update
    hover_object = nil
    @ship_hardpoints.each do |value|
      click_area = value[:click_area]
      # puts "CLICK AREA: #{click_area.y}"
      if click_area
        is_hover = click_area.update(0, 0)
        # puts "WAS HARDPOINT HOVER? #{is_hover}"
        # puts "Value item"
        # puts value[:item]
        hover_object = {item: value[:item], holding_type: :hardpoint, holding_slot: value[:hp] } if is_hover
        # raise "GOT HERE" if is_hover
      end
    end
    return hover_object
  end

  def update mouse_x, mouse_y, player
    if @active
      puts "SHIP LOADOUT SETTING - HAD CURSOR OJBECT" if @window.cursor_object
      # if @window.cursor_object.nil? && @ship_inventory
      @mouse_x, @mouse_y = [mouse_x, mouse_y]

      @hover_object = hardpoint_update


      # hover_object = matrix_update
      hover_object = @ship_inventory.update(mouse_x, mouse_y, player)
      hover_object = @object_inventory.update(mouse_x, mouse_y, player) if !hover_object && @object_inventory
      # puts "GOT OBJECT FROM " if hover_object

      # Was there a point to this line?
      @hover_object = hover_object if @hover_object.nil?
      # puts "UPDATE HERE: #{@hover_object}"

      # display data on cover object

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
      return true
    else
      return nil
    end
  end

  # Not used
  # def get_hardpoints
  #   klass = eval(@ship_value)
  #   return {
  #     front: klass::FRONT_HARDPOINT_LOCATIONS,
  #     right: klass::PORT_HARDPOINT_LOCATIONS,
  #     left:  klass::STARBOARD_HARDPOINT_LOCATIONS
  #   }
  # end

  def get_image
    klass = eval(@ship_value)
    return klass.get_right_broadside_image(klass::ITEM_MEDIA_DIRECTORY)
  end

  def get_large_image
    klass = eval(@ship_value)
    large_image = klass.get_large_image(klass::ITEM_MEDIA_DIRECTORY)
    # puts "LARGE IMAGE HERE"
    # puts large_image
    # stop
    return large_image
  end

  # deprecated
  # def clicked mx, my
  #   raise "Deperected?"
  #   puts "SHIP LOADOUT CLICKED"
  #   if is_mouse_hovering_next(mx, my)

  #   elsif is_mouse_hovering_prev(mx, my)

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

  def detail_box_draw
    if @hover_object
      # puts "HOVEROBJECT"
      # puts @hover_object.keys
      # @font.draw("You are dead!", @width / 2 - 50, @height / 2 - 55, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.text_width('>')
      # @font.height

       # puts "HERER1: #{@hover_object[:holding_type]}"
      texts = []
      text = nil

      # Are these necessary here? Is there a difference? Maybe if it's a store, we can show a price.
      if @hover_object[:holding_type] == :inventory
      end
      if @hover_object[:holding_type] == :hardpoint
      end

      if @hover_object[:item]
        object = @hover_object[:item]
        if object[:klass].name
          texts << object[:klass].name
        end
        if object[:klass].description
          if object[:klass].description.is_a?(String)
            texts << object[:klass].description
          elsif object[:klass].description.is_a?(Array)
            object[:klass].description.each do |description|
              texts << description
            end
          end
        end
      end

      texts.each_with_index do |text, index|
        height_padding = index * @font_height
        # puts "HEIGHT PADDING: #{index} - #{height_padding}"
        @font.draw(text, (@max_width / 4), (@max_height) + height_padding - (@font_height * 8), ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
        # @font.draw(text, (@max_width / 2) - (@font.text_width(text) / 2.0), (@max_height) - @font_height - (@font_padding * 4), ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      end
    end
  end

  def draw
    if @active
      @ship_inventory.draw
      @object_inventory.draw if @object_inventory

      detail_box_draw

      if @window.cursor_object
        @window.cursor_object[:image].draw(@mouse_x, @mouse_y, @hardpoint_image_z, @width_scale, @height_scale)
      end

      hardpoint_draw

      # matrix_draw

      # @button.draw(-(@button.w / 2), -(@y_offset - @button.h / 2))
      @button.draw(-(@button.w / 2), -(@button.h / 2))

      @font.draw(@value, ((@max_width / 2) - @font.text_width(@value) / 2), @y, 1, 1.0, 1.0, 0xff_ffff00)

      @ship.draw
      # @font.draw(@value, ((@max_width / 2) - @font.text_width(@value) / 2), @y, 1, 1.0, 1.0, 0xff_ffff00)
      # @font.draw(">", @prev_x, @y, 1, 1.0, 1.0, 0xff_ffff00)
    end
  end

end