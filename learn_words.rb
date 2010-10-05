#!/usr/bin/env ruby

require 'rubygems'
require 'highline/import'

###############################################################
#               PROCESSING COMMAND LINE OPTIONS
###############################################################

# TODO: use optparser !!!

USAGE = <<-STR
Usage: learn_words FILE [--limit N] [--part M/K]
STR

def exit_with_usage(str = nil)
  puts USAGE
  puts("\n" + str) unless str.nil?
  exit 1
end

limit = 3
part = 1
parts_count = 1
words_file = nil

begin
  if (i = ARGV.index '--limit')
    ARGV.delete_at i
    limit = ARGV.delete_at i
    raise unless limit =~ /\d+/
    limit = limit.to_i
  end

  if (i = ARGV.index '--part')
    ARGV.delete_at i
    match = ARGV.delete_at(i).match /(\d+)\/(\d+)/
    part = match[1].to_i
    parts_count = match[2].to_i
    raise if parts_count == 0 or part == 0 or part > parts_count
  end

  raise if ARGV.count != 1
  words_file = ARGV.first
rescue
  exit_with_usage
end

###############################################################
#                        READING WORDS FILE
###############################################################

class Word
  attr_reader :orig, :trans, :variants_number
  attr_accessor :times_asked, :times_answered

  def initialize(orig, trans)
    @orig = orig
    @trans = trans.split "/"
    @variants_number = @trans.length
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

  def asked(answers)
    @times_asked += 1
    if answers.map( &:downcase ).sort == trans.map( &:downcase ).sort
      @times_answered += 1
      true
    else
      false
    end
  end

  def favour
    3*frequency + @times_asked
  end
end


words = []
begin
  open(words_file) do |file|
    file.lines.each do |line|
      next if line.strip.empty? # pass blank lines
      parts = line.split( "\t" ).map{ |x| x.strip }.delete_if{ |x| x.empty? }
      words << Word.new( parts[1], parts[0] ) unless line.start_with? '#'
    end
  end
rescue Exception => e
  exit_with_usage e.message
end

###############################################################
#                          PART WORDS
###############################################################

total_words_count = words.count

# words per part
wpp = words.count / parts_count
left = (part-1) * wpp
right = part * wpp
if part == parts_count
  # reminder to last part
  right = words.count
end
words = words[left...right]

###############################################################
#                        WELCOME MESSAGE
###############################################################

say %{ <%= color('             Learn Words !           ', GREEN+UNDERLINE) %>}
say %{ <%= color('made by Vladimir Parfinenko aka cypok', GREEN) %>}
say %{ <%= color(' some fixes by Ivan Novikov aka NIA  ', GREEN) %>}
STDOUT.write "\n"
say %{Current limit of learning is set to #{limit}}
STDOUT.write "\n"
say %{Note: if there are more than one variant,}
say %{separate them by "/" or enter one by one}
say %{Type "exit" if you want to quit}
STDOUT.write "\n"
say %{<%= color('Total #{total_words_count} words to learn', BLUE) %>}
if parts_count != 1
  say %{<%= color('Part #{part} of #{parts_count}: #{words.count} words to learn', BLUE) %>}
end
STDOUT.write "\n"

###############################################################
#                          MAIN LOOP
###############################################################

answers = []
word = nil
while true
  local_words = words.sort_by { rand }.find_all { |x| x.times_answered < limit }

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

  variants_msg = word.variants_number == 1 ? "" : " (#{word.variants_number} variants)"
  say %{< <%= color(%q[#{word.orig}], YELLOW) %>#{variants_msg}}

  answers = []
  begin
    while answers.length < word.variants_number and not answers.include? "exit"
      STDOUT.write "> "
      answers += STDIN.readline.split( "/" ).map( &:strip )
      break if answers.include? ""
    end
  rescue EOFError, Interrupt
    break
  end

  break if answers.include? "exit"

  if word.asked(answers)
    say %{< #{word.times_answered}/#{word.times_asked}\t<%= color('ok!', GREEN) %>}
  else
    verb = ( word.variants_number != 1 ) ? "were" : "was"
    right_strings = word.trans.map{|t| '"'+t+'"' }.join ", "
    say %{< #{word.times_answered}/#{word.times_asked}\t<%= color(%q[WRONG! Right #{verb} #{right_strings}!], BOLD+RED+UNDERLINE) %>}
  end
  STDOUT.write "\n"
end

###############################################################
#                          RESULTS
###############################################################

STDOUT.write "\n"
say %{<%= color('Your results:', GREEN) %>}
words = words.sort do |x, y|
  if x.frequency == y.frequency
    x.trans <=> y.trans
  else
    -( x.frequency <=> y.frequency )
  end
end
max_trans_length = words.map {|w| w.trans.join('/').length }.max
words.each do |word|
  freq = (word.frequency*100).to_i.to_s.rjust(3)
  trans = word.trans.join('/').ljust(max_trans_length, ' ')
  say %{<%= color(%q[#{freq}%  #{word.times_answered}/#{word.times_asked}   #{trans}  #{word.orig}], BLUE) %>}
end
