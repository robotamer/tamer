+++
title = "Setup"
date = "2026-04-20 13:27:24"
description = "Installing and Setting up V on Linux"
tags = ["v", "code", "howto"]
+++

# V Language Setup

## Installing V
```sh
mkdir -p /opt/nix
chgrp users /opt/nix
cd /opt/nix
git clone --depth=1 https://github.com/vlang/v
cd v
make
which v
```

Add to ~/.profile
```sh
if command -v v &> /dev/null
then
    export VROOT=/opt/nix/lib/v
    export VMODULES=/opt/nix/lib/vmodules
fi
```

## Offline Documentation
### V Language Documentation
```sh
mkdir -p /opt/nix/lib/
cd /opt/nix/lib
git clone --branch generator --depth 1 https://github.com/vlang/docs v_docs_generator
v run .
mkdir -p /opt/nix/www
/opt/nix/www
ln -s ../lib/v_docs_generator/output vdocs
```
Access & bookmark: file:///opt/nix/www/vdocs/index.html

### V Module Documentation

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
Access & bookmark: file:///opt/nix/www/vlibs/index.html

