require_relative 'coords'
require_relative '../tracks_types'

module RedstoneBot

  class Entity
    attr_accessor :eid
    attr_accessor :coords    # Coords object with floats
    attr_accessor :name      # nil for non-players
   
    def initialize(eid, coords)
      @eid = eid
      @coords = coords
    end
   
    # :passive, :neutral, :hostile, :utility
    def self.attitude
      @attitude
    end

    # This is called in the class definition.
    def self.attitude_is(attitude)
      @attitude = attitude
    end
    
    # to_coords is not an alias so that subclasses can easily and correctly override 'coords'
    def to_coords
      coords
    end
  end
  
  module EntityWithItems
    def items
      @items ||= []
    end
    
    def wielded_item
      items[0]
    end
    
    def helmet
      items[1]
    end
    
    def chestplate
      items[2]
    end
    
    def leggings
      items[3]
    end
    
    def boots
      items[4]
    end
    
  end

  class Player < Entity
    include EntityWithItems
    attitude_is :neutral
    
    def initialize(eid, coords, name=nil)
      super eid, coords
      @name = name
    end

    def to_s
      "Player(#{eid}, #{name.inspect}, #{coords}, #{items.join ', '})"
    end
  end

  class DroppedItem < Entity
    attitude_is :passive   # this probably does not matter

    attr_reader :item

    def initialize(eid, coords, item)
      super eid, coords
      @item = item
    end
    
    def item_type
      @item.item_type
    end
    
    def to_s
      "DroppedItem(#@eid, #@item, #{coords})"
    end
  end

  class Mob < Entity
    include EntityWithItems
    extend TracksTypes

    # If the type ID isn't recognized, that's OK.  Just create an instance of the parent class.    
    types.default = self
    
    def to_s
      "#{self.class.name.split('::').last}(#{eid}, #{coords}, #{items.join ', '})"
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