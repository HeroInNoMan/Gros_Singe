#!/usr/bin/ruby
# coding: utf-8
require 'open-uri'

class Daily_Quote

  def initialize
    @quotes = Array.new
  end

  def fetch_daily_quote
    open('http://www.citation-du-jour.fr/') do |f|
      f.each do |line|
        if line.include? '<blockquote lang="fr">'
          arr = line.split('<blockquote lang="fr">')
          @quotes << arr[1].split('</blockquote>')[0].gsub('&#039;', '’')
        end
      end
    end
  end
  
  def fetch_evene_quote
    open('http://www.evene.fr/citations/citation-jour.php') do |f|
      f.each do |line|
        if line.include? "data-text" and !(line.include? "La citation du jour")
          arr = line.split('data-text="')
          @quotes << arr[1].split('" >')[0].gsub('&#039;', '’')
        end
      end
    end
  end

  def fetch_joke(num)
    open('http://www.great-quotes.com/jokes/pg/' + num.to_s) do |f|
      f.each do |line|
        if line.include? '<a href="/joke/'
          return line.split('&quot;')[1].split('&quot;')[0].gsub('<br />', "\n")
        end
      end
    end
  end

  def fetch_movie_quote(num)
    open('http://www.moviequotes.com/archive/bynumber/' + num.to_s + '.html') do |f|
      f.each do |line|
        if line.include? '<B>Quote:</b> '
          @citation = line.split('<B>Quote:</b> ')[1].split('"It\'s Danny, sir."')[0].gsub('&#039;', '’').gsub('<BR><P>', '')
        end
        if line.include? '<B>Movie Title:</b> ' and @citation
          title = line.split('<B>Movie Title:</b> ')[1]
          return @citation + ' — ' + title
        end
      end
    end
  end
  
  def fetch_quotes
    begin
      fetch_evene_quote
      fetch_daily_quote
    rescue
      puts "Error while fetching quote"
    end
  end

  def load_more_quotes(nb)
    begin
      nb.times do
      @quotes << fetch_movie_quote(rand(25000))
      @quotes << fetch_joke(rand(31))
      end
    rescue
      puts "Error while fetching quote"
    end
  end

  def quote
    fetch_quotes if @quotes.empty?
    if @quotes.length < 10
      Thread.new{load_more_quotes(5)}
    end
    puts @quotes.length
    return @quotes.delete_at(rand(@quotes.length)) unless @quotes.empty?
  end
end
