#!/usr/bin/ruby
# coding: utf-8

require 'optparse'
require 'yaml'
require 'gros_singe'

options = {}
optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: gros_singe_launch.rb [options]"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do options[:verbose] = true end
  opts.on( '-s', '--server SERVER', 'Connects to SERVER' ) do|str| options[:server] = str end
  opts.on( '-p', '--port PORT', 'Uses PORT' ) do|str| options[:port] = str end
  opts.on( '-c', '--chan CHANNEL', 'Joins #CHANNEL' ) do|str| options[:chan] = str end
  opts.on( '-n', '--nick NICK', 'Connects as NICK' ) do|str| options[:nick] = str end
  opts.on( '-f', '--file FILE', 'Use config from FILE' ) do|file| options[:configfile] = file end
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do|file| options[:logfile] = file end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

# If a config file is provided, we read from it
if options[:configfile]
  conf = YAML.load_file(options[:configfile])
  server = conf['server']
  port = conf['port']
  chan = conf['channel']
  nick = conf['nick']
  pwd = conf['pwd']
  logfile = conf['logfile']
end

# all config is overriden by command params
verbose = options[:verbose] if options[:verbose]
server = options[:server] if options[:server]
port = options[:port] if options[:port]
chan = options[:chan] if options[:chan]
nick = options[:nick] if options[:nick]
configfile = options[:configfile] if options[:configfile]
logfile = options[:logfile] if options[:logfile]

# default
server = "irc.rezosup.org" unless server
port = "6667" unless port
chan = "neuneu" unless chan
nick = "Gros_Singe" unless nick
configfile = "" unless configfile
logfile = "./logs/#{nick}.log" unless logfile

puts "using configfile: " + configfile + "." if configfile
puts "logfile: " + logfile + "."
puts "connected to: " + server + ":" + port.to_s + "/" + chan.gsub(/#/, '') + " as " + nick + "."

# instantiate and run bot.
bot = Gros_Singe.new server, port, chan.gsub(/#/, ''), nick, pwd, logfile, verbose
bot.run

# EOF
