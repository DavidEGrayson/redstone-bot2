require "redstone_bot/pack"
require "redstone_bot/packets"
require "redstone_bot/synchronizer"

require 'socket'
require 'io/wait'
require 'thread'

Thread.abort_on_exception = true

module RedstoneBot
  class Client
    include Synchronizer
  
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
      
      # Receive packets
      Thread.new do
        begin
          while true
            packet = receive_packet
            synchronize do
              notify_listeners packet
            end
          end
        rescue UnknownPacketError => e
          chat "WHAT'S 0x%02X PRECIOUSSS?" % [e.packet_type]
          exit 1
        end
      end
      
      # Send keepalives
      regularly(1) do
        send_packet Packet::KeepAlive
      end
      
    end
    
    def receive_packet
      Packet.receive(socket)
    end
    
    def send_packet(packet)
      socket.write packet.encode
    end
    
    def chat(message)
      send_packet Packet::ChatMessage.new(message) 
    end
  end
end