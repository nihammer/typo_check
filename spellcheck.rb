#!/usr/local/bin/ruby

TARGET_FILE = "./target.rb"
DICTIONARY_PATH = "./en_dic.txt"
WHITE_LIST_PATH = "./white_list.txt"
KEYWORDS_PATH = "./programming_keywords.txt"
WRONG_WORDS_PATH = "./wrong_word_list.txt"

def main()
  line_counter = 0
  found_counter = 0
  english_dictionary_words = File.readlines(DICTIONARY_PATH).each { |l| l.chomp! }
  keywords = File.readlines(KEYWORDS_PATH).each { |l| l.chomp! }
  white_list = File.readlines(WHITE_LIST_PATH).each { |l| l.chomp! }
  cached_words = []
  File.readlines(TARGET_FILE).each do |line|
    line.chomp!
    line_counter += 1
    line.scan(/([A-Z][a-z]+|[a-zA-Z]{2,})/).flatten.each do |word|
      temp_word = word.downcase
      next if keywords.include? (temp_word)
      next if white_list.include? (temp_word)
      next if cached_words.include? (temp_word)
      if english_dictionary_words.include? (temp_word)
        # puts "Saved #{temp_word} into cached!"
        cached_words.push(temp_word)
        next
      else
        found_counter += 1
        puts "Found wrong word in #{line_counter}: #{word}"
      end
    end
  end
  puts "Found #{found_counter} wrong words!"
end
main
