require_relative 'coords'
require_relative '../has_tids'

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
    
    # This is overwritten in subclasses to store useful data.
    def set_metadata(hash)    
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
      "Player(#{eid}, #{name.inspect}, #{coords}, #{(items-[nil]).size} items)"
    end
  end
  
  class ObjectEntity < Entity
    extend HasTids
    types.default = self
  end

  class DroppedItem < ObjectEntity
    attitude_is :passive   # this probably does not matter
    tid_is 2
    
    attr_reader :item   # this is nil for a while when the object is first created

    def item_type
      @item.item_type if @item
    end
    
    def set_metadata(hash)
      hash = hash.dup
      
      # Typically we receive 0 => 0 and 1 => 300 when an object is spawned.  I am not sure
      # what this metadata means, so just ignore it.
      hash.delete(0)
      hash.delete(1)
    
      if hash.has_key?(10)
        @item = hash[10]
      end
      
      # Oops, look at that, a little bit of the protocol leaked into the models directory :(      
    end
    
    def to_s
      "DroppedItem(#@eid, #@item, #{coords})"
    end
  end

  class Mob < Entity
    include EntityWithItems
    extend HasTids

    # If the type ID isn't recognized, that's OK.  Just create an instance of the parent class.    
    types.default = self
    
    def to_s
      "#{self.class.name.split('::').last}(#{eid}, #{coords}, #{(items-[nil]).size} items)"
    end
  end

  class Creeper < Mob
    tid_is 50
    attitude_is :hostile
  end

  class Skeleton < Mob
    tid_is 51
    attitude_is :hostile
  end

  class Spider < Mob
    tid_is 52
    attitude_is :hostile
  end

  class GiantZombie < Mob
    tid_is 53
    attitude_is :hostile
  end

  class Zombie < Mob
    tid_is 54
    attitude_is :hostile
  end

  class Slime < Mob
    tid_is 55
    attitude_is :hostile
  end

  class Ghast < Mob
    tid_is 56
    attitude_is :hostile
  end

  class ZombiePigman < Mob
    tid_is 57
    attitude_is :neutral
  end

  class Enderman < Mob
    tid_is 58
    attitude_is :neutral
  end

  class CaveSpider < Mob
    tid_is 59
    attitude_is :hostile
  end

  class Silverfish < Mob
    tid_is 60
    attitude_is :passive
  end

  class Blaze < Mob
    tid_is 61
    attitude_is :hostile
  end

  class MagmaCube < Mob
    tid_is 62
    attitude_is :hostile
  end

  class EnderDragon < Mob
    tid_is 63
    attitude_is :hostile
  end

  class Pig < Mob
    tid_is 90
    attitude_is :passive
  end

  class Sheep < Mob
    tid_is 91
    attitude_is :passive
  end

  class Cow < Mob
    tid_is 92
    attitude_is :passive
  end

  class Chicken < Mob
    tid_is 93
    attitude_is :passive
  end

  class Squid < Mob
    tid_is 94
    attitude_is :passive
  end

  class Wolf < Mob
    tid_is 95
    attitude_is :neutral
  end

  class Mooshroom < Mob
    tid_is 96
    attitude_is :passive
  end

  class Snowman < Mob
    tid_is 97
    attitude_is :utility
  end

  class Ocelot < Mob
    tid_is 98
    attitude_is :passive
  end

  class IronGolem < Mob
    tid_is 99
    attitude_is :utility
  end
    
  class Villager < Mob
    tid_is 120
    attitude_is :passive
  end

end