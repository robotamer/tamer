+++
title = "HDKeys Recover"
date = "2026-04-23 14:24:01"
description = "Recover bitcoin seed password"
tags = ["password", "go", "code", "bitcoin", "hdkeys","BIP39"]
+++

### Recover will run a wordlist against a Mnemonic seed phrase, and a public key to find a lost/forgotten BIP39 password.

[hdkeys repo](https://github.com/gotamer/hdkeys/)

> If you are here because you lost your password. **I will help you**; don't worry if all this sounds too complicated.
> First remember **Not your keys, not your coins**. Don't share your mnemonic keys with anyone, including me. 
> Don't panic, don't hurry, your coins are save as long as you don't share your mnemonic keys!
> We will make this work for you, so that you can recover your password on your own computer, with internet turned off.

Before you can use "HDKeys Recover" you must have a wordlist of passwords. 
I have created a [wordlist generator](./wordlist.html), which should work for most passwords.

### installation

You need go installed!

Following will create hdkeys hdkeys_recover hdkeys_wordlist in to the ./bin folder
```sh
git clone https://github.com/gotamer/hdkeys
cd hdkeys
./make.sh build
ls ./bin
bin/hdkeys_recover -h
```

### setup.sh
Once you have generated your wordlist. Modify your setup.sh file to include following.

- **HDKEYS_MNEMONIC** you should know what that is.
- **HDKEYS_TARGET_KEY** is a public key you know belongs to this account. You can find this in your wallet, on the blockchain, or just ask the person you received the coins from.

setup.sh example
```sh
export HDKEYS_MNEMONIC='tree matrix federal video roof sniff great wheel valve rib daughter public'
export HDKEYS_TARGET_KEY="3CN3xb1NFmUFZGQMMvS68jDcoi19RqC19S"
```

Then in a shell run
```sh
hdkeys_recover
```

