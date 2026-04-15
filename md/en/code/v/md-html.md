+++
date = "2026-04-09T18:15:57+0300"
modified = "2026-04-15T23:32:44+0300"
title = "Static site generator"
description = "V-lang static site generator"
tags = ["v", "website", "code"]
+++

### AI Comment
The updated generator.v script provides a fully integrated V-lang static site generator featuring modular methods, /_index.md template support, an optional --force build flag, and enhanced tag management. The script ensures robust TOML parsing, includes automatic search index generation, and generates tag cloud/archive pages. For instructions and the latest code, the user can review the provided generator.v file.

```sh
Usage: v run generator.v [run|serve|path/to/new.md]

Example:
$ v run generator.v en/code/sh/commit.md
```

### Folder structure:
```
lang/blog
lang/categorie1
lang/categorie2
```

### Example:
```
en/blog
en/code/go
en/code/lua
en/code/js
en/linux/alpine
```

### File format
```Markdown
++
date = "2026-04-09T18:15:57+0300"
modified = ""
title = "Markdown to html website generator"
description = "Markdown website generator in V"
tags = ["v", "website"]
++
Markdown goes here

```

- [View this page in markdown](/md/en/code/v/md-html.md)
- [Repo](https://github.com/robotamer/tamer)
- [Docs](https://tamer.pw/en/code/v/md-html.html)

