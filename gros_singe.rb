#!/usr/bin/ruby
# coding: utf-8
require 'socket'
require 'sqlite3'

class Gros_Singe
  def initialize(server, port, channel, nick)
    @flood_counter = 0
    @insult_rate = 40
    @server = server
    @port = port
    @channel = channel
    @nick = nick
    @socket = TCPSocket.new server, port
    ["NICK #{@nick}", "USER #{@nick} 0 * :NSSIrc user", "JOIN ##{@channel}", "PRIVMSG NICKSERV : IDENTIFY ***"].each { |command|
      say command
    }
    init_DB
    speak_answer("init", "")  if rand(@insult_rate) == 0
  end

  def say(msg)
    puts "#{@nick} : " + msg
    @socket.puts msg
  end

  def say_loud(msg)
    say "PRIVMSG ##{@channel} :#{msg}"
  end

  def say_action(msg)
    say "PRIVMSG ##{@channel} :#{1.chr}ACTION #{msg}#{1.chr}"
  end

  def is_command(line)
    return line =~ /PRIVMSG ([^ :]+) +:!(.+)/
  end

  def is_privmsg(line)
    return line =~ /PRIVMSG ([^ :]+) +:(.+)/
  end

  def control_flood(sender)
    if sender == @old_sender
      @flood_counter+=1
    else @flood_counter = 0
    end
    if @flood_counter == 10
      @flood_counter = 0
      speak_answer("bavard", sender)
    end
    @old_sender = sender
  end

  def init_DB
    @db = SQLite3::Database.new "gros_singe.db"
    @patterns = "patterns"
    @citations = "citations"
    @taquets = "taquets"
  end

  def find_pattern(msg, sender)
    @db.execute( "SELECT * FROM \"#{@patterns}\"" ) do |row|
      if msg =~ Regexp.compile(row[1], Regexp::IGNORECASE)
        puts "match :"
        puts row[1]
        puts row[0]
        speak_answer(row[0], sender) if rand(3) == 0
        return 1
      end
    end
  end

  def pattern_exists(pattern)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
    unless Integer(count) == 0
      return 1
    end
  end


  def speak_answer(pattern, sender)
    if pattern_exists(pattern)
      rows = @db.execute( "SELECT * FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
      row = rows[rand(rows.size)]
      if row[2] == "action"
        say_action row[1].gsub("nick", sender)
      else
        say_loud row[1].gsub("nick", sender)
      end
    end
  end

  def add_pattern(name, pattern)
    @db.execute( "INSERT INTO \"#{@patterns}\" VALUES (\"#{name}\", \"#{pattern}\")" ) unless pattern_exists(name)
  end

  def list_patterns
    liste = ""
    say_loud "Liste des patterns :"
    @db.execute("SELECT key FROM \"#{@patterns}\"") do |row|
      liste << row[0] + " | "
    end
    say_loud liste
  end

  def add_taquet(pattern, taquet, speak_type)
    if pattern_exists(pattern)
      @db.execute( "INSERT INTO \"#{@taquets}\" VALUES (\"#{pattern}\", \"#{taquet}\", \"#{speak_type}\")" )
    end
  end

  def random_quote
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@citations}\"" )
    unless Integer(count) == 0
      rows = @db.execute( "SELECT * FROM \"#{@citations}\"" )
      quote = rows[rand(rows.size)]
      if @last_quote == quote[1]
        random_quote
      else
        @last_quote = quote[1]
        say_loud "#{quote[1]} (#{quote[0]})"
      end
    end
  end

  def quote(key)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
    unless Integer(count) == 0
      rows = @db.execute( "SELECT * FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
      say_loud rows[rand(rows.size)][1]
    end
  end

  def add_quote(key, text)
    @db.execute( "INSERT INTO \"#{@citations}\" VALUES (\"#{key}\", \"#{text}\")" )
    say_loud "Citation ajoutée !"
  end

  def list_quotes
    total = 0
    say_loud "Liste des films :"
    @db.execute("SELECT DISTINCT key FROM \"#{@citations}\"") do |row|
      count = @db.get_first_value("SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{row[0]}\"")
      say_loud "#{row[0]} (#{count})"
      total = total + Integer(count)
    end
    say_loud "* Total : #{total}"
  end

  def handle_command(line)
    m, sender, target, command = *line.match(/:([^!]*)![^ ].* +PRIVMSG ([^ :]+) +:!(.+)/)
    if target == "##{@channel}"
      control_flood sender
      arg = command[/[^ ]+ +(.+)/, 1]
      case command
      when /^help$/
        say_loud "!help : affiche la liste des commandes."
        #             say_loud "!refresh : synchronise à la base de données."
        say_loud "!fréquence <X> : insulte les gens toutes les X interventions en moyenne."
        say_loud "!fréquence : affiche la fréquence d'insulte actuelle."
        say_loud "!add <pattern_existant> <nouvelle_réplique> : ajoute une réplique à un pattern."
        say_loud "!addaction <pattern_existant> <nouvelle_réplique> : ajoute une action à un pattern (en /me)."
        say_loud "!addpattern <nom> <pattern> : ajoute un pattern sur lequel on peut ajouter des réactions."
        say_loud "!patterns : affiche la liste des patterns existants."
        say_loud "!quotes : affiche la liste des films disponibles."
        say_loud "!quote : affiche une citation au hasard."
        say_loud "!quote <film> : affiche une citation tirée de <film>."
        say_loud "!quote <film> <citation> : ajoute la citation <citation> au film <film>."
      when /^refresh$/
        say_loud "Synchronisation avec la base..."
        init_DB
        say_loud "Terminé !"
      when /^bite$/
        say_action "fourre sa bite dans les fesses de #{sender}."
      when /^addaction (\w*) (.*)$/
        if pattern_exists($1)
          add_taquet($1, $2, "action")
          say_loud "C'est noté !"
        end
      when /^add (\w*) (.*)$/
        if pattern_exists($1)
          add_taquet($1, $2, "loud")
          say_loud "C'est noté !"
        end
      when /^addpattern (\w*) (.*)$/
        unless pattern_exists($1)
          add_pattern($1, $2)
          say_loud "Pattern ajouté !"
        end
      when /^patterns$/
        list_patterns
      when /^fréquence$/
        say_loud "Fréquence des insultes : #{@insult_rate}."
      when /^fréquence (\d+)$/
        freq = Integer($1)
        if freq > 100
          say_loud "Nan mais là c'est beaucoup trop. Je vais plus jamais parler maintenant ! Je refuse. Essaye encore."
        end
        if freq == 0
          say_loud "Ok, je ferme ma gueule. Mais je reviendrai tas de punaises."
        end
        @insult_rate = freq
        say_loud "Fréquence des insultes initialisée à #{$1}."
        puts @insult_rate
      when /^quote$/
        random_quote
      when /^quote (\w*)$/
        quote($1)
      when /^quote (\w*) (.*)$/
        add_quote($1, $2)
      when /^quotes$/
        list_quotes
      end
    end      
  end

  def handle_privmsg(line)
    m, sender, target, msg = *line.match(/:([^!]*)![^ ].* +PRIVMSG ([^ :]+) +:(.+)/)    
    if target == "##{@channel}"
      control_flood sender
      unless find_pattern(msg, sender)
        case msg
        when /^(.*\s)*(\w{7})(\s.*)*$/i
          say_loud "C'est toi le #{$2} !" if rand(@insult_rate) == 0
        when /^(.* )?#{@nick}[:)]?( .*)?$/i
          speak_answer("hilight", sender) if rand(3) == 0
        else speak_answer("gratuit", sender) if rand(@insult_rate) == 0
        end
      end
    end
  end

  def run
    while line = @socket.gets.strip

      #Si on a ruby1.8 (ou avant), y'a pas la méthode encoding
      if "bite".respond?_to(:encoding)
        line.force_encoding("UTF-8")
        #Si la longueur en octets et en chars est la même, ptet qu'on était en latin
        if line.length == line.bytesize
          line.force_encoding("ISO-8859-9")
          line.encode!("UTF-8")
        end
      end

      puts line

      # Gestion du ping
      # On le traite directement, sans passer par un thread
      if line =~/^PING :(.*)/
        sender = line.match(/^PING :(.*)/)
        say "PONG #{sender}"
        next
      end

      # Gestion du flood
      next if @old_line == line
      @old_line = line

      # Gestion des commandes du bot
      if is_command line
        t = Thread.new{handle_command(line)}
        t.join
        next
      end
      # Gestion des messages utilisateurs
      if is_privmsg line
        t = Thread.new{handle_privmsg(line)}
        t.join
        next
      end
    end
  end
end 

chan_arg = ARGV[0]
nick_arg = ARGV[1]
chan_arg = "***" unless chan_arg
nick_arg = "Gros_Singe" unless nick_arg
bot = Gros_Singe.new 'irc.rezosup.org', '6667', "#{chan_arg}", "#{nick_arg}"
bot.run

# EOF
