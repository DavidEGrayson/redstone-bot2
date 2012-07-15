require "redstone_bot/entities"

module RedstoneBot
  class EntityTracker
    attr_reader :entities

    # body should be an object that responds to .position and returns
    # a vector of numbers representing the player's position.
    # A good choice is RedstoneBot::Body
    # This allows us to do things like find the closest entity.  It is optional.
    def initialize(client, body=nil)
      @entities = {}
      @body = body
      
      client.listen do |p|
        case p
        when Packet::NamedEntitySpawn
          entities[p.eid] = Player.new p.eid, p.player_name
          update_entity_position_absolute p
        when Packet::MobSpawn
          entities[p.eid] = Mob.create p.eid, p.type
          update_entity_position_absolute p
        when Packet::EntityTeleport
          update_entity_position_absolute p
        when Packet::EntityLookAndRelativeMove, Packet::EntityRelativeMove
          update_entity_position_relative p
        when Packet::DestroyEntity
          entities.delete p.eid
        end
      end
    end
    
    def entities_of_type(klass)
      entities.values.select { |e| klass === e }
    end

    def closest_entity(klass=Entity)
      entities_of_type(klass).min_by { |e| distance_to(e.position) }
    end

    def distance_to(position)
      (position - player_position).magnitude
    end

    def debug_entities
      puts "==== ENTITITES ===="
      entities.values.sort_by { |e| e.class.name }.each do |entity|
        puts "#{entity.class} - #{entity}"
      end
      nil
    end

    protected  
    def update_entity_position_absolute(p)
      return unless entities.has_key?(p.eid)
      entities[p.eid].position = Vector[p.x, p.y, p.z]/32.0
    end

    def update_entity_position_relative(p)
      return unless entities.has_key?(p.eid)
      entities[p.eid].position += Vector[p.dx, p.dy, p.dz]/32.0
    end
    
    def player_position
      @body.position
    end
  end
end