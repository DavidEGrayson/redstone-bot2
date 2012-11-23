module RedstoneBot
  # Lets you associate some kind id (usually an integer) to different
  # classes and then create them using the integer.
  module TracksTypes
    def self.extended(klass)
      t = {}
      
      klass.singleton_class.send(:define_method, :types) do
        t
      end
      
    end
    
    # This is called in the subclass definitions.
    def type_is(type)
      @type = type
      types[type] = self
    end

     # This is only called on self.
    def create(type, *args)
      (types[type] || self).new(*args)
    end
  end
end