#!/usr/bin/ruby
# coding: utf-8

require 'logger'
require 'socket'
require 'sqlite3'
require 'thread'
require 'KillTime'
require 'Daily_Quote'

class Gros_Singe

  def add_pattern(name, pattern)
    @db.execute( "INSERT INTO \"#{@patterns}\" VALUES (\"#{name}\", \"#{pattern}\")" ) unless pattern_exists(name)
  end

  def add_quote(key, text, quiet)
    unless quote_exists(key, text)
      @db.execute( "INSERT INTO \"#{@citations}\" VALUES (\"#{key}\", \"#{text}\")" )
      say_loud "C'est noté !" unless quiet
    end
  end

  def add_taquet(pattern, taquet, speak_type)
    @db.execute( "INSERT INTO \"#{@taquets}\" VALUES (\"#{pattern}\", \"#{taquet}\", \"#{speak_type}\")" )
  end

  def chut(chan, duree)
    # Fait taire le bot pendant un temps donné sur un chan.
  end

  def control_flood(chan)
    if @sender == @old_sender and chan == @channel
      @flood_counter+=1
    else @flood_counter = 0
    end
    if @flood_counter == 10
      @flood_counter = 0
      speak_answer("bavard")
    end
    @old_sender = @sender
  end

  def daily_quote
    say_loud @daily_quote.quote
  end

  def find_matching_patterns(msg)
    patterns = Array.new
    @db.execute("SELECT * FROM " + @patterns) do |row|
      if row[1] and /#{row[1]}/.match(msg)
        if row[0] == 'konami'
          trigger_pattern(row[0], row[1], 1)
          Process.exit
        end
        patterns << row
      end
    end
    return patterns
  end

  def handle_command(command)
    #    arg = command[/[^ ]+ +(.+)/, 1]
    case command
    when /^help$/
      whisper("!help : affiche la liste des commandes.")
      #       whisper("!refresh : synchronise à la base de données.")
      whisper("!fréquence <X> : insulte les gens toutes les X interventions en moyenne.")

      whisper("!fréquence : affiche la fréquence d'insulte actuelle.")
      #       whisper("!add <pattern_existant> <nouvelle_réplique> : ajoute une réplique à un pattern.")
      #       whisper("!addaction <pattern_existant> <nouvelle_réplique> : ajoute une action à un pattern (en /me).")
      #       whisper("!addpattern <nom> <pattern> : ajoute un pattern sur lequel on peut ajouter des réactions.")
      #       whisper("!patterns : affiche la liste des patterns existants.")
      whisper("!quotes : affiche la liste des tags disponibles.")
      whisper("!quote : affiche une citation au hasard.")
      whisper("!quote <tag> : affiche une citation tirée de <tag>.")
      whisper("!quote <tag> <citation> : ajoute la citation <citation> au tag <tag>.")
    when /^refresh$/
      say_loud "Synchronisation avec la base..."
      init_DB
      say_loud "Terminé !"
    when /^poing$/
      say_action "invite #{@sender} pour un week-end à la Fistinière."
    when /^bite$/
      say_action "fourre sa bite dans les fesses de #{@sender}."
      #     when /^addaction (\w*) (.*)$/
      #       if pattern_exists($1)
      #         add_taquet($1, $2, "action")
      #         say_loud "C'est noté !"
      #       end
      #     when /^add (\w*) (.*)$/
      #       if pattern_exists($1)
      #         add_taquet($1, $2, "loud")
      #         say_loud "C'est noté !"
      #       end
      #     when /^addpattern (\w*) (.*)$/
      #       unless pattern_exists($1)
      #         add_pattern($1, $2)
      #         say_loud "Pattern ajouté !"
      #       end
      #     when /^patterns$/
      #       list_patterns(sender)
    when /^fréquence$/
      say_loud "Fréquence des insultes : 1/#{@insult_rate}."
    when /^fréquence (\d+)$/
      freq = Integer($1)
      if freq > 100
        say_loud "Essaie moins de 100, pour voir ?"
      elsif freq == 0
        say_loud "Tu m’aimes pas, c’est ça ?"
      else
        @insult_rate = freq
        say_loud "Fréquence des insultes réglée à 1/#{$1}."
      end
    when /^réaction (\d+)$/
      freq = Integer($1)
      if freq > 10
        say_loud "Essaie moins de 10, pour voir ?"
      elsif freq == 0
        say_loud "Tu m’aimes pas, c’est ça ?"
      else
        @reactionProba = freq
        say_loud "Fréquence des réactions réglée à 1/#{$1}."
      end
    when /^quote$/
      random_quote
    when /^quote (\w+)$/
      quote($1)
    when /^quote (\w+) (.*)$/
      add_quote($1, $2, false)
    when /^quotes$/
      list_quotes(sender)
    when /^join #(\w+)$/
      join_channel $1
      @channels << $1
    when /^leave$/
      @channels.delete(@channel)
      leave_channel @channel
    when /^leave #(\w+)$/
      chan = $1
      if @channels.delete(chan)
        leave_channel chan
      end
    when /^repeat #(\w+) (\/me) (.*)/
      if "Duncan" == @sender
        repeat_action($1, $3)
      end
    when /^repeat #(\w+) (.*)/
      if "Duncan" == @sender
        repeat($1, $2)
      end
    end
  end

  def handle_privmsg(msg, query)
    case msg
    when /^!(.*)/
      handle_command $1
      return
    when /citation|quote/i
      daily_quote
      return
    when /^lo+l|mdr+$/i
      # TODO gérer les taquets en /me
      add_taquet("drole", @prev_msg, "loud")
      p "*** Phrase drôle apprise : « " + @prev_msg + " »."
    when /^(h[aeioué]){2,}$/i
      add_taquet("drole", @prev_msg, "loud")
      p "*** Phrase drôle apprise : « " + @prev_msg + " »."
    when /^(https?:\/\/[^ ]+)/i
      url = $1
      unless url =~ /pastis\.tristramg\.eu/
        add_quote("url", url, true)
        p "*** url apprise : « " + url + " »."
      end
    end
    rows = find_matching_patterns(msg)
    if !rows.empty?
      rows.each { |r| break if trigger_pattern(r[0], r[1], @reactionProba)}
    elsif msg =~ /^(.*\s)*(\w{6,8})(\s.*)*$/
      #       if rand(@insult_rate) == 0
      #         mot = $2
      #         if mot[0..0] =~ /[aeiouyéèïëöæœêâî]/i
      #           say_loud "C’est toi l’#{mot} !"
      #         else
      #           say_loud "C’est toi le #{mot} !"
      #         end
      #       end
    else
      unless trigger_pattern("drole", nil, @insult_rate)
        trigger_pattern("gratuit", nil, @insult_rate)
      end
    end
  end

  def init_DB(database)
    @db = SQLite3::Database.new database
    @patterns = "patterns"
    @citations = "citations"
    @taquets = "taquets"
  end

  def initialize(database, server, port, channel, nick, pwd, logFile, verbose)
    init_DB(database)
    @server = server
    @port = port
    @channel = channel
    @channels = Array.new [ channel ]
    @nick = nick
    @pwd = pwd
    @logger = Logger.new(logFile, 'weekly')
    @logger.level = Logger::DEBUG
    @verbose_mode = verbose
    @flood_counter = 0
    @insult_rate = 42
    @reactionProba = 5
    @sender=""
    @prev_line=""
    @prev_msg=""
    @socket = TCPSocket.new @server, @port
    @daily_quote = Daily_Quote.new
    @mutex = Mutex.new
    say "NICK #{@nick}"
    say "USER #{@nick} 0 * :NSSIrc user"
    @channels.each { |chan| say "JOIN #" + chan }
    #   say "PRIVMSG NICKSERV : IDENTIFY #{@pwd}"
    speak_answer("init")  if rand(@reactionProba) == 0
  end

  def join_channel(chan)
    say "JOIN #" + chan
  end

  def leave_channel(chan)
    say "PART #" + chan
  end

  def list_patterns
    liste = ""
    whisper("Liste des patterns :")
    @db.execute("SELECT key FROM \"#{@patterns}\"") do |row|
      liste << row[0] + " | "
    end
    whisper(liste)
  end

  def list_quotes
    total = 0
    whisper("Liste des films :")
    @db.execute("SELECT DISTINCT key FROM \"#{@citations}\"") do |row|
      count = @db.get_first_value("SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{row[0]}\"")
      whisper("#{row[0]} (#{count})")
      total = total + Integer(count)
    end
    whisper("* Total : #{total}")
  end

  def p(txt)
    puts txt if @verbose_mode
    @logger.info(txt)
  end

  def pattern_exists(pattern)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
    return 1 unless Integer(count) == 0
  end

  def quote(key)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
    unless Integer(count) == 0
      rows = @db.execute( "SELECT * FROM \"#{@citations}\" WHERE key = \"#{key}\"" )
      say_loud rows[rand(rows.size)][1]
    end
  end

  def quote_exists(key, text)
    count = @db.get_first_value( "SELECT COUNT (*) FROM \"#{@citations}\" WHERE key = \"#{key}\" AND text = \"#{text}\"")
    return 1 unless Integer(count) == 0
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

  def repeat(chan, msg)
    say "PRIVMSG ##{chan} :#{msg}"
  end

  def repeat_action(chan, msg)
    say "PRIVMSG ##{chan} :#{1.chr}ACTION #{msg}#{1.chr}"
  end

  def run
    @idle_count = 1
    total = @idle_count * 6111
    timeout = KillTime.new(total) {
      random_quote
      daily_quote
      @idle_count = @idle_count +1
    }

    while line = @socket.gets.strip

      # Gestion directe du ping (pas dans un thread)
      if line =~/^PING :(.*)/i
        sender = line.match(/^PING :(.*)/)
        @socket.puts "PONG #{sender}"
        next
      end

      p line

      next unless line =~ /PRIVMSG ([^ :]+) +:(.+)/

      timeout.reset
      @idle_count = 1

      #     next if @prev_line == line
      @prev_line = line

      m, @sender, target, msg = *line.match(/:([^!]*)![^ ].* +PRIVMSG ([^ :]+) +:(.+)/)

      if @nick == target
        Thread.new{handle_privmsg(msg, true); @prev_msg = msg}
      elsif target.start_with?('#')
        chan = target.split('#')[1]
        if @channels.include?(chan)
          control_flood(chan)
          @channel = chan
          Thread.new{handle_privmsg(msg, false); @prev_msg = msg}
        end
      end
    end
  end

  def say(msg)
    @mutex.synchronize{
      p "*** #{@nick}: " + msg
      @socket.puts msg
    }
  end

  def say_action(msg)
    msg.split("\n").each{|line|
      say "PRIVMSG ##{@channel} :#{1.chr}ACTION #{line}#{1.chr}"
    }
  end

  def say_loud(msg)
    msg.split("\n").each{|line|
      say "PRIVMSG ##{@channel} :#{line}"
    }
  end

  def speak_answer(pattern)
    if pattern_exists(pattern)
      rows = @db.execute( "SELECT * FROM \"#{@taquets}\" WHERE key = \"#{pattern}\"" )
      row = rows[rand(rows.size)]
      if row[2] == "action"
        say_action row[1].gsub("nick", @sender)
      elsif row[2] == "loud"
        say_loud row[1].gsub("nick", @sender)
      end
    end
  end

  def trigger_pattern(pattern_name, pattern, probability)
    log = "*** "
    if pattern
      log+="matched " + pattern_name + " : " + pattern + " "
    end
    loto = rand(probability)
    if loto == 0
      p log + "(answer triggered)"
      speak_answer(pattern_name)
      return true
    end
    p log + "(no answer triggered: " + loto.to_s + "/" + probability.to_s + ")"
    return false
  end

  def whisper(msg)
    say "PRIVMSG #{@sender}: #{msg}"
  end

end

# EOF
