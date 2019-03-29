#!/usr/local/bin/ruby

require 'logger'

DICTIONARY_PATH = "./dictionaries/en_dic.txt"
WHITE_LIST_PATH = "./white_list/rails.txt"
KEYWORDS_PATH = "./programming_keywords/rails.txt"
WRONG_WORDS_PATH = "./wrong_word_list.txt"
LOG_PATH = "./log/log"

OPTIONS = {
    :update => '--update',
    :type => '--type'
}

FILETYPE = {
    :ruby => 'rb',
    :javascript => 'js',
    :typescript => 'ts'
}

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

  en_dict, keywords, white_list = load_libraries
  cached_words = []
  target_files.each do |file|
    found_counter += spell_check(file, keywords, white_list, cached_words, en_dict)
  end
  update_keyword_file(keywords) if @update_white_list_flag
  puts "Found #{found_counter} wrong words!\n"
  puts "Open file #{LOG_PATH} to confirm!\n"
end
main
