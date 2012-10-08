#!/usr/bin/env ruby

require "openssl"

class Dispatch

# -------------------------------------------------------------
# Encryption
#
# Asymmetric ncryption scheme for the victim host. Encrypt
# using the attackers public key, decrypt using its own 
# private key.
# -------------------------------------------------------------

	# Encrypt
	#
	# Encrypt a string using the victim's public key and return
	# the cipher text.

	def encrypt(data)
		key = OpenSSL::PKey::RSA.new File.read '../keys/victim.pub'
		return key.public_key.public_encrypt(data)
	end

	# Dcrypt
	#
	# Decrypt cipher text using the attacker's private key and
	# return the result. 

	def decrypt(data)
		key = OpenSSL::PKey::RSA.new File.read '../keys/attacker.pem'
		return key.private_decrypt(data)
	end

# -------------------------------------------------------------
# Fin
# -------------------------------------------------------------

end
