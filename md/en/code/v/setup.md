+++
title = "V Language Setup"
date = "2026-04-20 13:27:24"
description = "Installing and Setting up V on Linux"
tags = ["v", "code", "howto"]
+++

I use as a gereral practice /opt/nix/{bin,cfg,etc,lib,scr,srv,sys,var,tmp} as location where I install software manually.
You may change that.

#### Documentation Practice:
- # run as root
- $ run as user

## Installing V

Installing bleeding edge code:
```sh
VROOT=/opt/nix/lib/v
VMODULES=/opt/nix/lib/vmodules

# mkdir -p /opt/nix/lib
# chgrp users /opt/nix
$ cd /opt/nix/lib
$ git clone --depth=1 https://github.com/vlang/v
$ cd $VROOT
$ make
$ which v
$ v version
```

Switching V to a stable release code:
```sh
$ cd $VROOT
$ git tag -l # find the latest tag release as of writting it is 0.5.1
$ git checkout 0.5.1
$ v self -prod
$ v version
```

_____________________________________________________
Add following to ~/.profile
```sh
if command -v v &> /dev/null
then
    export VROOT=/opt/nix/lib/v
    export VMODULES=/opt/nix/lib/vmodules
fi
```
_____________________________________________________
## Offline Documentation

Now we will create the V languade, and V module documentation for offline use.

### V Language Documentation
```sh
mkdir -p /opt/nix/lib/
cd /opt/nix/lib
git clone --branch generator --depth 1 https://github.com/vlang/docs v_docs_generator
v run .
mkdir -p /opt/nix/www
cd /opt/nix/www
ln -s ../lib/v_docs_generator/output vdocs
```
**Access & bookmark:** file:///opt/nix/www/vdocs/index.html
_____________________________________________________
### V Module Documentation

Create following script in /opt/nix/scr and run it.
```sh
$ cat generate_vlib_docs.sh 
#!/bin/sh

set -eu

# 1. Setup workspace
WORKSPACE=/tmp/vdoc_workspace
VDOCS=/opt/nix/www/vlibs

# 1.1 cleanup
if [ -L "$WORKSPACE/vlib" ]
then
	unlink $WORKSPACE/vlib
	unlink $WORKSPACE/vmodules
fi

if [ -d "$WORKSPACE" ]
then
	rm -rf $WORKSPACE
fi

# 2. Symlink
mkdir -p $WORKSPACE
ln -s $VROOT/vlib $WORKSPACE/vlib
ln -s $VMODULES $WORKSPACE/vmodules

# 3 Generate vdocs
rm -rf $VDOCS
v doc -m -f html -readme -o $VDOCS $WORKSPACE

# 4. Cleanup
unlink $WORKSPACE/vlib
unlink $WORKSPACE/vmodules
rm -rf $WORKSPACE
```
**Access & bookmark:** file:///opt/nix/www/vlibs/index.html

