module RedstoneBot
  class ChunkTracker
    def initialize(client)
      client.listen do |p|
        case p
        when Packet::ChunkAllocation, Packet::ChunkData, Packet::MultiBlockChange, Packet::BlockChange
          puts Time.now.strftime("%M:%S.%L") + " " + p.inspect
        end
      end
    end
    
  end
  
end