require_relative 'coords'

# TODO, eventually: move all these sublasses into the RedstoneBot::Entity namespace or something

class Entity
  attr_accessor :eid
	attr_accessor :position  # Coords object with floats
	attr_accessor :name      # nil for non-players

	# :passive, :neutral, :hostile, :utility
	def self.attitude
		@attitude
	end

	# This is called in the class definition.
	def self.attitude_is(attitude)
		@attitude = attitude
	end
end

class Player < Entity
	attitude_is :neutral

	def initialize(eid, name=nil)
		@eid = eid
		@name = name
	end

	def to_s
		"Player(#{eid}, #{name.inspect}, #{position})"
	end
end

# Lets you associate some kind id (usually an integer) to different
# classes and then create them using the integer.
module TracksTypes
  def self.extended(klass)
    klass.instance_eval do
      @@types = {}
    end
  end

  def types
    @@types
  end
  
  # This is called in the subclass definitions.
	def type_is(type)
		@type = type
		types[type] = self
	end

   # This is only called on self.
	def create(type, *args)
		(types[type] || self).new(*args)
	end
end

class Mob < Entity
	@mob_types = {}       # Associates mob id (50..120) to the different Mob subclasses.
	def self.mob_types
		@mob_types
	end

	def initialize(eid)
		@eid = eid
	end

	# This is called in the subclass definitions.  TODO: get rid of this and just use 'extend TracksTypes'
	def self.mob_type(type)
		@mob_type = type
		Mob.mob_types[type] = self
	end

	def self.create(eid, type)
		(mob_types[type] || Mob).new(eid)
	end

	def to_s
		"#{self.class}(#{eid}, #{position})"
	end
end

class Item < Entity
  extend TracksTypes
  attitude_is :passive   # this probably does not matter

  attr_reader :count, :metadata  

	def initialize(eid, count, metadata)
		@eid = eid
    @count = count
    @metadata = metadata
	end
  
  def to_s
    "#{self.class}#{'x'+count.to_s if count > 1}(#{eid}, #{position}, #{metadata})"
  end
end

class Creeper < Mob
	mob_type 50
	attitude_is :hostile
end

class Skeleton < Mob
	mob_type 51
	attitude_is :hostile
end

class Spider < Mob
	mob_type 52
	attitude_is :hostile
end

class GiantZombie < Mob
	mob_type 53
	attitude_is :hostile
end

class Zombie < Mob
	mob_type 54
	attitude_is :hostile
end

class Slime < Mob
	mob_type 55
	attitude_is :hostile
end

class Ghast < Mob
	mob_type 56
	attitude_is :hostile
end

class ZombiePigman < Mob
	mob_type 57
	attitude_is :neutral
end

class Enderman < Mob
	mob_type 58
	attitude_is :neutral
end

class CaveSpider < Mob
	mob_type 59
	attitude_is :hostile
end

class Silverfish < Mob
	mob_type 60
	attitude_is :passive
end

class Blaze < Mob
	mob_type 61
	attitude_is :hostile
end

class MagmaCube < Mob
	mob_type 62
	attitude_is :hostile
end

class EnderDragon < Mob
	mob_type 63
	attitude_is :hostile
end

class Pig < Mob
	mob_type 90
	attitude_is :passive
end

class Sheep < Mob
	mob_type 91
	attitude_is :passive
end

class Cow < Mob
	mob_type 92
	attitude_is :passive
end

class Chicken < Mob
	mob_type 93
	attitude_is :passive
end

class Squid < Mob
	mob_type 94
	attitude_is :passive
end

class Wolf < Mob
	mob_type 95
	attitude_is :neutral
end

class Mooshroom < Mob
	mob_type 96
	attitude_is :passive
end

class Snowman < Mob
	mob_type 97
	attitude_is :utility
end

class Ocelot < Mob
	mob_type 98
	attitude_is :passive
end

class Villager < Mob
	mob_type 120
	attitude_is :passive
end

class IronShovel < Item
  type_is 256  
end

class Seeds < Item
  type_is 295
end

class Wheat < Item
  type_is 296
end

class Bread < Item
  type_is 297
end

