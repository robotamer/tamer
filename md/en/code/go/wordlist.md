+++
title = "HDKeys Wordlist"
date = "2026-04-23 14:01:45"
description = "Creates a wordlist for bruteforce password recovery"
tags = ["password", "go", "code", "bitcoin", "hdkeys", "BIP39"]
+++

This cli command was created for [hdkeys_recover](./recover.html) but could be used otherwise 
hence the reason it is seperate.

Wordlist will create a password list from provided words by combining them in every which way possible.

1. copy the testdata folder anywhere you like.
2. modify the words.txt file with words you may have used to create your password. One word per line.
3. modify the setup.sh file (more about setup.sh below)
4. run hdkeys_wordlist
5. run hdkeys_recover
6. add more words to the list if it was unsuccessful 
7. run hdkeys_wordlist again (This will create a history file, designed to not check the same phrases over and over)
8. GOTO 5 until hdkeys_recover finds your password. (Good Luck)


### setup.sh

- `HDKEYS_TARGET_KEY` is a public key you know belongs to this account.

- `HDKEYS_PASSWORD_WORDS_SEPERATOR` is a key you may have added between words.

For example if your seperator is `@` and word are "one two six" 
it will create passwords like one@twosix onetwo@six etc.

- `HDKEYS_PASSWORD_MAX_LENGTH_WORDS` is to specify maximum number of words to combine
from your words.txt list to create a password `2` will create onetwo, one@two, onesix one@six etc. 

[hdkeys repo](https://github.com/gotamer/hdkeys/)
