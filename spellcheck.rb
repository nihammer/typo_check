#!/usr/local/bin/ruby

TARGET_FILE = "./target.rb"
DICTIONARY_PATH = "./en_dic.txt"
WHITE_LIST_PATH = "./white_list/rails.txt"
KEYWORDS_PATH = "./programming_keywords/rails.txt"
WRONG_WORDS_PATH = "./wrong_word_list.txt"

def update_key_word_list(new_key_words)
  File.open(KEYWORDS_PATH, 'a') do |f|
    new_key_words.each { |word| f.puts(word) }
  end
end

def spell_check(file_path, keywords, new_key_words, white_list, cached_words, english_dictionary_words)
  found_counter = 0
  line_counter = 0
  puts "\n\n==> Checking file: #{file_path}"
  File.readlines(file_path).each do |line|
    line.chomp!
    line_counter += 1
    line.scan(/([A-Z][a-z]+|[a-zA-Z]{2,})/).flatten.each do |original_word|
      word = original_word.downcase
      next if keywords.include? (word)
      next if white_list.include? (word)
      next if cached_words.include? (word)
      if english_dictionary_words.include? (word)
        # puts "Saved #{word} into cached!"
        cached_words.push(word)
        next
      else
        found_counter += 1
        new_key_words.push(word)
        puts "Found wrong word in #{line_counter}: #{original_word}"
      end
    end
  end
  found_counter
end

def show_help()
  puts "Wrong params!\n"
  puts "Usage: ruby spellcheck.rb [file/directory name]\n\n"
  exit
end

def main()
  found_counter = 0
  show_help if ARGV.size == 0
  target_files = File.file?(ARGV.first) ? Dir[ARGV.first] : Dir["#{ARGV.first}/*"]
  english_dictionary_words = File.readlines(DICTIONARY_PATH).each { |l| l.chomp! }
  keywords = File.readlines(KEYWORDS_PATH).each { |l| l.chomp! }
  white_list = File.readlines(WHITE_LIST_PATH).each { |l| l.chomp! }
  cached_words = []
  new_key_words = []
  target_files.each do |file|
    found_counter += spell_check(file, keywords, new_key_words, white_list, cached_words, english_dictionary_words)
  end
  puts "Found #{found_counter} wrong words!"
  update_key_word_list(new_key_words)
end
main
