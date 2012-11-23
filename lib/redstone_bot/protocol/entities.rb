require_relative '../coords'
require_relative '../tracks_types'
require_relative 'item_types'

module RedstoneBot

  class Entity
    attr_accessor :eid
    attr_accessor :position  # Coords object with floats
    attr_accessor :name      # nil for non-players
   
    def initialize(eid)
      @eid = eid
    end
   
    # :passive, :neutral, :hostile, :utility
    def self.attitude
      @attitude
    end

    # This is called in the class definition.
    def self.attitude_is(attitude)
      @attitude = attitude
    end
    
    # to_coords is not an alias so that subclasses can easily and correctly override 'position'
    def to_coords
      position
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

  class Mob < Entity
    extend TracksTypes

    # If the type ID isn't recognized, that's OK.  Just create an instance of the parent class.    
    types.default = self
    
    def to_s
      "#{self.class.name.split('::').last}(#{eid}, #{position})"
    end
  end

  # TODO: call this a DroppedItem and have it just contain a Slot object, but rename Slot to Item?
  class Item < Entity
    attitude_is :passive   # this probably does not matter

    attr_reader :count, :metadata, :item_type

    def initialize(eid, item_type, count, metadata)
      @eid = eid
      @item_type = item_type
      @count = count
      @metadata = metadata
    end
    
    def to_s
      "#{item_type}#{'x'+count.to_s if count > 1}(#{eid}, #{position}, #{metadata})"
    end
  end

  class Creeper < Mob
    type_is 50
    attitude_is :hostile
  end

  class Skeleton < Mob
    type_is 51
    attitude_is :hostile
  end

  class Spider < Mob
    type_is 52
    attitude_is :hostile
  end

  class GiantZombie < Mob
    type_is 53
    attitude_is :hostile
  end

  class Zombie < Mob
    type_is 54
    attitude_is :hostile
  end

  class Slime < Mob
    type_is 55
    attitude_is :hostile
  end

  class Ghast < Mob
    type_is 56
    attitude_is :hostile
  end

  class ZombiePigman < Mob
    type_is 57
    attitude_is :neutral
  end

  class Enderman < Mob
    type_is 58
    attitude_is :neutral
  end

  class CaveSpider < Mob
    type_is 59
    attitude_is :hostile
  end

  class Silverfish < Mob
    type_is 60
    attitude_is :passive
  end

  class Blaze < Mob
    type_is 61
    attitude_is :hostile
  end

  class MagmaCube < Mob
    type_is 62
    attitude_is :hostile
  end

  class EnderDragon < Mob
    type_is 63
    attitude_is :hostile
  end

  class Pig < Mob
    type_is 90
    attitude_is :passive
  end

  class Sheep < Mob
    type_is 91
    attitude_is :passive
  end

  class Cow < Mob
    type_is 92
    attitude_is :passive
  end

  class Chicken < Mob
    type_is 93
    attitude_is :passive
  end

  class Squid < Mob
    type_is 94
    attitude_is :passive
  end

  class Wolf < Mob
    type_is 95
    attitude_is :neutral
  end

  class Mooshroom < Mob
    type_is 96
    attitude_is :passive
  end

  class Snowman < Mob
    type_is 97
    attitude_is :utility
  end

  class Ocelot < Mob
    type_is 98
    attitude_is :passive
  end

  class IronGolem < Mob
    type_is 99
    attitude_is :utility
  end
    
  class Villager < Mob
    type_is 120
    attitude_is :passive
  end

end