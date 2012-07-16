
module RedstoneBot
  # Vulnerabilities:
  #   Thread.new { while true; end }
  #   "eval " + string
  #   EvaluatesRuby.instance_method(:handle_chat).bind(self).call(message)
  class ChatEvaluator
    attr_accessor :only_for_username
    attr_accessor :permission_denied_message
  
    def initialize(context, client)
      @context = context
      @client = client
      @permission_denied_message = "I'm sorry %s, but I cannot do that."
    
      client.listen do |p|
        next unless p.is_a?(Packet::UserChatMessage)

        next unless p.contents =~ /^eval (.+)/
        str = $1

        if only_for_username && p.username != only_for_username
          @client.chat @permission_denied_message % [p.username]
          next
        end
        
        do_eval str
      end
    end
  
    def do_eval(string)
      result = nil
      thread = Thread.new do
        $SAFE = 4
        result = begin
          eval string
        rescue Exception => e
          e.message
        end
      end
      if !thread.join(0.5)
        thread.kill
        result = ":("
      end

      begin
        case result
          when String then chat result
          when nil then
          else chat result.inspect
          end
      rescue SecurityError => e
        chat e.message 
      end

      GC.enable
    end
    
    protected
    def chat(message)
      @client.chat(message)
    end
  end
  
end