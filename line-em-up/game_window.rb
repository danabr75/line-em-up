# A simple "Triangle Game" that allows you to move a Roguelike '@' around the
# window (and off of it). This is a working example on MacOS 10.12 as of Dec 16, 2017.
# This combines some of the Ruby2D tutorial code with keypress management
# that actually works.
# 
# Keys: hjkl: movement, q: quit
# 
# To run: ruby triangle-game.rb after installing the Simple2D library and Ruby2D Gem.
#
# Author: Douglas P. Fields, Jr.
# E-mail: symbolics@lisp.engineer
# Site: https://symbolics.lisp.engineer/
# Copyright 2017 Douglas P. Fields, Jr.
# License: The MIT License

# require 'gosu'

# Encoding: UTF-8

# The tutorial game over a landscape rendered with OpenGL.
# Basically shows how arbitrary OpenGL calls can be put into
# the block given to Window#gl, and that Gosu Images can be
# used as textures using the gl_tex_info call.

# require 'rubygems'
require 'gosu'

# CURRENT_DIRECTORY = File.expand_path('../', __FILE__)
# MEDIA_DIRECTORY   = File.expand_path('../', __FILE__) + "/media"
# VENDOR_DIRECTORY   = File.expand_path('../', __FILE__) + "/../vendors"


# ONLY ENABLE FOR WINDOWS COMPILATION
# Place opengl lib in lib library
# Replace the meths list iteration with the following (added rescue blocks):
  # meths.each do |mn|
  #   define_singleton_method(mn) do |*args,&block|
  #     begin
  #       implementation.send(mn, *args, &block)
  #     rescue
  #     end
  #   end
  #   define_method(mn) do |*args,&block|
  #     begin
  #       implementation.send(mn, *args, &block)
  #     rescue
  #     end
  #   end
  #   private mn
  # end
# For WINDOWS - using local lip
# require_relative 'lib/opengl.rb'
# FOR Linux\OSX - using opengl gem
# # require 'opengl'

require_relative "lib/global_constants.rb"
include GlobalConstants
Dir["#{LIB_DIRECTORY  }/*.rb"].each { |f| require f }
Dir["#{MODEL_DIRECTORY}/*.rb"].each { |f| require f }
Dir["#{VENDOR_LIB_DIRECTORY}/*.rb"].each { |f| require f }
# Sub folders as well.
Dir["#{LIB_DIRECTORY  }/**/*.rb"].each { |f| require f }
Dir["#{MODEL_DIRECTORY}/**/*.rb"].each { |f| require f }
Dir["#{VENDOR_LIB_DIRECTORY}/**/*.rb"].each { |f| require f }
# require_relative 'media'
# Dir["/path/to/directory/*.rb"].each {|file| require file }
# 
# exit if Object.const_defined?(:Ocra) #allow ocra to create an exe without executing the entire script



# RESOLUTIONS = [[640, 480], [800, 600], [960, 720], [1024, 768]]
# WIDTH, HEIGHT = 1080, 720
# require_relative 'models/graphics/smoke.rb'

