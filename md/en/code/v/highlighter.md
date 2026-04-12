+++
title = "Highlighter"
date = "2026-04-12 22:24:06"
description = "Highlighter is a code highlighter module for v"
tags = ["code", "v"]
+++

Highlighter is a code highlighter module for v, as well as a shell command.
The command will walk all sub direcories looking for html files.

```v
module highlighter

import json
import os

pub struct SyntaxDef {
pub:
	patterns []PatternItem
	symbols  map[string]string
}

pub struct PatternItem {
pub:
	pattern string
	@type   string @[json: type]
}

pub struct Manager {
pub mut:
	cache    map[string]SyntaxDef
	json_dir string
}

pub fn new_manager() Manager {
	return Manager{
		json_dir: os.join_path(os.dir(@FILE), 'lang_data')
	}
}

pub fn (mut m Manager) highlight_html(html string) string {
	parts := html.split('</code>')
	if parts.len <= 1 {
		return html
	}

	mut final_html := ''

	for i, part in parts {
		if i == parts.len - 1 {
			final_html += part 
			break
		}

		if part.contains('<code class="language-') {
			sub_parts := part.split('<code class="language-')
			mut before_code := sub_parts[0]

			lang_and_code := sub_parts[1]
			lang := lang_and_code.all_before('">')
			code := lang_and_code.all_after('">')

			syntax := m.get_syntax(lang) or {
				m.get_syntax('bash') or {
					final_html += part + '</code>'
					continue
				}
			}

			// Add the language class to the <pre> tag for the dark background
			// We look back at the 'before_code' and swap <pre> for <pre class="language-xxx">
			if before_code.ends_with('<pre>') {
				before_code = before_code.trim_string_right('<pre>') + '<pre class="language-${lang}">'
			}

			highlighted := m.apply_highlight(code, syntax)
			final_html += '${before_code}<code class="language-${lang}">${highlighted}</code>'
		} else {
			final_html += part + '</code>'
		}
	}

	return final_html
}

fn (mut m Manager) get_syntax(lang string) ?SyntaxDef {
	if lang in m.cache {
		return m.cache[lang]
	}
	path := os.join_path(m.json_dir, '${lang}.json')
	if !os.exists(path) {
		return none
	}
	data := os.read_file(path) or { return none }
	m.cache[lang] = json.decode(SyntaxDef, data) or { return none }
	return m.cache[lang]
}

fn (m Manager) apply_highlight(code string, syntax SyntaxDef) string {
	mut input := code.replace('&quot;', '"').replace('&lt;', '<').replace('&gt;', '>').replace('&amp;',
		'&')
	mut out := ''
	mut i := 0

	for i < input.len {
		// 1. Multiline Comments /* */
		if input.substr(i, input.len).starts_with('/*') {
			end_idx := input.index_after('*/', i) or { input.len }
			out += '<span class="token comment">${input[i..end_idx]}</span>'
			i = end_idx
			continue
		}

		// 2. Single Line Comments //
		if input.substr(i, input.len).starts_with('//') {
			end_idx := input.index_after('\n', i) or { input.len }
			out += '<span class="token comment">${input[i..end_idx]}</span>'
			i = end_idx
			continue
		}

		// 3. Strings "..." or '...'
		if input[i] == `"` || input[i] == `'` {
			quote := input[i]
			mut j := i + 1
			for j < input.len {
				if input[j] == `\\` && j + 1 < input.len {
					j += 2
					continue
				}
				if input[j] == quote {
					j++
					break
				}
				j++
			}
			out += '<span class="token string">${input[i..j]}</span>'
			i = j
			continue
		}

		// 4. Words (Keywords & Types)
		if input[i].is_letter() || input[i] == `_` {
			mut j := i
			for j < input.len && (input[j].is_alnum() || input[j] == `_`) {
				j++
			}
			word := input[i..j]
			if word in syntax.symbols {
				out += '<span class="token ${syntax.symbols[word]}">${word}</span>'
			} else {
				out += word
			}
			i = j
			continue
		}

		// 5. Numbers
		if input[i].is_digit() {
			mut j := i
			for j < input.len && (input[j].is_alnum() || input[j] == `.`) {
				j++
			}
			out += '<span class="token number">${input[i..j]}</span>'
			i = j
			continue
		}

		// 6. Punctuation and Operators
		// Add this before the "Everything else" step
		if input[i] in [`(`, `)`, `{`, `}`, `[`, `]`, `,`, `;`, `.`, `:`, `+`, `-`, `*`, `/`, `=`,
			`>`, `<`, `!`, `&`, `|`, `^`, `%`, `~`, `?`] {
			out += '<span class="token operator">${input[i].ascii_str()}</span>'
			i++
			continue
		}

		// 7. Everything else (fallback)
		out += input[i].ascii_str()
		i++
	}

	return out
}

```

