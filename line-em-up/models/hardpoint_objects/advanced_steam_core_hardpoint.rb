require_relative 'steam_core_hardpoint.rb'

module HardpointObjects
  class AdvancedSteamCoreHardpoint < HardpointObjects::SteamCoreHardpoint
    ABSTRACT_CLASS = false
    HARDPOINT_NAME = "advanced_steam_core"
    PROJECTILE_CLASS   = nil 
    FIRING_GROUP_NUMBER = nil # Passive

    STEAM_MAX_CAPACITY  = 200.0
    # STEAM_MAX_CAPACITY  = 1000000.0
    STEAM_RATE_INCREASE = 0.3

    SLOT_TYPE = :steam_core

    def self.get_hardpoint_image
      # raise "OVERRIDE ME"
      Gosu::Image.new("#{MEDIA_DIRECTORY}/hardpoints/#{HARDPOINT_NAME}/hardpoint.png")
    end

    def self.name
      "Advanced Steam Core"
    end

    def self.description
      "Generates power for your ship; Your engines and weapons"
    end

    def self.value
      3000
    end
  end
end