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
    @types_by_string = {}
    def self.from_id(id)
      @types[id]
    end
    
    def self.from_string(string)
      @types_by_string[string.downcase]
    end
    
    def self.from(x)
      case x
      when nil, "nil" then nil
      when Integer then from_id(x)
      when String
        x = x.gsub(/\s+/,'')
        from_string(x.to_s) or (from_id(x.hex) if x[0,2]=='0x') or (from_id(x.to_i) if x =~ /\d+/)
      end
    end
    
    File.open(File.join(File.dirname(__FILE__), "block_types.tsv")) do |f|
      f.each_line do |line|
        id_string, name, attr_string = line.split
        id = id_string.to_i
        symbol = name.to_sym
        attrs = (attr_string||"").split(",")
        block_type = BlockType.new(id, symbol, attrs.include?("solid"))
        const_set symbol, block_type
        @types_by_string[symbol.to_s.downcase] = @types[id] = block_type        
      end
    end
    
    # TODO: better way to represent this, so that FullyGrown can actually be a constant.
    class << Wheat
      def fully_grown
        7
      end
    end
  end
end


