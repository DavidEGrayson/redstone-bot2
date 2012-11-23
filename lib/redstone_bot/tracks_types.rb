module RedstoneBot
  # Lets you associate some kind id (usually an integer) to different
  # classes and then create them using the integer.
  module TracksTypes
    def self.extended(klass)
      # Use a closure because for some reason @@types didn't work
      # when there were multiple classes extending TracksTypes.
      types = {}
      klass.singleton_class.send(:define_method, :types) do
        types
      end
    end
    
    # This is called in the subclass definitions.
    def type_is(type)
      @type = type
      types[type] = self
    end

     # This is only called on self.
    def create(type, *args)
      klass = types[type]
      
      # To override this behavior, just write
      #   types.default = some_klass
      # in the class definition of some appropriate class.
      if !klass
        raise "Unrecognized type of #{name}: #{type}"
      end
      
      klass.new(*args)
    end
  end
end