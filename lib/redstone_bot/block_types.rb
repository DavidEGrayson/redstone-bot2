module RedstoneBot
  class BlockType
    attr_reader :symbol, :id
  
    def initialize(id, symbol, solid)
      @id = id
      @symbol = symbol
      @solid = solid
    end
  
    def solid?
      @solid
    end
    
    def to_sym
      @symbol
    end
    
    def to_s
      @symbol.to_s
    end
    
    def to_i
      @id
    end
    
    @types = []  # array where each block type is placed
    def self.from_id(id)
      @types[id]
    end
    
    File.open(File.join(File.dirname(__FILE__), "block_types.tsv")) do |f|
      f.each_line do |line|
        id_string, name, attr_string = line.split
        id = id_string.to_i
        symbol = name.to_sym
        attrs = (attr_string||"").split(",")
        block_type = BlockType.new(id, symbol, attrs.include?("solid"))
        const_set symbol, block_type
        @types[id] = block_type
      end
    end
  end
end


