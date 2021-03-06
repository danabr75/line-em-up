require_relative 'hardpoint_object'

module HardpointObjects
  class SteamCoreHardpoint < HardpointObjects::HardpointObject
    ABSTRACT_CLASS = true
    HARDPOINT_NAME = "replace_me"  
    PROJECTILE_CLASS   = nil 
    FIRING_GROUP_NUMBER = nil # Passive

    STEAM_MAX_CAPACITY  = nil
    STEAM_RATE_INCREASE = nil

    SHOW_HARDPOINT = false

    SLOT_TYPE = :steam_core

    def self.get_hardpoint_image
      raise "OVERRIDE ME"
    end

    def self.name
      raise "OVERRIDE ME"
    end

    def self.description
      raise "OVERRIDE ME"
    end

    def self.value
      raise "OVERRIDE ME"
    end
  end
end