#!/usr/bin/ruby
# coding: utf-8
require 'open-uri'

class Daily_Quote

  def initialize
    @quotes = Array.new
  end
  
  def fetch_quotes
    puts 1
    open('http://www.evene.fr/citations/citation-jour.php') do |f|
      puts 2
      f.each do |line|
        puts 3
        if line.include? "data-text" and !(line.include? "La citation du jour")
          puts 4
          arr = line.split('data-text="')
          puts 5
          @quotes << arr[1].split('" >')[0].gsub('&#039;', '’')
          puts 6
        end
      end
    end
    open('http://www.citation-du-jour.fr/') do |f|
      f.each do |line|
        if line.include? '<blockquote lang="fr">'
      arr = line.split('<blockquote lang="fr">')
          @quotes << arr[1].split('</blockquote>')[0].gsub('&#039;', '’')
        end
      end
    end
  end

  def get_quote
    # @quotes.each { |item| pp item }
    return @quotes[rand(@quotes.length)]
  end
end
