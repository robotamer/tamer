+++
title = "commit.sh"
date = "2026-04-09 23:37:27"
description = "A script to git add, git tag, git commit, and git push. Including auto incrementing tags with semantic versioning."
tags = ["sh", "bash", "code", "git"]
+++

Optionaly creates a meta data file.

[The script is in a Github Gist](https://gist.github.com/robotamer/35ef24fdd326626b7f5d8e9571e133c5)

```sh
NAME 
    commit - git add, tag, commit & push
SYNOPSIS
    commit OPTION...
DESCRIPTION
    A script to git add, git tag, git commit, and git push. 
    Including auto incrementing tags with semantic versioning.
    Optionaly creates a meta data file
OPTIONS
    -m, --message (optional only in dry run mode)
        Specify a commit message
    -i, --increment [major, minor, patch] (optional patch is the default)
        Specify the type of version increment, alternatives: -v or -r 
    -v, --version (optional) (default: -i patch)
        Specify a version. Use semantic versioning (v0.2.3). 
    -r, --recreate (optional)
        Recreate the last tag, if it already exists, by deleting and retagging
    -n, --nopush ( optional) (default for -i patch)
        Do not push the tag to the remote even if it is created.
    -d, --dryrun (optional)
        Perform a dry run; no commit, tag, push ...
    -t, --metadata (optional)
        Create metadata.toml file
    -p, --print (optional)
        Print git info
EXAMPLES
	commit.sh -i minor -m 'updated something'
    commit.sh -v v2.0.0 -m 'code for freedom'
    commit.sh -i patch -n -m "-i patch is the default!"
    commit.sh -r -d 
```

# Embeded Gist:

<script src="https://gist.github.com/robotamer/35ef24fdd326626b7f5d8e9571e133c5.js"></script>
