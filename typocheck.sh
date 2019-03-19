#!/bin/bash

DICTIONARY_PATH="./englishDictionary.txt"
USERD_WORDS_PATH="./listOfUsedWords.txt"
KEYWORDS_PATH="./programmingKeywords.txt"
WRONG_WORDS_PATH="./wrong_word_list.txt"

main() {
cat $WRONG_WORDS_PATH | grep -oE "^[a-z]+" | while read -ra words;
do
    for word in "${words[@]}";
    do
        spell_check $word;
    done;
done;
# done < wrong_typo_dictionary.txt
}

spell_check() {
    cat $DICTIONARY_PATH | grep -i $1 1>/dev/null || echo "not found $1";
}

main
