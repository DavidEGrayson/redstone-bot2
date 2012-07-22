module RedstoneBot
  class SimpleCache
    def initialize(change_source, &proc)
      raise "no block given" unless block_given?
      @proc = proc
      @hash = {}
      change_source.on_change do |id|
        @hash.delete id
      end
    end
    
    def [](id)
      if @hash.has_key?(id)
        @hash[id]
      else
        @hash[id] = @proc.call(id)
      end
    end
    
    def delete(id)
      @hash.delete(id)
    end
    
    def clear
      @hash.clear
    end
  end
end