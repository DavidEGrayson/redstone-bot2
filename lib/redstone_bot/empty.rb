module RedstoneBot
  module Empty
    def self.===(other)
      other.respond_to?(:empty?) and other.empty?
    end
  end
  
  module NonEmpty
    def self.===(other)
      not Empty === other
    end
  end
end