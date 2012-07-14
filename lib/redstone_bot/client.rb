require "redstone_bot/pack"
require "redstone_bot/packets"

require 'socket'
require 'io/wait'
require 'thread'

module RedstoneBot
  class Client
    attr_reader :socket
    attr_reader :username
    attr_reader :hostname
    attr_reader :port
    attr_reader :entity_id
    
    def initialize(username, hostname, port)
      @username = username
      @hostname = hostname
      @port = port
      @listeners = []
    end
    
    def synchronize(&block)
      @mutex.synchronize(&block)
    end
    
    # Called at setup time.
    def listen(&proc)
      @listeners << proc
    end
    
    def notify_listeners(*args)
      synchronize do
        @listeners.each do |l|
          l.call(*args)
        end
      end
    end
    
    def start
      @mutex = Mutex.new    
      @socket = TCPSocket.open hostname, port
      @socket.extend DataReader
      
      send_packet Packet::Handshake.new(username, hostname, port)
      receive_packet
      
      send_packet Packet::LoginRequest.new(username)
      @entity_id = receive_packet.entity_id
      
      notify_listeners :start
      Thread.new do
        while true
          packet = receive_packet
          notify_listeners packet
        end
      end
    end
    
    def receive_packet
      Packet.receive(socket)
    end
    
    def send_packet(packet)
      socket.write packet.encode
    end
  end
end