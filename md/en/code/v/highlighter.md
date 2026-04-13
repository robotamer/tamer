+++
title = "Highlighter"
date = "2026-04-12 22:24:06"
description = "Highlighter is a code highlighter module for v, and a standalone cli tool."
tags = ["code", "v"]
+++

The shell command Highlighter will walk all sub direcories looking for html files.

As module, a lightweight, native V module to inject (Prism-compatible css) syntax highlighting into 
static HTML files at build time. No client-side JavaScript required.

## Features
- **Native V**: No external regex engine dependencies.
- **Fast**: High-speed scanner (FSM)
- **Prism Compatible**: Outputs standard `token` classes.
- **Auto-detection**: Automatically highlights blocks with `class="language-xxx"` or defaults to Bash.

## Usage

### As a CLI tool
```sh
v highlighter/cmd/main.v -o highlight
./highlight --verbose --force /var/www
```

### As a Module
```v
import highlighter

mut hl := highlighter.new_manager()
html_output := hl.highlight_html(markdown_generated_html)
```

## License
Distributed under the MIT License. See LICENSE for more information.

## Acknowledgements

- **Google Gemini**: For collaborating on the native V scanner logic and the conversion pipeline.
- **Lite XL**: For the comprehensive syntax definitions that power the language support.
- **Prism CSS**: For the beautiful themes and standardized token naming conventions.

