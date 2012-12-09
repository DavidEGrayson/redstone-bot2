require_relative "../models/entities"

module RedstoneBot
  class EntityTracker
    attr_reader :entities

    # body should be an object that responds to .position and returns
    # a RedstoneBot::Coords representing the player's position.
    # A good choice is RedstoneBot::Body
    # This allows us to do things like find the closest entity.  It is optional.
    def initialize(client, body=nil)
      @entities = {}
      @body = body
      
      client.listen &method(:receive_packet)
    end

    def receive_packet(p)
      return unless p.respond_to?(:eid) || p.respond_to?(:eids)
      
      case p
      when Packet::SpawnNamedEntity
        entities[p.eid] = Player.new p.eid, p.coords, p.player_name
      when Packet::SpawnDroppedItem
        entities[p.eid] = DroppedItem.new p.eid, p.coords, p.item
      when Packet::SpawnMob
        entities[p.eid] = Mob.create p.type, p.eid, p.coords
      when Packet::DestroyEntity
        p.eids.each { |eid| entities.delete eid }
      end and return
      
      entity = entities[p.eid] or return
      
      case p
      when Packet::EntityTeleport
        entity.coords = p.coords
      when Packet::EntityLookAndRelativeMove, Packet::EntityRelativeMove
        entity.coords += p.coords_change
      when Packet::EntityEquipment
        entity.items[p.spot_id] = p.item
      end
    end
    
    def select(&proc)
      entities.values.select(&proc)
    end
    
    def entities_of_type(klass)
      entities.values.grep klass
    end
    
    # TODO: get rid of this in favor of using @body.closest ?  Then EntityTracker does not need @body
    #  or just move this to some module that is mixed into bot?
    def closest_entity(klass=Entity)
      entities_of_type(klass).min_by { |e| @body.distance_to(e) }
    end
    
    def player(name)
      entities.values.find { |entity| entity.name == name and entity.is_a?(Player) }
    end
    
    def entities_with_enchanted_items 
      select do |entity|
        entity.respond_to?(:items) && (entity.items-[nil]).any? { |i| i.enchantments }
      end
    end 

    def report
      s = "==== ENTITITES ====\n"
      entities.values.sort_by { |e| e.class.name }.each do |entity|
        s.concat "#{entity.class} - #{entity}\n"
      end
      s
    end
  end
end