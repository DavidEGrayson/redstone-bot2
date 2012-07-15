require 'matrix'

class Entity
  attr_accessor :id
	attr_accessor :position  # Vector of floats
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

	def initialize(id, name=nil)
		@id = id
		@name = name
	end

	def to_s
		"Player(#{id}, #{name.inspect}, #{position})"
	end
end

class Mob < Entity
	@mob_types = {}       # Associates mob id (50..120) to the different Mob subclasses.
	def self.mob_types
		@mob_types
	end

	def initialize(id)
		@id = id
	end

	# This is called in the class definition.
	def self.mob_type(type)
		@mob_type = type
		Mob.mob_types[type] = self
	end

	def self.create(id, type)
		(mob_types[type] || Mob).new(id)
	end

	def to_s
		"#{self.class}(#{id}, #{position})"
	end
end

def Mob(id)
	klass = Class.new(Mob)
	klass.mob_type id
	klass
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

