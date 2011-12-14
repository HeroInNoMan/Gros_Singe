#!/usr/bin/ruby
# coding: utf-8
require 'socket'
require 'sqlite3'
require 'yaml'
require 'thread'
require 'Timeout'
require 'Daily_Quote'

class Gros_Singe
  
  def add_pattern(name, pattern)
    @db.execute( "INSERT INTO \"#{@patterns}\" VALUES (\"#{name}\", \"#{pattern}\")" ) unless pattern_exists(name)
  end

  def add_quote(key, text)
    @db.execute( "INSERT INTO \"#{@citations}\" VALUES (\"#{key}\", \"#{text}\")" )
    say_loud "Citation ajoutée !"
  end

  def add_taquet(pattern, taquet, speak_type)
    if pattern_exists(pattern)
      @db.execute( "INSERT INTO \"#{@taquets}\" VALUES (\"#{pattern}\", \"#{taquet}\", \"#{speak_type}\")" )
    end
  end

  def control_flood(sender, chan)
    if sender == @old_sender and chan == @channel
      @flood_counter+=1
    else @flood_counter = 0
    end
    if @flood_counter == 10
      @flood_counter = 0
      speak_answer("bavard", sender)
    end
    @old_sender = sender
  end

  def daily_quote
    puts 'daily_quote...'
    @daily_quote.fetch_quotes # marche pas
    say_loud @daily_quote.get_quote
    #     say_loud %x[bash fetch_quote.rb]
    puts 'done!'
  end

  def find_pattern(msg, sender)
    @db.execute( "SELECT * FROM \"#{@patterns}\"" ) do |row|
      if row[1] and /#{row[1]}/.match(msg)
          return row
      end
    end
    return nil
  end

  def handle_command(line)
    m, sender, target, command = *line.match(/:([^!]*)![^ ].* +PRIVMSG ([^ :]+) +:!(.+)/)
    if @nick == target
      whisper(sender, "je parle pas en privé !")
    elsif target.start_with?('#')
      chan = target.split('#')[1]
      if @channels.include?(chan)
        control_flood(sender, chan)
        @channel = chan
        arg = command[/[^ ]+ +(.+)/, 1]
        case command
        when /^help$/
          whisper(sender, "!help : affiche la liste des commandes.")
          # whisper(sender, "!refresh : synchronise à la base de données.")
          whisper(sender, "!fréquence <X> : insulte les gens toutes les X interventions en moyenne.")
          whisper(sender, "!fréquence : affiche la fréquence d'insulte actuelle.")
          #       whisper(sender, "!add <pattern_existant> <nouvelle_réplique> : ajoute une réplique à un pattern.")
          #       whisper(sender, "!addaction <pattern_existant> <nouvelle_réplique> : ajoute une action à un pattern (en /me).")
          #       whisper(sender, "!addpattern <nom> <pattern> : ajoute un pattern sur lequel on peut ajouter des réactions.")
          #       whisper(sender, "!patterns : affiche la liste des patterns existants.")
        whisper(sender, "!quotes : affiche la liste des tags disponibles.")
          whisper(sender, "!quote : affiche une citation au hasard.")
          whisper(sender, "!quote <tag> : affiche une citation tirée de <tag>.")
          whisper(sender, "!quote <tag> <citation> : ajoute la citation <citation> au tag <tag>.")
        when /^refresh$/
          say_loud "Synchronisation avec la base..."
          init_DB
          say_loud "Terminé !"
        when /^bite$/
          say_action "fourre sa bite dans les fesses de #{sender}."
          #       when /^addaction (\w*) (.*)$/
          #         if pattern_exists($1)
          #           add_taquet($1, $2, "action")
          #           say_loud "C'est noté !"
          #         end
          #       when /^add (\w*) (.*)$/
          #         if pattern_exists($1)
          #           add_taquet($1, $2, "loud")
          #           say_loud "C'est noté !"
          #         end
          #       when /^addpattern (\w*) (.*)$/
          #         unless pattern_exists($1)
          #           add_pattern($1, $2)
          #           say_loud "Pattern ajouté !"
          #         end
          #       when /^patterns$/
          #         list_patterns(sender)
        when /^fréquence$/
          say_loud "Fréquence des insultes : 1/#{@insult_rate}."
        when /^fréquence (\d+)$/
          freq = Integer($1)
          if freq > 100
            say_loud "Nan mais là c'est beaucoup trop. Je vais plus jamais parler maintenant ! Je refuse. Essaye encore."
          end
          if freq == 0
            say_loud "Ok, je ferme ma gueule. Mais je reviendrai tas de punaises."
          end
          @insult_rate = freq
          say_loud "Fréquence des insultes initialisée à 1/#{$1}."
          puts @insult_rate
        when /^quote$/
          random_quote
        when /^quote (\w*)$/
          quote($1)
        when /^quote (\w*) (.*)$/
          add_quote($1, $2)
        when /^quotes$/
          list_quotes(sender)
        when /^join #(\w*)$/
          join_channel $1
          @channels << $1
        when /^leave #(\w*)$/
          if @channels.delete($1)
            leave_channel $1
          end
        when /^focus #(\w*)$/
          if @channels.include?($1)
            focus_channel $1
          end
        end
      end      
    end
  end
  
  def handle_privmsg(line)
    m, sender, target, msg = *line.match(/:([^!]*)![^ ].* +PRIVMSG ([^ :]+) +:(.+)/)
    
    if @nick == target
      whisper(sender, "J'parle pas aux connards, et sûrement pas en privé.")
    elsif target.start_with?('#')
      chan = target.split('#')[1]
      if @channels.include?(chan)
        control_flood(sender, chan)
        @channel = chan
        case msg
        when /^(.*\s)*citation du jour(\s.*)*$/i
          daily_quote
          return
        when /^(.*\s)*(\w{6,8})(\s.*)*$/i
          if rand(@insult_rate) == 0
            mot = $2
            if mot[0..0] =~ /[aeiouyéèïëöæœêâî]/i
              say_loud "C'est toi l'#{mot} !"
            else
              say_loud "C'est toi le #{mot} !"
            end
          end
          return
        when /#{@nick}/i
          trigger_pattern("hilight", nil, sender, 1)
          return
        else
          trigger_pattern("gratuit", nil, sender, @insult_rate)
        end
        row = find_pattern(msg, sender)
        if(row)
          trigger_pattern(row[0], row[1], sender, @reactionProba)
          return
        end
      end
    end
  end
  
  def init_DB
    @db = SQLite3::Database.new "gros_singe.db"
    @patterns = "patterns"
    @citations = "citations"
    @taquets = "taquets"
  end
  
  def initialize(server, port, channel, nick, pwd)
    @flood_counter = 0
    @insult_rate = 42
    @reactionProba = 4
    @server = server
    @port = port
    @channel = channel
    @channels = Array.new [ @channel, "testouille" ]
    @nick = nick
    @pwd = pwd
    @socket = TCPSocket.new server, port
    @daily_quote = Daily_Quote.new
    @mutex = Mutex.new
    say "NICK #{@nick}"
    say "USER #{@nick} 0 * :NSSIrc user"
    @channels.each { |chan| say "JOIN #" + chan }
