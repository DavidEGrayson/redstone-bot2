require_relative "../protocol/entities"

module RedstoneBot
  class EntityTracker
    attr_reader :entities
    attr_accessor :debug
    attr_accessor :debug_ignore

    # body should be an object that responds to .position and returns
    # a RedstoneBot::Coords representing the player's position.
    # A good choice is RedstoneBot::Body
    # This allows us to do things like find the closest entity.  It is optional.
    def initialize(client, body=nil)
      @entities = {}
      @body = body
      @debug_ignore = []
      
      client.listen do |p|
        next unless p.respond_to?(:eid) || p.respond_to?(:eids)
        
        case p
        when Packet::SpawnNamedEntity
          entities[p.eid] = Player.new p.eid, p.player_name
          update_entity_position_absolute p
        when Packet::SpawnDroppedItem
          entities[p.eid] = DroppedItem.new p.eid, p.item
          update_entity_position_absolute p
        when Packet::SpawnMob
          entities[p.eid] = Mob.create p.type, p.eid
          update_entity_position_absolute p
        when Packet::EntityTeleport
          update_entity_position_absolute p
        when Packet::EntityLookAndRelativeMove, Packet::EntityRelativeMove
          update_entity_position_relative p
        end
        
        if debug
          debug_packet p
        end

        if Packet::DestroyEntity === p
          p.eids.each { |eid| entities.delete eid }
        end
      end
    end

    def select(&proc)
      entities.values.select(&proc)
    end
    
    def entities_of_type(klass)
      select { |e| klass === e }
    end
    
    # TODO: get rid of this in favor of using @body.closest?  Then EntityTracker does not need @body
    def closest_entity(klass=Entity)
      entities_of_type(klass).min_by { |e| @body.distance_to(e.position) }
    end

    def debug_entities
      puts "==== ENTITITES ===="
      entities.values.sort_by { |e| e.class.name }.each do |entity|
        puts "#{entity.class} - #{entity}"
      end
      nil
    end
    
    def debug_packet(packet)
      entity = entities[packet.eid]
      
      return if debug_ignore.any? { |m| m === entity || m === packet }
      
      puts "#{packet.eid} #{packet.inspect} #{entity}"
    end
    
    def player(name)
      entities.values.find { |entity| entity.name == name and entity.class == Player }
    end

    protected  
    def update_entity_position_absolute(p)
      return unless entities.has_key?(p.eid)
      entities[p.eid].position = p.coords
    end

    def update_entity_position_relative(p)
      return unless entities.has_key?(p.eid)
      entities[p.eid].position += p.coords_change
    end
  end
end