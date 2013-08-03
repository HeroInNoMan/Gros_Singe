#!/usr/bin/ruby

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
  opts.on( '-d', '--database DATABASE', 'Connect to DATABASE' ) do|str| options[:database] = str end
  opts.on( '-s', '--server SERVER', 'Connect to SERVER' ) do|str| options[:server] = str end
  opts.on( '-p', '--port PORT', 'Use PORT' ) do|str| options[:port] = str end
  opts.on( '-c', '--chan CHANNEL', 'Join #CHANNEL' ) do|str| options[:chan] = str end
  opts.on( '-n', '--nick NICK', 'Connect as NICK' ) do|str| options[:nick] = str end
  opts.on( '-f', '--file FILE', 'Use config from FILE' ) do|file| options[:configfile] = file end
  opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do|file| options[:logfile] = file end

  # Display the help screen
  opts.on( '-h', '--help', 'Display this screen' ) do puts opts; exit end
end

optparse.parse!

# If a config file is provided, read from it
if options[:configfile]
  conf = YAML.load_file(options[:configfile])
  database = conf['database']
  server = conf['server']
  port = conf['port']
  chan = conf['channel']
  nick = conf['nick']
  pwd = conf['pwd']
  logfile = conf['logfile']
end

# Override config file by command params
verbose = options[:verbose] if options[:verbose]
database = options[:database] if options[:database]
server = options[:server] if options[:server]
port = options[:port] if options[:port]
chan = options[:chan] if options[:chan]
nick = options[:nick] if options[:nick]
configfile = options[:configfile] if options[:configfile]
logfile = options[:logfile] if options[:logfile]

# Set default values where necessary
database = "gros_singe.db" unless database
server = "irc.rezosup.org" unless server
port = "6667" unless port
chan = "neuneu" unless chan
nick = "Gros_Singe" unless nick
configfile = "" unless configfile
logfile = "./logs/#{nick}.log" unless logfile

# Instantiate and run the bot.
puts "Configfile: " + configfile + "." if options[:configfile]
puts "Database: " + database + "." if database
puts "Logfile: " + logfile + "."
puts "Connected to: " + server + ":" + port.to_s + "/#" + chan.gsub(/#/, '') + " as " + nick + "."
bot = Gros_Singe.new database, server, port, chan.gsub(/#/, ''), nick, pwd, logfile, verbose
bot.run

# EOF
