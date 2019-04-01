#!/usr/local/bin/ruby

require 'logger'

# https://github.com/dwyl/english-words
DICTIONARY_PATH = "./dictionaries/words_alpha.txt"

WHITE_LIST_PATH = "./white_list/rails.txt"
KEYWORDS_PATH = "./programming_keywords/rails.txt"
WRONG_WORDS_PATH = "./wrong_word_list.txt"
LOG_PATH = "./log/log"
PROGRESS_BAR_MAX_WIDTH = 100

OPTIONS = {
    :update => '--update',
    :type => '--type'
}

FILETYPE = {
    :ruby => 'rb',
    :javascript => 'js',
    :typescript => 'ts'
}

def progress_bar(i, max = 100)
  i = max if i > max
  percent = i * 100.0 / max
  bar_length = i * PROGRESS_BAR_MAX_WIDTH.to_f / max
  bar_str = ('#' * bar_length).ljust(PROGRESS_BAR_MAX_WIDTH)
  print "\r#{bar_str} #{'%0.1f' % percent}%"
end

def update_keyword_file(keywords)
  File.open(KEYWORDS_PATH, 'a') do |f|
      keywords.sort.each { |word| f.puts(word) }
  end
  @log.info "Updated now words to #{KEYWORDS_PATH}!"
end

def spell_check(file_path, keywords, white_list, cached_words, en_dict)
  found_counter = 0
  line_counter = 0
  @log.info "\n\n==> Checking file: #{file_path}"
  File.readlines(file_path).each do |line|
    line.chomp!
    line_counter += 1
    line.scan(/([A-Z][a-z]+|[a-zA-Z]{2,})/).flatten.each do |original_word|
      word = original_word.downcase
      next if keywords.include? (word)
      next if white_list.include? (word)
      next if cached_words.include? (word)
      if en_dict.include? (word)
        cached_words.push(word)
        next
      else
        found_counter += 1
        keywords.push(word) if @update_white_list_flag
        @log.info "Found wrong word in #{line_counter}: #{original_word}"
      end
    end
  end
  found_counter
end

def show_help_and_exit()
  puts "SOURCE CODE SPELL CHECK TOOL\n"
  puts "Usage: ruby spellcheck.rb [OPTION] [FILE NAME/ DIRECTORY NAME]\n"
  puts "Options:\n"
  puts "#{OPTIONS[:update]}: Update/Register programming keywords\n"
  puts "#{OPTIONS[:type]}:Specify the target file extension\n"
  puts "       Default file extension is ruby\n"
  exit
end

def load_libraries()
  en_dict = File.readlines(DICTIONARY_PATH).each { |l| l.chomp! }
  keywords = File.readlines(KEYWORDS_PATH).each { |l| l.chomp! }
  white_list = File.readlines(WHITE_LIST_PATH).each { |l| l.chomp! }
  return en_dict, keywords, white_list
end

def main()
  found_counter = 0
  @update_white_list_flag = false
  @file_type = FILETYPE[:ruby]
  @log = Logger.new(LOG_PATH)

  case ARGV.size
  when 1
      target = ARGV.first
  when 2
      show_help_and_exit if ARGV.first != OPTIONS[:update]
      target = ARGV.last
      @update_white_list_flag = true
  else
      show_help_and_exit
  end

  if File.file?(target)
      target_files = Dir[target]
  elsif File.directory?(target)
      target_files = Dir::glob("#{target}/**/*.#{@file_type}")
  else
      show_help_and_exit
  end

  # Start
  puts "Running...\n"
  en_dict, keywords, white_list = load_libraries
  cached_words = []
  checked_file_count = 0
  number_of_target_file = target_files.size
  target_files.each do |file|
    found_counter += spell_check(file, keywords, white_list, cached_words, en_dict)
    checked_file_count += 1
    progress_bar(checked_file_count, number_of_target_file)
  end
  update_keyword_file(keywords) if @update_white_list_flag
  puts "\nFound #{found_counter} wrong words!\n"
  puts "Open file #{LOG_PATH} to confirm!\n"
end
main
