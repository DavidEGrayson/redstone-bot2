# ChatMover: a class that converts chat commands into movements,
# so you can tell your bot where to go.  I am open to better name
# suggestions for ChatMover and ChatEvaluator and future chat-listening
# classes.

module RedstoneBot
  module ChatMover
    def chat_mover(p)
      case p.chat
      when /\Awhere u looking?\??/
        chat "yaw=%.2f pitch=%.2f" % [body.look.yaw, body.look.pitch]
      when /\Awhere (.+)\Z/ then
        name = $1
        if name == "u" || name == @chatter.username
          chat "I be at #{position}"
        else
          player = entity_tracker.player(name)
          if player
            chat "dat guy at #{player.position}"
          else
            chat "dunno who dat '#{name}' is"
          end
        end
      when "stop" then stop
      when "n", "z-" then move_to position - Coords::Z
      when "s", "z+" then move_to position + Coords::Z
      when "e", "x+" then move_to position + Coords::X
      when "w", "x-" then move_to position - Coords::X
      when "j" then jump
      when "m"
        player = entity_tracker.player(p.username)
        if player
          x, z = player.coords.x, player.coords.z
          chat "coming to #{x}, #{z}!"
          miracle_jump x, z
        else
          chat "dunno where U r (chat m <X> <Z> to specify)"
        end
      when /m (\-?[\.\d]+) (\-?[\.\d]+)/
        x = $1.to_f
        z = $2.to_f
        chat "coming to #{x}, #{z}!"
        miracle_jump x, z
      when "follow me"
        player = entity_tracker.player(p.username)
        if player
          chat "coming!"
          follow(speed: 20) do 
            entity_tracker.player(p.username)
          end
        else
          chat "dunno where U r"
        end   
      when "fetch"
        item = entity_tracker.closest_entity(Item)
        if item
          path_to item
        else 
          chat "don't see dat"
        end
      when "M"
        player = entity_tracker.player(p.username)
        if player
          chat "coming!"
          move_to player
        else
          chat "dunno where U r"
        end
      when "h"
        player = entity_tracker.player(p.username)
        if player
          chat "coming!"
          path_to player
        else
          chat "dunno where U r"
        end
      end
    end

  end
end