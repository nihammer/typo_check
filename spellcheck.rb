#!/usr/local/bin/ruby

require 'logger'

# https://github.com/dwyl/english-words
DICTIONARY_PATH = "./dictionaries/words_alpha.txt"

WHITE_LIST_PATH = "./white_list"
PRIVATE_NAMES_PATH = "./private_names/names.txt"
COMPUTER_VOCABULARY_PATH = "./computer_vocabulary"
PROG_KEYWORDS_PATH = "./programming_keywords/rails.txt"
LOG_PATH = "./log/log"
PROGRESS_BAR_MAX_WIDTH = 100

OPTIONS = {
  :update => '--update',
  :type => '--type'
}

FILETYPE = {
  :ruby => 'rb',
  :javascript => 'js',
  :typescript => 'ts',
  :php => 'php',
  :html => 'html',
  :plaintext => 'txt',
  :graphql => 'graphql'
}

LIB_DICRECTORY_NAME = {
  :ruby => '\gem',
  :rails => '\gem',
  :javascript => '\node_modules',
  :cakephp => '\vendor',
  :laravel => '\vendor'
}

ERROR_MESSAGE = {
  :filetype_not_exist => 'Filetype does not exist!',
  :param_not_exist => 'Parameter does not exist: ',
  :no_file => 'There is no file to scan!'
}

def progress_bar(i, max = 100)
  i = max if i > max
  percent = i * 100.0 / max
  bar_length = i * PROGRESS_BAR_MAX_WIDTH.to_f / max
  bar_str = ('#' * bar_length).ljust(PROGRESS_BAR_MAX_WIDTH)
  print "\r#{bar_str} #{'%0.1f' % percent}%"
end

def update_keyword_file(keywords)
  File.open(PROG_KEYWORDS_PATH, 'a') do |f|
    keywords.sort.each { |word| f.puts(word) }
  end
  @log.info "Updated now words to #{PROG_KEYWORDS_PATH}!"
end

#TODO
# Scan and create white list
# from library of a language/framework
def scan_lib
end

#TODO
# combinedlowercasecheck(default:don't need to check now)
def combined_lower_case_check(combined_word)
  false
end

#TODO
# PascalCaseCheck(default:don't need to check now)
def pascal_case_check(combined_word)
  false
end

#TODO
# camelCaseCheck(default:don't need to check now)
def camel_case_check(combined_word)
  false
end

# Return False if found any NEW wrong word
def check_spell_combination_word(word)
  return true if camel_case_check(word)
  return true if pascal_case_check(word)
  return true if combined_lower_case_check(word)
  false
end

# Return False if found any NEW wrong word
def check_spell_of_the_word(original_word, wrong_words_found=[])
  word = original_word.downcase
  # Check from cache data
  return true if @cached_words.include? (word)
  return true if @keywords.include? (word)
  return true if @cv_words.include? (word)
  return true if @private_names.include? (word)
  return true if @white_list.include? (word)
  if wrong_words_found.include? (word)
    @found_counter += 1
    return true
  end

  # Check from dictionary files
  if @en_dict.include? (word)
    @cached_words.push(word)
    return true
  end

  return true if check_spell_combination_word(original_word)

  false
end

def spell_check(file_path)
  wrong_words_found_in_file = []
  line_counter = 0
  File.readlines(file_path).each do |line|
    line.chomp!
    line_counter += 1
    # line.scan(/([A-Z][a-z]+|[a-zA-Z]{2,})/).flatten.each do |original_word|
    line.scan(/(A?[A-Z][a-z]{1,}|[a-z]{1,}|[A-Z]{1,})/).flatten.each do |original_word|
      # For case: "ABeautifulDay" => "BeautifulDay"
      original_word[0] = '' if original_word =~ /A[A-Z][a-z]{1,}/

      next if check_spell_of_the_word(original_word, wrong_words_found_in_file)

      # Found wrong word
      @found_counter += 1
      wrong_words_found_in_file.push(original_word.downcase)
      @log.info "\n\n==> Checking file: #{file_path}" if wrong_words_found_in_file.size == 1
      @keywords.push(original_word.downcase) if @update_white_list_flag
      @log.info "Found wrong word in line #{line_counter}: #{original_word}"
    end
  end
end

def show_help_and_exit(message=nil)
  puts "\nError: #{message}\n\n\n" if message
  puts "SOURCE CODE SPELL CHECK TOOL\n"
  puts "Usage: ruby spellcheck.rb [OPTION] [FILE NAME/ DIRECTORY NAME]\n"
  puts "Options:\n"
  puts "#{OPTIONS[:update]}: Update/Register programming keywords\n"
  puts "#{OPTIONS[:type]}: Specify the target file extension\n"
  puts "       Default file extension is ruby\n"
  puts "  Filetype list:\n"
  FILETYPE.keys.each { |filetype| puts "    #{filetype}\n" }
  puts "\n"
  exit
end

def load_data_from_files(path, file_type=FILETYPE[:plaintext])
  data = []
  if File.file?(path)
    data = File.readlines(path).each { |l| l.chomp! }
  elsif File.directory?(path)
    files = Dir::glob("#{path}/**/*.#{file_type}")
    files.each do |file|
      File.open(file, "r") do |f|
        f.each { |l| data.push(l.chomp) }
      end
    end
  end
  data
end

def load_libraries
  en_dict = load_data_from_files(DICTIONARY_PATH)
  keywords = load_data_from_files(PROG_KEYWORDS_PATH)
  cv_words = load_data_from_files(COMPUTER_VOCABULARY_PATH)
  private_names = load_data_from_files(PRIVATE_NAMES_PATH)
  white_list = load_data_from_files(WHITE_LIST_PATH)
  [en_dict, keywords, cv_words, private_names, white_list]
end

def process_arguments
  target_files = []
  show_help_and_exit if ARGV.empty?

  if ARGV.include? (OPTIONS[:type])
    index = ARGV.index(OPTIONS[:type])
    show_help_and_exit ERROR_MESSAGE[:filetype_not_exist] unless FILETYPE.keys.map(&:to_s).include? (ARGV[index+1])
    @file_type = ARGV[index+1]
  end

  ARGV.each_with_index do |argument, index|
    case argument
    when OPTIONS[:update]
      @update_white_list_flag = true
    when OPTIONS[:type]
      next
    else
      if File.file?(argument)
        target_files += Dir[argument]
      elsif File.directory?(argument)
        target_files += Dir::glob("#{argument}/**/*.#{@file_type}")
      else
        next if FILETYPE.keys.map(&:to_s).include? (argument)
        show_help_and_exit "#{ERROR_MESSAGE[:param_not_exist]}#{argument}"
      end
    end
  end
  show_help_and_exit ERROR_MESSAGE[:no_file] if target_files.empty?

  target_files
end

def main
  @found_counter = 0
  @update_white_list_flag = false
  @file_type = FILETYPE[:ruby]
  @log = Logger.new(LOG_PATH)

  target_files = process_arguments

  # Start
  puts "Running...\n"
  @en_dict, @keywords, @cv_words, @private_names, @white_list = load_libraries
  @cached_words = []
  checked_file_count = 0
  number_of_target_file = target_files.size
  target_files.each do |file|
    spell_check(file)
    checked_file_count += 1
    progress_bar(checked_file_count, number_of_target_file)
  end
  update_keyword_file(@keywords) if @update_white_list_flag
  puts "\nFound #{@found_counter} wrong words!\n"
  puts "Open file #{LOG_PATH} to confirm!\n"
end
main