class GameWindow < Gosu::Window

  RESOLUTIONS = [[640, 480], [800, 600], [960, 720], [1024, 768], [1280, 960], [1400, 1050], [1440, 1080], [1600, 1200], [1856, 1392], [1920, 1440], [2048, 1536]]
  DEFAULT_WIDTH, DEFAULT_HEIGHT = 640, 480

  include GlobalConstants
  # CONFIG_FILE = "#{CURRENT_DIRECTORY}/../config.txt"

  attr_accessor :width, :height, :block_all_controls, :ship_loadout_menu, :menu, :cursor_object

  attr_accessor :projectiles, :destructable_projectiles, :ships, :graphical_effects, :shipwrecks
  attr_accessor :add_projectiles, :remove_projectile_ids
  attr_accessor :add_ships, :remove_ship_ids
  attr_accessor :add_destructable_projectiles, :remove_destructable_projectile_ids

  include GlobalVariables

  def initialize width = nil, height = nil, fullscreen = false, options = {}


    # Thread.new do
    #   # results = Parallel.map((0..20), in_processes: 7, progress: "Proj Update: ", isolation: false) { |item| rand(255) }
    #   # results = Parallel.map((0..20), in_processes: 2, isolation: false) { |item| rand(255) }
    #   results = Parallel.map((0..20000), in_processes: 2) { |item| rand(255) }
    #   # results = Parallel.map((0..20), in_threads: 4) { |item| rand(255) }
    #   # Process.waitall
    #   puts "TEST HERE!!!! RESULTS HERE: #{results.count}"
    #   Thread.exit
    # end


    @config_path = self.class::CONFIG_FILE
    @window = self
    @open_gl_executer = ExecuteOpenGl.new

    # @smoke = Graphics::Smoke.new

    # GET difficulty from config file.!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    @difficulty = options[:difficulty]
    @block_all_controls = !options[:block_controls_until_button_up].nil? && options[:block_controls_until_button_up] == true ? true : false
    @debug = true #options[:debug]
    # GameWindow.fullscreen(self) if fullscreen
    @start_fullscreen = fullscreen
    @center_ui_y = 0
    @center_ui_x = 0

    # @width  = width || DEFAULT_WIDTH
    # @height = height || DEFAULT_HEIGHT

    # reset_center_font_ui_y

    # Need to just pull from config file.. and then do scaling. See LoadoutWindow
    # index = GameWindow.find_index_of_current_resolution(self.width, self.height)
    # if index == 0
    #   @scale = 1
    # else
    #   original_width, original_height = RESOLUTIONS[0]
    #   width_scale = @width / original_width.to_f
    #   height_scale = @height / original_height.to_f
    #   @scale = (width_scale + height_scale) / 2
    # end
    value = ConfigSetting.get_setting(@config_path, 'resolution', ResolutionSetting::SELECTION[0])
    raise "DID NOT GET A RESOLUTION FROM CONFIG" if value.nil?
    width, height = value.split('x')
    @width, @height = [width.to_i, height.to_i]

    default_width, default_height = ResolutionSetting::SELECTION[0].split('x')
    # default_width, default_height = default_value.split('x')
   # puts 'FOR TESTING:'
    # @width, @height = [default_width.to_i, default_height.to_i]
    # END TESTING

    @projectile_collision_manager = AsyncProcessManager.new(ProjectileCollisionThread, 8, true)
    @collision_counter = 0
    @destructable_collision_counter = 2
    @projectile_update_manager    = AsyncProcessManager.new(ProjectileUpdateThread, 8, true)
    # @projectile_update_manager    = AsyncProcessManager.new()
    @destructable_projectile_collision_manager = AsyncProcessManager.new(DestructableProjectileCollisionThread, 8, true)
    @destructable_projectile_update_manager    = AsyncProcessManager.new(DestructableProjectileUpdateThread, 8, true)

    # r, w = IO.pipe
    # @projectile_update_pipe_out, @projectile_update_pipe_in = IO.pipe
    # @projectile_update_pid = fork do
    #   AsyncProcessManager.new(@projectile_update_pipe_in, @projectile_update_pipe_out)

    # end

    @ship_update_manager = AsyncProcessManager.new(ShipUpdateThread, 8, true)

    # Need to just pull from config file.. and then do scaling.
    # index = GameWindow.find_index_of_current_resolution(self.width, self.height)
    if @width == default_width && @height == @default_height
      @width_scale = 1.0
      @height_scale = 1.0
      @average_scale = 1.0
      # @scale = @width / (@height.to_f)
      @resolution_scale = 1.0
    else
      # original_width, original_height = RESOLUTIONS[0]
      @width_scale =  @width / default_width.to_f
      @height_scale = @height / default_height.to_f
      @average_scale = (@width_scale + @height_scale) / 2.0

     # puts "WIDTH SCALE: #{@width_scale}"
     # puts "HEIGHT SCALE: #{@height_scale}"

     # puts "AVERAGE SCALE: #{@average_scale}"
      # @scale = (@width_scale + @height_scale) / 2
      # raise "NEW SCALE: #{@width_scale} x #{@height_scale}"
      # @scale = @width / (@height.to_f)
      @resolution_scale = @width.to_f / (@height.to_f)
     # puts "resolution_scale: #{@resolution_scale}"
    end


    super(@width, @height)
    # @width, @height = [@width.to_f, @height.to_f]
   # puts "TRYING TO SET RESOLUTION HERE: #{@width} and #{@height}"
   # puts "ACTUAL IS: #{self.width} and #{self.height}"
   # puts "Gosu.screen width: #{Gosu.screen_height} and Gosu.screen_height: #{Gosu.screen_height}"
    

    @game_pause = false
    # @menu = nil
    # @can_open_menu = true
    @can_pause = true
    @can_resize = !options[:block_resize].nil? && options[:block_resize] == true ? false : true
    @can_toggle_secondary = true
    @can_toggle_fullscreen_a = true
    @can_toggle_fullscreen_b = true


    self.caption = "OpenGL Integration"
    

    @gl_background = GLBackground.new(@height_scale, @height_scale, @width, @height, @resolution_scale)


    GlobalVariables.set_config(@width_scale, @height_scale, @width, @height,
      @gl_background.map_pixel_width, @gl_background.map_pixel_height,
      @gl_background.map_tile_width, @gl_background.map_tile_height,
      @gl_background.tile_pixel_width, @gl_background.tile_pixel_height,
      true
    )
    
    # @grappling_hook = nil
    
    @buildings = Array.new
    @projectiles = {}

    @add_projectiles = []
    @remove_projectile_ids = []

    @add_destructable_projectiles = []
    @remove_destructable_projectile_ids = []
    @destructable_projectiles = {}

    # @enemy_projectiles = Array.new
    # @pickups = Array.new

    @add_ships = []
    @ships = {}
    @remove_ship_ids = []



    @shipwrecks = Array.new
    # @enemies_random_spawn_timer = 100
    # @enemies_random_spawn_timer = 5
    # @enemies_spawner_counter = 0
    # @enemies_spawner_counter = 5

    # @max_enemy_count = 30
    # @enemies_killed = 0
    
    @font = Gosu::Font.new((10 * ((@width_scale + @height_scale) / 2.0)).to_i)
    # @max_enemies = 4
    # @max_enemies = 0

    @ui_y = 0
    @footer_bar = FooterBar.new(@width, @height, @height_scale, @height_scale)
    reset_font_ui_y

    # @boss_active_at_enemies_killed = 500
    # if @difficulty == 'easy'
    #   @boss_active_at_enemies_killed = 300
    #   @boss_active_at_level          = 2
    #   @handicap = 0.3
    # elsif @difficulty == "medium"
    #   @boss_active_at_level          = 3
    #   @boss_active_at_enemies_killed = 450
    #   @handicap = 0.6
    # else
    #   @boss_active_at_level          = 4
    #   @boss_active_at_enemies_killed = 700
    #   @handicap = 1
    # end

    # @player = Player.new(
    #   @scale, @width / 2, @height / 2, @width, @height,
    #   @gl_background.player_position_x, @gl_background.player_position_y, @gl_background.global_map_width, @gl_background.global_map_height,
    #   {handicap: @handicap, max_movable_height: @height - @footer_bar.height}

    # In the future, can use the map to mark insertion point for player. for now, we will choose the center
    @player = Player.new(
      @gl_background.map_pixel_width / 2.0, @gl_background.map_pixel_height / 2.0,
      @gl_background.map_tile_width / 2, @gl_background.map_tile_height / 2
    )

    @center_target = @player
    
    @pointer = Cursor.new(@width, @height, @height_scale, @height_scale, @player)

    @quest_data = QuestInterface.get_quests(CONFIG_FILE)

    values = @gl_background.init_map(@center_target.current_map_tile_x, @center_target.current_map_tile_y, self)
    @buildings = values[:buildings]
    values[:ships].each do |ship|
      @ship[ship.id] = ship
    end
    @pickups = values[:pickups]

    @messages = []
    @effects = []
    @graphical_effects = []

    @viewable_pixel_offset_x, @viewable_pixel_offset_y = [0, 0]
    viewable_center_target = nil

    @quest_data, @ships, @buildings, @messages, @effects = QuestInterface.init_quests_on_map_load(@config_path, @quest_data, @gl_background.map_name, @ships, @buildings, @player, @messages, @effects, self, {debug: @debug})
   # puts "EFFECTS COUNT ON INIT: #{@effects.count}"

    # @quest_data, @ships, @buildings = QuestInterface.update_quests(@config_path, @quest_data, @gl_background.map_name, @ships, @buildings, @player)

    # Loading in ActiveQuests .. start off with kill all enemie ships in the area
    # every ship killed must be checked against the quests
    # Move these to right after map init?

    # init_quest = {
    #   # Need to keep these strings around. We can eval them, but then can't convert them back to strings.
    #   "starting_level_quest": {
    #     victory_condition_string:      "lambda { |map_name, ships, buildings, player| ships.count == 0                               }",
    #     post_victory_triggers_string:  "lambda { |map_name, ships, buildings, player| {trigger_quests: ['followup-level-quest']}     }",
    #     active_condition_string:       "lambda { |map_name, ships, buildings, player| map_name == active_condition                   }"
    #   },
    #   "followup-level-quest": {
    #     victory_condition_string:      "lambda { |map_name, ships, buildings, player| buildings.count == 0                           }",
    #     post_victory_triggers_string:  "lambda { |map_name, ships, buildings, player| {trigger_quests: ['followup-level-quest']}     }",
    #     active_condition_string:       "lambda { |map_name, ships, buildings, player| map_name == active_condition }",
    #     map_init_string:               "lambda { |map_name, ships, buildings, player|  ships << AIShip.new(nil, nil, x_value.to_i, y_value.to_i) if map_name == 'desert_v2_small'; return {ships: ships, buildings: buildings} }"

    #   }
    # }
    # test = AIShip.new(nil, nil, 123, 123, {:id=>"starting_level_quest_ship_1"})
    # init_quest_data = init_quest_data.to_json
    # quests = [init_quest]
    # active_quest_data = ConfigSetting.get_setting(@config_path, 'Quests', quests.to_json)
    # puts "ACTIVE_QUEST"
    # puts active_quest_data.inspect
    # active_quests_data = eval(active_quest_data)
    # active_quests = {}
    # active_quests_data.each do |quest|
    #   quest.each do |quest_id, quest_hash|
    #     active_quests[quest_id] = {}
    #    # puts "active_quests[quest_id]: #{active_quests[quest_id]}"
    #    # puts "quest_hash: #{quest_hash}"
    #     active_quests[quest_id][:victory_condition]     = eval(quest_hash[:victory_condition_string]) if quest_hash[:victory_condition_string] && quest_hash[:victory_condition_string] != ''
    #     active_quests[quest_id][:post_victory_triggers] = eval(quest_hash[:post_victory_triggers_string]) if quest_hash[:post_victory_triggers_string] && quest_hash[:post_victory_triggers_string] != ''
    #     active_quests[quest_id][:active_condition]      = eval(quest_hash[:active_condition_string]) if quest_hash[:active_condition_string] && quest_hash[:active_condition_string] != ''
    #   end
    # end
    # puts "ACTIVE_QUESTV2"
    # puts active_quests
    # @active_quests = active_quests
    # Run these active quests through the update block. If the victory condition is met, need to update the json data. And move it to inactive.
    # Create quest management interface module... can retrieve, store, etc.
    # raise "STOP HERE"
    # Inactive quests are dormant until triggered. Map location.. or death of a special ship.
    # One triggered, they should be moved into the active_quest_data


    # @scroll_factor = 1
    # @movement_x = 0
    # @movement_y = 0
    @viewable_offset_x = 0
    @viewable_offset_y = 0
    # @can_toggle_scroll_factor = true
    @boss_active = false
    @boss = nil
    @boss_killed = false

    @debug = true #is_debug?

    # START MENU INIT
    # Can punt to different file
    @window = self
    @menu = Menu.new(@window, @width / 2, 10 * @average_scale, ZOrder::UI, @resolution_scale)
    @menu.add_item(
      :resume, "Resume",
      0, 0,
      lambda {|window, menu, id| menu.disable },
      nil,
      {is_button: true}
    )
    @menu.add_item(
      :loadout, "Inventory",
      0, 0,
      # Might be the reason why the mapping has to exist in the game window scope. Might not have access to ship loadout menu here.
      lambda {|window, menu, id| window.menu.disable; window.ship_loadout_menu.enable },
      nil,
      {is_button: true}
    )
    # This will close the window... which i guess is fine.
    @menu.add_item(
      :back_to_menu, "Back To Menu",
      0, 0,
      lambda {|window, menu, id| self.close; Main.new.show }, 
      nil,
      {is_button: true}
    )
    @menu.add_item(
      :exit, "Exit",
      0, 0,
      lambda {|window, menu, id| window.close; }, 
      nil,
      {is_button: true}
    )
    # END  MENU INIT

    # START SHIP LOADOUT INIT.
    # @refresh_player_ship = false
    @cursor_object = nil
    @ship_loadout_menu = ShipLoadoutSetting.new(@window, @width, @height, get_center_font_ui_y, @config_path, @height_scale, @height_scale, {scale: @average_scale})
    # @object_attached_to_cursor = nil
    # END  SHIP LOADOUT INIT.
    @menus = [@ship_loadout_menu, @menu]
    # LUIT.config({window: @window, z: 25})
    # @button = LUIT::Button.new(@window, :test, 450, 450, "test", 30, 30)
  end

  def menus_active
    @menus.collect{|menu| menu.active }.include?(true)
  end


  # Switch button downs to this method
  # This only triggers once during press. Use the other section for when we want it contunually triggered
  def button_down(id)
    # puts "HERE: #{id.inspect}"
    # super(id)
    # Not necessary when using LUIT.. using `update` instead for trigger
    # if id == Gosu::MsLeft
    #   @menu.clicked
    # end

    # if id == Gosu::MsLeft
    #   @ship_loadout_menu.clicked
    # end

    if @player.is_alive && !@game_pause && !@menu_open
              # KB_LEFT_CONTROL    = 224,
      if id == Gosu::KB_LEFT_CONTROL && @player.ready_for_special?
       # puts "Gosu::KB_LEFT_CONTROL CLICKED!!"
        # @projectiles += @player.special_attack([@enemies, @buildings, @enemy_destructable_projectiles, [@boss]])
        # @projectiles += @player.special_attack_2
      end
    end

  end

  # required for LUIT objects, passes id of element
  def onClick element_id
    if @menu.active
      @menu.onClick(element_id)
    elsif @ship_loadout_menu.active
      @ship_loadout_menu.onClick(element_id)
    else
      if @effects.any?
        @effects.each do |effect|
          effect.onClick(element_id)
        end
      end
    end
  end


  def self.reset(window, options = {})
    window = GameWindow.new(window.width, window.height, window.fullscreen?, options.merge({block_controls_until_button_up: true})).show
  end

  def self.start width = nil, height = nil, fullscreen = false, options = {}
    GameWindow.new(width, height, fullscreen, options).show
  end

