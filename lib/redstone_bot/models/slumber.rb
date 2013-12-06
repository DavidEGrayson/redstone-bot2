module RedstoneBot
  class Slumber
    def initialize(client, body, chunk_tracker, entity_tracker, time_tracker, brain)
      @client = client
      @body = body
      @chunk_tracker = chunk_tracker
      @time_tracker = time_tracker
      @entity_tracker = entity_tracker
      
      if brain
        @brain = brain
        @synchronizer = brain.synchronizer
      end
      
      @client.listen &method(:receive_packet)
    end
    
    def bed_sleep_until_woken(bed_coords)
      return unless @brain.require { bed_sleep_until_woken(bed_coords) }
      
      bed_use bed_coords
      result = @synchronizer.timeout(10) do
        @synchronizer.wait_until { in_bed? }
      end
      if result == :timeout
        $stderr.puts "Failed to get into bed.  day_age=#{time_tracker.day_age}"
      end
      
      @synchronizer.wait_until { !in_bed? }
    end
    
    def in_bed?
      !@bed_coords.nil?
    end
    
    def receive_packet(p)
      case p
      when Packet::PlayerPositionAndLook
        if @bed_coords
          # The server is telling us we have left bed.
          puts "#{@client.time_string} We have left bed."
          @bed_coords = nil
          @body.immobilize(nil)
        end
      when Packet::UseBed
        if !@entity_tracker.entities.has_key?(p.eid)
          # The server told us we have gone to sleep by sending this
          # UseBed packet with a non-existent entity number.
          @bed_coords = p.coords
          puts "#{@client.time_string} We are sleeping in bed at #{@bed_coords}."
          
          @body.immobilize(self)
        end
      end
    end
  
    def bed_use(bed_coords)
      block_type = @chunk_tracker.block_type(bed_coords)
      if block_type != ItemType::BedBlock
        raise "Cannot use bed: #{bed_coords} is #{block_type}."
      end

      if @time_tracker.day?
        raise "Cannot use bed: it is daytime."
      end
      
      # TODO: check object metadata so we can tell if the bed is occupied
      
      @body.immobilization_check!
      
      if @body.busy?
        raise "Cannot use bed because the body is busy doing something else."
      end
      
      if @body.distance_to(bed_coords) > 10
        raise "Bed is too far away."
      end
                
      @client.send_packet Packet::PlayerBlockPlacement.new bed_coords, 1, nil
      
      # If this fails, we could get get:
      #   A chat packet with {"translate" => "tile.bed.occupied"}
      #   A chat packet with {"translate" => "time.bed.noSleep"} (cannot sleep during day)
      # If we get kicked out of bed in the morning, we receive:
      #   Position update packet
    end
    
    def bed_leave
      eid = 0  # tmphax, shouldn't this be the entity that represents me?
      @client.send_packet Packet::EntityAction.new eid, :leave_bed
      
      # TODO: make sure that sending this packet results in the 'we have left bed' message above (indirectly through the server)
    end

  end
end