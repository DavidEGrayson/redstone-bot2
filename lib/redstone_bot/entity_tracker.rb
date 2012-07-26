require_relative "entities"

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
        next unless p.respond_to? :eid
        
        case p
        when Packet::SpawnNamedEntity
          entities[p.eid] = Player.new p.eid, p.player_name
          update_entity_position_absolute p
        when Packet::SpawnDroppedItem
          item_type = ItemType.from_id(p.item)
          raise "Unknown item type #{p.item} enocunted." if !item_type
          entities[p.eid] = Item.new p.eid, item_type, p.count, p.metadata
          update_entity_position_absolute p
        when Packet::SpawnMob
          entities[p.eid] = Mob.create p.eid, p.type
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
          entities.delete p.eid
        end
      end
    end
    
    def entities_of_type(klass)
      entities.values.select { |e| klass === e }
    end

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