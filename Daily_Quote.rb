#!/usr/bin/ruby
# coding: utf-8
require 'open-uri'

class Daily_Quote

  def initialize
    @quotes = Array.new
  end
  
  def fetch_quotes
    open('http://www.evene.fr/citations/citation-jour.php') do |f|
      f.each do |line|
        if line.include? "data-text" and !(line.include? "La citation du jour")
          arr = line.split('data-text="')
          @quotes << arr[1].split('" >')[0].gsub('&#039;', '’')
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