#   say "PRIVMSG NICKSERV : IDENTIFY #{@pwd}"
    init_DB
    speak_answer("init", "")  if rand(@reactionProba) == 0
  end

  def is_command(line)
    return line =~ /PRIVMSG ([^ :]+) +:!(.+)/
  end

  def is_privmsg(line)
    return line =~ /PRIVMSG ([^ :]+) +:(.+)/
  end

  def join_channel(chan)
    say "JOIN #" + chan
  end

  def leave_channel(chan)
    say "PART #" + chan
  end

  def list_patterns(sender)
    liste = ""
    whisper(sender, "Liste des patterns :")
    @db.execute("SELECT key FROM \"#{@patterns}\"") do |row|
      liste << row[0] + " | "
    end
    whisper(sender, liste)
  end

  def list_quotes(sender)
    total = 0
    whisper(sender, "Liste des films :")
    @db.execute("SELECT DISTINCT key FROM \"#{@citations}\"") do |row|
      count = @db.get_first_value("SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{row[0]}\"")
      whisper(sender, "#{row[0]} (#{count})")
      total = total + Integer(count)
    end
    whisper(sender, "* Total : #{total}")
  end

  def pattern_exists(pattern)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
    unless Integer(count) == 0
      return 1
    end
  end

  def quote(key)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
    unless Integer(count) == 0
      rows = @db.execute( "SELECT * FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
      say_loud rows[rand(rows.size)][1]
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

  def run
    timeout = Timeout.new(6111) { random_quote }

    while line = @socket.gets.strip

      # Gestion du ping
      # On le traite directement, sans passer par un thread
      if line =~/^PING :(.*)/
        sender = line.match(/^PING :(.*)/)
        @socket.puts "PONG #{sender}"
        next
      end
      puts line
      
      timeout.reset

      # Gestion du flood
      next if @old_line == line
      @old_line = line

      # Gestion des commandes du bot
      if is_command line
        t = Thread.new{handle_command(line)}
        next
      end

      # Gestion des messages utilisateurs
      if is_privmsg line
        t = Thread.new{handle_privmsg(line)}
        next
      end
    end
  end

  def say(msg)
    @mutex.synchronize{
      puts "#{@nick}: " + msg
      @socket.puts msg
    }
  end

  def say_action(msg)
    say "PRIVMSG ##{@channel} :#{1.chr}ACTION #{msg}#{1.chr}"
  end

  def say_loud(msg)
    say "PRIVMSG ##{@channel} :#{msg}"
  end

  def speak_answer(pattern, sender)
    if pattern_exists(pattern)
      rows = @db.execute( "SELECT * FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
      row = rows[rand(rows.size)]
      if row[2] == "action"
        say_action row[1].gsub("nick", sender)
      elsif row[2] == "loud"
        say_loud row[1].gsub("nick", sender)
      end
    end
  end

  def trigger_pattern(pattern_name, pattern, sender, probability)
    log = "*** "
    if(pattern)
      log+="matched " + pattern_name + " : " + pattern + " "
    end
    loto = rand(probability)
    if loto == 0
      puts log + "(answer triggered)"
      speak_answer(pattern_name, sender)
    else
      puts log + "(no answer triggered: " + loto.to_s + "/" + probability.to_s + ")"
    end
  end
  
  def whisper(nick, msg)
    say "PRIVMSG #{nick} :#{msg}"
  end

end 

conf = YAML.parse_file('gros_singe.yaml')
bot = Gros_Singe.new conf["server"].value, conf["port"].value, conf["channel"].value, conf["nick"].value, conf["pwd"].value
bot.run

# EOF
