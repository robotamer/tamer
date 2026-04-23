+++
title = "Nix File System Hierarchy"
date = "2022-04-20 13:27:24"
description = "The way it should be"
tags = ["linux", "nix"]
+++

1. **bin** binaries 
1. **cfg** config files (only text files no binaries)
1. **etc** etcetera files that don't fit in any other category (only text files no binaries)
1. **lib** libraries for binaries such as xx.so files
1. **scr** script files such as sh, bash, perl, lua (only text files no binaries)
1. **srv** server, data for backround running services such as mail, web servers, vcs repos (git) 
1. **sys** system and distribution specific files such as devices, drivers, and kernel feature 
1. **tmp** temporary files, they are deleted when the system goes down.
1. **usr** user read-only user data
1. **var** variable data files, such as log files, mail spools etc 

```sh
NIX=/opt/nix
mkdir -p $NIX
cd $NIX
mkdir -p bin cfg etc lib scr srv sys tmp usr var
```