# When fullscreen, try to match window with screen resolution
# .screen_height ⇒ Integer
# The height (in pixels) of the user's primary screen.
# .screen_width ⇒ Integer
# The width (in pixels) of the user's primary screen.

  def self.fullscreen(window)
    window.fullscreen = !window.fullscreen?
  end

  def self.resize(window, width, height, fullscreen)
    window = GameWindow.new(width, height).show
    window.fullscreen = fullscreen
  end

  def self.find_index_of_current_resolution width, height
    current_index = nil
    counter = 0
    RESOLUTIONS.each do |resolution|
      break if current_index && current_index > 0
      current_index = counter if resolution[0] == width && resolution[1] == height
      counter += 1
    end
    return current_index
  end

  def self.up_resolution(window)
    # # puts "UP RESLUTION"
    # index = find_index_of_current_resolution(window.width, window.height)
    # # puts "FOUND INDEX: #{index}"
    # if index == RESOLUTIONS.count - 1
    #   # Max resolution, do nothing
    # else
    #   # window.width = RESOLUTIONS[index + 1][0]
    #   # window.height = RESOLUTIONS[index + 1][1]
    #   width = RESOLUTIONS[index + 1][0]
    #   height = RESOLUTIONS[index + 1][1]
    #   # puts "UPPING TO #{width} x #{height}"
    #   window = GameWindow.new(width, height, {block_resize: true}).show
    # end
  end

  def self.down_resolution(window)
    # index = find_index_of_current_resolution(window.width, window.height)
    # if index == 0
    #   # Min resolution, do nothing
    # else
    #   # window.width = RESOLUTIONS[index - 1][0]
    #   # window.height = RESOLUTIONS[index - 1][1]
    #   width = RESOLUTIONS[index - 1][0]
    #   height = RESOLUTIONS[index - 1][1]
    #   window = GameWindow.new(width, height, {block_resize: true}).show
    # end
  end

  def button_up id
    @block_all_controls = false
    # Grappling hook always active
    # if (id == Gosu::MS_RIGHT) && @player.is_alive
    #   @grappling_hook.deactivate if @grappling_hook
    # end

    if (id == Gosu::KB_P)
      @can_pause = true
    end
    if (id == Gosu::KB_TAB)
      @can_toggle_secondary = true
    end
    # if (id == Gosu::KB_Q || id == Gosu::KB_E)
    #   @can_toggle_scroll_factor = true
    # end

    if id == Gosu::KB_RETURN
      @can_toggle_fullscreen_a = true
    end
    if id == Gosu::KB_RIGHT_META
      @can_toggle_fullscreen_b = true
    end
    if id == Gosu::KB_MINUS
      @can_resize = true
    end
    if id == Gosu::KB_EQUALS
      @can_resize = true
    end
    if id == Gosu::MS_RIGHT
      @player.deactivate_group_3
    end
    if id == Gosu::MS_LEFT
      @player.deactivate_group_2
    end
    if id == Gosu::KB_SPACE
      @player.deactivate_group_1
    end

    if id == Gosu::KB_LEFT_SHIFT
      @player.disable_boost
    end 
  end

  def get_center_font_ui_y
    return_value = @center_ui_y
    @center_ui_y += 10 * @average_scale
    return return_value
  end

  def get_center_font_ui_x
    return @center_ui_x
  end

  # def reset_center_font_ui_y
  #   @center_ui_y = @height  / 2
  #   @center_ui_x = @width / 2
  # end

  def is_debug?
    ENV['debug'] == 'true' || ENV['debug'] == true
  end

  def update
    @quest_data, @ships, @buildings, @messages, @effects = QuestInterface.update_quests(@config_path, @quest_data, @gl_background.map_name, @ships, @buildings, @player, @messages, @effects, self)
    
    @add_projectiles.reject! do |projectile|
      @projectiles[projectile.id] = projectile
      true
    end

    @remove_projectile_ids.reject! do |projectile_id|
      @projectiles.delete(projectile_id)
      true
    end

    @add_ships.reject! do |ship|
      @ships[ship.id] = ship
      true
    end

    @remove_ship_ids.reject! do |ship_id|
      @ships.delete(ship_id)
      true
    end


    @add_destructable_projectiles.reject! do |dp|
      @destructable_projectiles[dp.id] = dp
      true
    end

    @remove_destructable_projectile_ids.reject! do |dp_id|
      puts "DELETING DESTUCTABLE ID: #{dp_id}"
      @destructable_projectiles.delete(dp_id)
      true
    end




    if @ship_loadout_menu.refresh_player_ship
      @player.refresh_ship
      @ship_loadout_menu.refresh_player_ship = false
    end

    # Reset cursor object. # Need to move this inside of ship loadout... or can't, cause of scope?
    # @cursor_object = nil
    # @cursor_object = @ship_loadout_menu.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)



    @pointer.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y, @viewable_pixel_offset_x, @viewable_pixel_offset_y) if @pointer

    # @smoke.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)

    if @start_fullscreen
      @start_fullscreen = false
      GameWindow.fullscreen(self)
    end
    # reset_center_font_ui_y
    @menu.update
    @ship_loadout_menu.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)

    # puts "HERE UPDATE: [@game_pause, menus_active, @menu_open, @menu.active]"
    if !@game_pause && !menus_active && !@menu_open && !@menu.active
      @effects.reject! do |effect_group|
        @gl_background, @ships, @buildings, @player, @viewable_center_target, @viewable_pixel_offset_x, @viewable_pixel_offset_y = effect_group.update(@gl_background, @ships, @buildings, @player, @viewable_center_target, @viewable_pixel_offset_x, @viewable_pixel_offset_y)
        !effect_group.is_active
      end

      # @graphical_effects.reject! do |effect|
      #   !effect.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)
      # end

      if @collision_counter < 4
        # puts "SKIPPING COLLISION MANAGER"
        @collision_counter += 1
      else
        # puts "CALLING COLLISION MANAGER"
        @projectile_collision_manager.update(self, @projectiles, [@ships, @destructable_projectiles, {'player' => @player} ])
        # @destructable_projectile_collision_manager = AsyncProcessManager.new(DestructableProjectileCollisionThread, 8, true)
        # @destructable_projectile_update_manager    = AsyncProcessManager.new(DestructableProjectileUpdateThread, 8, true)
        @collision_counter = 0
      end

      if @destructable_collision_counter < 4
        # puts "SKIPPING COLLISION MANAGER"
        @destructable_collision_counter += 1
      else
        # puts "CALLING COLLISION MANAGER"
        # @projectile_collision_manager.update(self, @projectiles, [@ships, @destructable_projectiles, {'player' => @player} ])
        @destructable_projectile_collision_manager.update(self, @destructable_projectiles, [@ships, {'player' => @player} ])
        # @destructable_projectile_update_manager    = AsyncProcessManager.new(DestructableProjectileUpdateThread, 8, true)
        @destructable_collision_counter = 0
      end

      # @projectile_update_manager.update(self, self.mouse_x, self.mouse_y, @player)

      # require 'parallel'
      # results = Parallel.map((0..200), in_processes: 7, progress: "Main Update: ", isolation: false) { |item| rand(255) }
      # puts "MAIN WINDOW: #{results.count}"

      # @projectile_update_manager.update(@projectiles, ProjectileUpdateProcess, self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)
      @destructable_projectile_update_manager.update(self, @destructable_projectiles, self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)
      @projectile_update_manager.update(self, @projectiles, self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)
      # @projectile_update_manager.update

      @ship_update_manager.update(self, @ships, self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y, @ships.merge({'player' => @player}), @buildings)

      #projectiles remove themselves
      # @projectiles.reject! do |projectile|
      #   !projectile.is_alive
      # end


    end

    if !@block_all_controls
      # Moving up buildings, so clickable buildings can block the player from attacking.
      @buildings.reject! { |building| !building.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y, @player.x, @player.y) }
      # puts "WINDOW BLOCK CONTROLS HER"
      @messages.reject! { |message| !message.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y) }

      if Gosu.button_down?(Gosu::KbEscape) && !menus_active
        @menu.enable
      end

      # if Gosu.button_down?(Gosu::KB_LEFT_SHIFT) && !menus_active
      #   @player.enable_boost
      #   # if @player.use_steam(0.5)
      #   #   @player.movement(@average_scale / 2, @player.angle)
      #   # end
      # end

      if Gosu.button_down?(Gosu::KB_M)
        GameWindow.reset(self, {debug: @debug})
      end

      if Gosu.button_down?(Gosu::KB_RIGHT_META) && Gosu.button_down?(Gosu::KB_RETURN) && @can_toggle_fullscreen_a && @can_toggle_fullscreen_b
        @can_toggle_fullscreen_a = false
        @can_toggle_fullscreen_b = false
        GameWindow.fullscreen(self)
      end


      if Gosu.button_down?(Gosu::KB_P) && @can_pause
        @can_pause = false
        @game_pause = !@game_pause
      end

      if Gosu.button_down?(Gosu::KB_O) && @can_resize
        @can_resize = false
        GameWindow.resize(self, 1920, 1080, false)
      end

      if Gosu.button_down?(Gosu::KB_MINUS) && @can_resize
        @can_resize = false
        GameWindow.down_resolution(self)
      end
      if Gosu.button_down?(Gosu::KB_EQUALS) && @can_resize
        @can_resize = false
        GameWindow.up_resolution(self)
      end



      if @player.is_alive && !@game_pause && !menus_active
        if Gosu.button_down?(Gosu::KB_TAB) || Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::GP_RIGHT)
          @can_toggle_secondary = false
          @player.toggle_secondary
        end

        if Gosu.button_down?(Gosu::KB_A) || Gosu.button_down?(Gosu::KB_LEFT)  || Gosu.button_down?(Gosu::GP_LEFT)
          # @can_toggle_scroll_factor = false
          @player.rotate_counterclockwise
        end

        if Gosu.button_down?(Gosu::KB_D)# && @can_toggle_scroll_factor
          # @can_toggle_scroll_factor = false
          @player.rotate_clockwise
        end

        @player.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y, @pointer.current_map_pixel_x, @pointer.current_map_pixel_y)
        @player.move_left  if Gosu.button_down?(Gosu::KB_Q)# Gosu.button_down?(Gosu::KB_LEFT)  || Gosu.button_down?(Gosu::GP_LEFT)    || 
        @player.move_right if Gosu.button_down?(Gosu::KB_E)# Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::GP_RIGHT)   || 
        # puts "MOVEMENT HERE: #{@movement_x} and #{@movemeny_y}"if Gosu.button_down?(Gosu::KB_UP)    || Gosu.button_down?(Gosu::GP_UP)      || Gosu.button_down?(Gosu::KB_W)
        @player.accelerate if Gosu.button_down?(Gosu::KB_UP)    || Gosu.button_down?(Gosu::GP_UP)      || Gosu.button_down?(Gosu::KB_W)
        @player.brake      if Gosu.button_down?(Gosu::KB_DOWN)  || Gosu.button_down?(Gosu::GP_DOWN)    || Gosu.button_down?(Gosu::KB_S)
        @player.reverse    if Gosu.button_down?(Gosu::KB_X)

        results = @gl_background.update(@player.current_map_pixel_x, @player.current_map_pixel_y, @buildings, @pickups, @viewable_pixel_offset_x, @viewable_pixel_offset_y)
        @buildings = results[:buildings]
        # @pickups = results[:pickups]
        # NEED to update background's projectiles
        # @projectiles = results[:projectiles]
        
        if Gosu.button_down?(Gosu::MS_RIGHT)
            @player.attack_group_3(@pointer).each do |results|
              # puts "RESULTS HERE: #{}"
              results[:projectiles].each do |projectile|
                @projectiles[projectile.id] = projectile if projectile
              end
              results[:destructable_projectiles].each do |projectile|
                # @destructable_projectiles.push(projectile) if projectile
                @destructable_projectiles[projectile.id] = projectile if projectile
              end
              results[:graphical_effects].each do |effect|
                @graphical_effects.push(effect) if effect
              end
            end
        end

        if Gosu.button_down?(Gosu::MS_LEFT)
            @player.attack_group_2(@pointer).each do |results|
              results[:projectiles].each do |projectile|
                # @projectiles.push(projectile) if projectile
                @projectiles[projectile.id] = projectile if projectile
              end
              results[:destructable_projectiles].each do |projectile|
                # @destructable_projectiles.push(projectile) if projectile
                @destructable_projectiles[projectile.id] = projectile if projectile
              end
              results[:graphical_effects].each do |effect|
                @graphical_effects.push(effect) if effect
              end
            end
        else
          # MOVE ELSEWHERE... KEY UP
          # @player.deactivate_group_2
        end

        if Gosu.button_down?(Gosu::KB_SPACE)
          # Player cooldown no longer used.
          # if @player.cooldown_wait <= 0
            @player.attack_group_1(@pointer).each do |results|
              results[:projectiles].each do |projectile|
                # @projectiles.push(projectile) if projectile
                @projectiles[projectile.id] = projectile if projectile
              end
              results[:destructable_projectiles].each do |projectile|
                # @destructable_projectiles.push(projectile) if projectile
                @destructable_projectiles[projectile.id] = projectile if projectile
              end
              results[:graphical_effects].each do |effect|
                @graphical_effects.push(effect) if projectile
              end

            end
          # end
        else
          # MOVE ELSEWHERE... KEY UP
          # @player.deactivate_group_1
        end


        # @player.collect_pickups(@pickups)

        # @enemy_projectiles.each do |projectile|
        #   results = projectile.hit_objects([[@player]])
        #   # @pickups = @pickups + results[:drops]
        # # end
        # @destructable_projectiles.each do |projectile|
        #   results = projectile.hit_objects([[@player]])
        #   # @pickups = @pickups + results[:drops]
        # end


        # @grappling_hook.collect_pickups(@player, @pickups) if @grappling_hook && @grappling_hook.active
      end

      if !@game_pause && !menus_active && !@menu_open && !@menu.active
        # Can't iterate AND add to the projectiles.. so needs to stay synchronous
        # @projectiles.each do |key, projectile|
        #   # @projectile_collision_manager.add(projectile)
        #   @projectile_update_manager.add(projectile)
        # end
        # Thread.new(@projectiles, @projectile_collision_manager, @projectile_update_manager) do |local_projectiles, manager1, manager2|
        #   local_projectiles.each do |key, projectile|
        #     manager1.add(projectile)
        #     manager2.add(projectile)
        #   end
        #   Thread.exit
        # end

        # @ships.each do |ship|
        #   @ship_update_manager.add(ship)
        # end
        # Thread.new(@ships, @ship_update_manager) do |local_ships, manager1|
        #   local_ships.each do |ship|
        #     manager1.add(ship)
        #   end
        #   Thread.exit
        # end

        # @destructable_projectiles.each do |projectile|
        #   result = projectile.hit_objects([@ships, @destructable_projectiles, [@player]])
        #   result[:graphical_effects].each do |effect|
        #     @graphical_effects << effect if effect
        #   end
        # end
        
        

        # if @player.is_alive && @grappling_hook
        #   grap_result = @grappling_hook.update(@player)
        #   @grappling_hook = nil if !grap_result
        # end

        # @pickups.reject! { |pickup| !pickup.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y) }



        # The projectiles and enemy projectiles... only allows for two factions.. we need to support multiple...
        # attacks need to be able to handle.. lists of enemies and lists of allies maybe??
        # @projectiles.reject! do |projectile|
        #   result = projectile.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)
        #   result[:graphical_effects].each do |effect|
        #     @graphical_effects << effect if effect
        #   end
        #   !result[:is_alive]
        # end
        # @destructable_projectiles.reject! do |projectile|
        #   result = projectile.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y)

        #   result[:graphical_effects].each do |effect|
        #     @graphical_effects << effect if effect
        #   end

        #   !result[:is_alive]
        # end


        @shipwrecks.reject! do |ship|
          result = ship.update(nil, nil, @player.current_map_pixel_x, @player.current_map_pixel_y)
          # puts "SHIPWREK RESULT"
          # puts result.inspect
          if result[:building]
            result[:building].set_window(self)
            @buildings << result[:building]
          end
          !result[:is_alive]
        end
        # puts "SHIPS HERE: #{@ships.count}"
        # puts "SHIPS ids: #{@ships.collect{|s| s.id }}"
        # @ships.reject! do |ship|
        #   # puts "CALLING SHIP UPDATE HERE: #{ship.id}"
        #   # results = ship.update(self.mouse_x, self.mouse_y, @player.current_map_pixel_x, @player.current_map_pixel_y, @ships + [@player], @buildings)
        #   # puts "RESULTS HERE: #{results}" if results[:projectiles]
        #   #RESULTS HERE: {:is_alive=>true, :projectiles=>[{:projectiles=>[#<Bullet:0x00007fa4bf72f180 @tile_pixel_width=112.5, @tile_pixel_height=112.5, @map_pixel_width=28125, @map_pixel_height=28125, @map_tile_width=250, @map_tile_height=250, @width_scale=1.875, @height_scale=1.875, @screen_pixel_width=900, @screen_pixel_height=900, @debug=true, @damage_increase=1, @average_scale=1.7578125, @id="e09ca7e3-563b-4c96-bd63-918c36065a54", @image=#######

        #   # puts "@enemy_projectiles:"
        #   # puts @enemy_projectiles
        #   # results[:projectiles].each do |projectile|
        #   #   @projectiles.push(projectile) if projectile
        #   # end
        #   # results[:destructable_projectiles].each do |projectile|
        #   #   @destructable_projectiles.push(projectile) if projectile
        #   # end
        #   # results[:graphical_effects].each do |effect|
        #   #   @graphical_effects.push(effect)
        #   # end
        #   # @shipwrecks << results[:shipwreck] if results[:shipwreck]

        #   # @enemy_projectiles = @enemy_projectiles + results[:projectiles]
        #   # puts "SHIP ID HERE: #{ship.id} and is alive? : #{results[:is_alive]}"
        #   # !results[:is_alive]
        #   !ship.is_alive
        # end

      end
    end # END if !@block_all_controls
    # @button.update
  end # END UPDATE FUNCTION

  def draw
    # Adding pointer as a opengl coord test
    # puts "@enemy_projectiles:"
    # puts @enemy_projectiles.class
    # puts @enemy_projectiles

    @open_gl_executer.draw(self, @gl_background, @player, @pointer, @buildings, @pickups)
    @pointer.draw# if @grappling_hook.nil? || !@grappling_hook.active
    # @smoke.draw
    @menu.draw
    @ship_loadout_menu.draw
    # @button.draw
    @footer_bar.draw(@player)
    # @boss.draw if @boss
    # @pointer.draw(self.mouse_x, self.mouse_y) if @grappling_hook.nil? || !@grappling_hook.active

    @player.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) if @player.is_alive && !@ship_loadout_menu.active
    # @grappling_hook.draw(@player) if @player.is_alive && @grappling_hook
    if !menus_active && !@player.is_alive
      @font.draw("You are dead!", @width / 2 - 50, @height / 2 - 55, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Press ESC to quit", @width / 2 - 50, @height / 2 - 40, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Press M to Restart", @width / 2 - 50, @height / 2 - 25, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    end
    # if @boss_killed
    #   @font.draw("You won! Your score: #{@player.score}", @width / 2 - 50, @height / 2 - 55, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    # end
    @font.draw("Paused", @width / 2 - 50, @height / 2 - 25, ZOrder::UI, 1.0, 1.0, 0xff_ffff00) if @game_pause
    # reactivate
    @ships.each { |key, ship| ship.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }
    @shipwrecks.each { |ship| ship.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }
    @projectiles.each { |key, projectile| projectile.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }
    @destructable_projectiles.each { |key, projectile| projectile.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }
    @buildings.each { |building| building.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }
    # @font.draw("Score: #{@player.score}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    # @font.draw("Level: #{@enemies_spawner_counter + 1}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    # @font.draw("Enemies Killed: #{@enemies_killed}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    # @font.draw("Boss Health: #{@boss.health.round(2)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00) if @boss
    @messages.each_with_index do |message, index|
      message.draw(index)
    end
    # @effects.each_with_index do |effect, index|
    #   effect.draw
    # end
    # @graphical_effects.each { |effect| effect.draw(@viewable_pixel_offset_x, @viewable_pixel_offset_y) }

    if @debug
      # @font.draw("Attack Speed: #{@player.attack_speed.round(2)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Health: #{@player.health}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Armor: #{@player.armor}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Rockets: #{@player.rockets}", 10, 70, ZOrder::UI, 1.0, 1.0, 0xff_ffff00) if @player.secondary_weapon == 'missile'
      # @font.draw("Bombs: #{@player.bombs}", 10, 70, ZOrder::UI, 1.0, 1.0, 0xff_ffff00) if @player.secondary_weapon == 'bomb'
      @font.draw("Time Alive: #{@player.time_alive}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("STEAM: #{@player.ship.current_steam_capacity}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Ship count: #{@ships.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("enemy_projectiles: #{@enemy_projectiles.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("projectiles count: #{@projectiles.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("destructable_proj: #{@destructable_projectiles.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("pickups count: #{@pickups.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("buildings count: #{@buildings.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Object count: #{@ships.count + @projectiles.count + @destructable_projectiles.count + @pickups.count + @buildings.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Damage Reduction: #{@player.damage_reduction.round(2)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Boost Incease: #{@player.boost_increase.round(2)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Attack Speed: #{@player.attack_speed.round(2)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("FPS: #{Gosu.fps}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("BG - GPS: #{@gl_background.gps_map_center_x} - #{@gl_background.gps_map_center_y}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("GPS: #{@player.current_map_tile_x} - #{@player.current_map_tile_y}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("MAP PIXEL: #{@player.current_map_pixel_x.round(1)} - #{@player.current_map_pixel_y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Angle: #{@player.angle}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("Momentum: #{@player.ship.current_momentum.to_i}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @font.draw("----------------------", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)

      # @font.draw("Cursor MAP PIXEL   : #{@pointer.current_map_pixel_x.round(1)} - #{@pointer.current_map_pixel_y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("Cursor SCREEN PIXEL: #{@pointer.x.round(1)} - #{@pointer.y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # if @projectiles.any? && false
      #   @font.draw("----------------------", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("P GPS: #{@projectiles.last.current_map_tile_x} - #{@projectiles.last.current_map_tile_y}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("P MAP PIXEL: #{@projectiles.last.current_map_pixel_x.round(1)} - #{@projectiles.last.current_map_pixel_y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("P Angle: #{@projectiles.last.angle}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # end
      # if @buildings.any?
      #   @font.draw("----------------------", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("B GPS: #{@buildings.last.current_map_tile_x} - #{@buildings.last.current_map_tile_y}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("B MAP PIXEL: #{@buildings.last.current_map_pixel_x.round(1)} - #{@buildings.last.current_map_pixel_y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # end
      # @font.draw("@messages: #{@messages.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # if @ships.any?
      #   @font.draw("----------------------", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("E GPS: #{@ships.last.current_map_tile_x} - #{@ships.last.current_map_tile_y}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("E MAP PIXEL: #{@ships.last.current_map_pixel_x.round(1)} - #{@ships.last.current_map_pixel_y.round(1)}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("E Angle: #{@ships.last.angle}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("E Momentum: #{@ships.last.current_momentum.to_i}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      #   @font.draw("E ID: #{@ships.last.id}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # end
      @font.draw("Active Quests", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @quest_data.each do |quest_key, values|
        next if values["map_name"] != @gl_background.map_name
        if values['state'] == 'active'
          @font.draw("- #{quest_key}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
        end
      end
      @font.draw("Completed Quests", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      @quest_data.each do |quest_key, values|
        next if values["map_name"] != @gl_background.map_name
        if values['state'] == 'complete'
          @font.draw("- #{quest_key}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
        end
      end

      # @font.draw("Quests", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @quest_data.each do |quest_key, values|
      #   @font.draw("- #{quest_key} annd state - #{values['state']}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # end
      if @effects.any?
        @font.draw("----------------------", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
        @font.draw("Effect: #{@effects.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      end
      @font.draw("G-Effect: #{@graphical_effects.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("SHIPWRECK COUNT: #{@shipwrecks.count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # local_count = 0
      # @buildings.each do |b|
      #   local_count += 1 if b.class::CLASS_TYPE == :landwreck
      # end
      # @font.draw("LANDWRECK COUNT: #{local_count}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
      # @font.draw("VIEW OFFSET: #{[@viewable_pixel_offset_x.round(1), @viewable_pixel_offset_y.round(1)]}", 10, get_font_ui_y, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)

    end
    # @gl_background.draw(ZOrder::Background)
    reset_font_ui_y
  end

  def get_font_ui_y
    return_value = @ui_y
    @ui_y += 15 
    return return_value
  end
  def reset_font_ui_y
    @ui_y = 10
  end
end

GameWindow.new.show if __FILE__ == $0
