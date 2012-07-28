require "spec_helper"
require "openssl"
require "base64"
require "redstone_bot/packets"


describe OpenSSL::Cipher do
  before do
    # Example 1
    encryption_request = RedstoneBot::Packet.receive test_stream String.from_hex "fd:00:01:00:2d:00:a2:30:81:9f:30:0d:06:09:2a:86:48:86:f7:0d:01:01:01:05:00:03:81:8d:00:30:81:89:02:81:81:00:a3:6b:56:09:9c:2c:0a:88:05:42:4f:36:0e:ca:44:0e:08:a9:65:60:ea:8a:11:b7:aa:97:9e:6c:61:6b:6f:31:af:c2:3a:1e:3b:7e:ed:f9:22:d3:10:d5:b4:c9:fc:92:7f:a2:bc:d4:1c:1f:ac:97:74:c6:cc:54:9f:63:55:ea:4f:f2:37:8c:b4:61:da:ba:a1:26:e4:95:2e:f1:52:31:2b:e5:30:64:c4:32:b8:71:6d:41:8c:1e:0b:01:ff:ec:de:e1:67:3f:8c:ce:87:4f:49:1f:4b:f7:b2:df:a0:17:24:49:9e:1a:91:4b:d4:b5:25:4f:38:48:a6:d3:f6:71:02:03:01:00:01:00:04:c3:64:7e:92"
    @public_key = encryption_request.public_key
    @verify_token = encryption_request.verify_token
    @expected_encrypted_token = String.from_hex "4d:b7:54:c0:e4:14:63:49:44:29:e3:f7:23:43:69:28:e0:89:e8:ac:c1:95:6e:d8:24:14:dd:76:45:ca:cc:b5:04:67:a6:42:e7:03:41:0d:65:54:01:d3:1a:74:0f:bb:df:ab:1d:4f:9f:93:89:0a:fe:cb:14:91:12:ca:d2:7e:d5:6a:f4:16:45:b4:04:ff:9e:0d:4a:40:dc:c2:1a:8e:eb:31:7c:6c:f3:1a:16:15:7d:ea:51:f5:7e:cc:82:1b:5d:4f:dc:36:34:aa:46:1a:d7:9b:c1:c1:21:f2:52:ff:94:10:ad:b3:f2:36:0e:c0:f7:b9:69:99:d2:cc:a2:67"
    
    # Example 2 (overwrites example 1 for now)
    @public_key = String.from_hex "30:81:9f:30:0d:06:09:2a:86:48:86:f7:0d:01:01:01:05:00:03:81:8d:00:30:81:89:02:81:81:00:a3:6b:56:09:9c:2c:0a:88:05:42:4f:36:0e:ca:44:0e:08:a9:65:60:ea:8a:11:b7:aa:97:9e:6c:61:6b:6f:31:af:c2:3a:1e:3b:7e:ed:f9:22:d3:10:d5:b4:c9:fc:92:7f:a2:bc:d4:1c:1f:ac:97:74:c6:cc:54:9f:63:55:ea:4f:f2:37:8c:b4:61:da:ba:a1:26:e4:95:2e:f1:52:31:2b:e5:30:64:c4:32:b8:71:6d:41:8c:1e:0b:01:ff:ec:de:e1:67:3f:8c:ce:87:4f:49:1f:4b:f7:b2:df:a0:17:24:49:9e:1a:91:4b:d4:b5:25:4f:38:48:a6:d3:f6:71:02:03:01:00:01"
    @verify_token = String.from_hex "25:ff:99:01"
    @encrypted_token = String.from_hex "65:ff:dd:35:64:02:79:71:dc:ca:fa:32:c3:86:e1:ae:5e:0b:68:11:eb:76:af:92:ad:a6:08:d5:01:9d:92:52:48:f9:a7:be:f8:3f:60:05:3a:e0:13:b2:2d:09:4c:d2:2a:88:0b:14:cc:55:54:23:ef:78:0c:1d:3b:25:03:1f:27:55:e5:e6:cc:3e:4e:78:56:90:1f:9a:2b:6a:fc:e7:1d:e8:d0:e7:e5:22:52:4e:68:34:c2:85:55:bc:8f:20:7d:dd:cf:11:f4:5a:80:46:00:14:b9:27:fc:b6:61:5d:dd:6b:e4:5a:7e:6e:be:8b:28:2a:86:5a:f2:f9:53:e1"

    @public_key.size.should == 0xA2
    @verify_token.size.should == 4
    @expected_encrypted_token.size.should == 128
  end
  
  it "works" do
    key = OpenSSL::PKey::RSA.new(@public_key)
    key.should be_public
    key.to_der.should == @public_key
    key.should be_a_kind_of OpenSSL::PKey::RSA
    
    # Attempt 1
    encrypted = key.public_encrypt @verify_token, OpenSSL::PKey::RSA::PKCS1_PADDING
    encrypted2 = key.public_encrypt @verify_token, OpenSSL::PKey::RSA::PKCS1_PADDING
    encrypted.should == encrypted2
    
    encrypted.size.should == @expected_encrypted_token.size
    encrypted.should == @expected_encrypted_token    
  end

  # it "works2" do  
    # cipher = OpenSSL::Cipher.new('aes-128-cfb8')
    # cipher.encrypt
        
    # cipher = OpenSSL::Cipher.new('aes-128-ecb')
    # cipher.encrypt
    # cipher.key = @public_key
    
    # encrypted = cipher.update(@verify_token) + cipher.final
    # encrypted.size.should == @expected_encrypted_token.size
    # encrypted.should == @expected_encrypted_token
  # end
end