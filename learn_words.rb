#!/usr/bin/env ruby

require 'rubygems'
require 'highline/import'

if ARGV.size < 1 or ARGV.size > 2
  puts "Usage: learn_words.rb FILE [LEARNING_LIMIT]"
  exit 1
end

class Word
  attr_reader :orig, :trans
  attr_accessor :times_asked, :times_answered

  def initialize(orig, trans)
    @orig = orig
    @trans = trans
    @times_asked = 0
    @times_answered = 0
  end

  def frequency
    if @times_asked == 0
      0.0
    else
      @times_answered.to_f / @times_asked.to_f
    end
  end

  def asked(answered)
    right = answered.downcase == trans.downcase
    @times_asked += 1
    @times_answered += 1 if right
    right
  end

  def favour
    3*frequency + @times_asked
  end
end

words = []
open(ARGV[0]).lines.each do |line|
  next if line.strip.empty? # pass blank lines
  parts = line.split( "\t" ).map{ |x| x.strip }.delete_if{ |x| x.empty? }
  words << Word.new( parts[1], parts[0] ) unless line.start_with? '#'
end

LIMIT = (ARGV[1] || 3).to_i

say %{<%= color('<<<    Welcome to WordLearner !   >>>', GREEN+UNDERLINE) %>}
say %{<%= color('made by Vladimir Parfinenko aka cypok', GREEN) %>}
STDOUT.write "\n"
say %{Current limit of learning is set to #{LIMIT}}
say %{Type "exit" if you want to quit}
STDOUT.write "\n"

ans = ""
word = nil
while true
  local_words = words.sort_by { rand }.find_all { |x| x.times_answered < LIMIT }
  
  break if local_words.size == 0

  min_favour = local_words.map{ |x| x.favour}.min

  d = 0.25
  word_prev = word
  word = local_words.find { |x| x.favour <= (min_favour + d) }
  while word == word_prev && local_words.count > 1
    local_words = local_words.sort_by { rand }
    d += 0.25
    word = local_words.find { |x| x.favour <= (min_favour + d) }
  end

  say %{< <%= color(%q[#{word.orig}], YELLOW) %>}
  STDOUT.write "> "
  ans = STDIN.readline.strip

  break if ans == "exit"

  if word.asked(ans)
    say %{< #{word.times_answered}/#{word.times_asked}\t<%= color('ok!', GREEN) %>}
  else
    say %{< #{word.times_answered}/#{word.times_asked}\t<%= color(%q[WRONG! Right was "#{word.trans}"], RED+UNDERLINE) %>!}
  end
  STDOUT.write "\n"
end

STDOUT.write "\n"
say %{<%= color('Your results:', GREEN) %>}
words = words.sort do |x, y| 
  if x.frequency == y.frequency
    x.trans <=> y.trans
  else
    -( x.frequency <=> y.frequency )
  end
end
words.each do |word|
  say %{<%= color(%q[#{(word.frequency*100).to_i.to_s.rjust(3)}% #{word.times_answered}/#{word.times_asked}  #{word.trans.ljust(28, " ")}#{word.orig}], BLUE) %>}
end

