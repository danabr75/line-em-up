require_relative 'armor_hardpoint.rb'

module HardpointObjects
  class BasicArmorHardpoint < HardpointObjects::ArmorHardpoint
    ABSTRACT_CLASS = false
    HARDPOINT_NAME = "basic_armor"

    PERMANENT_STEAM_USE       = 0
    TILES_PER_SECOND_MODIFIER = 0.7
    ROTATION_MODIFIER         = 0.8
    DAMAGE_REDUCTION          = 0.5
    # SHOW_HARDPOINT = false

    # SHOW_HARDPOINT_BASE = false


    def self.get_hardpoint_image
      Gosu::Image.new("#{MEDIA_DIRECTORY}/hardpoints/#{HARDPOINT_NAME}/hardpoint.png")
    end

    def self.description
      "Basic Armor"
    end

    def self.value
      300
    end
  end
end