module RedstoneBot
  class ItemType
    attr_reader :id, :symbol, :max_stack
  
    def initialize(id, symbol, max_stack, solid)
      @id = id
      @symbol = symbol
      @max_stack = max_stack
      @solid = solid
    end
  
    def ===(other)
      self == other or other.respond_to?(:item_type) && self == other.item_type
    end
  
    def solid?
      @solid
    end
    
    def to_sym
      @symbol
    end
    
    def block?
      id < 256
    end
    
    def stackable?
      max_stack > 1
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
    
    File.open(File.join(File.dirname(__FILE__), "item_types.tsv")) do |f|
      f.each_line do |line|
        id_string, name, max_stack_string, attr_string = line.split
        id = id_string.to_i
        symbol = name.to_sym
        max_stack = max_stack_string.to_i        
        attrs = (attr_string||"").split(",")

        item_type = new(id, symbol, max_stack, attrs.include?("solid"))
        
        string = name.downcase
        raise "Multiple item types named #{name}" if @types_by_string[string]
        raise "Multiple item types with id #{id}" if @types[id]
        const_set symbol, item_type
        @types_by_string[string] = @types[id] = item_type
      end
    end
    
    class << WheatBlock
      def fully_grown
        7
      end
    end
  end
end


