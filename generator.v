module main

import os
import time
import toml
import markdown
import json
import net.http.file

// --- CONFIGURATION ---
const site_url = 'http://tamer.pw'
const content_root = os.join_path_single(os.getwd(), 'md')
const output_root = os.getwd()
const supported_langs = ['en', 'tr']

// --- MODELS ---

struct Page {
	path_md  string
	modified string
mut:
	url         string
	content     string
	title       string
	date        string
	description string
	tags        []string
	lang        string
	is_blog     bool
	menu_html   string
}

struct SearchItem {
	t string @[json: 't'] // title
	u string @[json: 'u'] // url
	c string @[json: 'c'] // description/content
	g string @[json: 'g'] // tags (joined string)
}

struct Theme {
	author string = 'TaMeR'
}

// --- THEME METHODS ---

fn (t Theme) header(p Page, keywords string) string {
	println('/md/${p.url.replace('.html', '.md')}')
	markdown_file := os.join_path_single('/md', p.url.replace('.html', '.md'))
	markdown_link := if os.exists(markdown_file) {
		'<link rel="alternate" type="text/markdown" href="${markdown_file}">'
	} else {
		''
	}
	return '<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/w3.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/themes/prism-okaidia.min.css">
    <link rel="alternate" type="application/rss+xml" title="${p.lang} RSS Feed" href="/${p.lang}/rss.xml">
    ${markdown_link}

    <title>${p.title}</title>
    <meta name="author" content="${t.author}">
    <meta name="description" content="${p.description}">
    <meta name="keywords" content="${keywords}">
    <style>
        .tag-cloud { line-height: 2.5; padding: 40px; background: white; border-radius: 8px; text-align: center; }
        .tag-item { transition: transform 0.2s; display: inline-block; text-decoration: none; margin: 0 10px; }
        .tag-item:hover { transform: scale(1.1); color: #2196F3 !important; }
        .tag-badge { 
            font-size: 0.6rem; 
            vertical-align: top; 
            background: #e1e1e1; 
            color: #555; 
            padding: 2px 6px; 
            border-radius: 10px; 
            margin-left: 4px; 
        }
    </style>
</head>'
}

fn (t Theme) scripts(lang string) string {
	return '
    <script>
    let idx = [];
    async function init() { 
        try {
            const r = await fetch("/${lang}/search.json"); 
            idx = await r.json(); 
        } catch(e) { console.error("Search index failed", e); }
    }
    init();
    function search() {
        const q = document.getElementById("si").value.toLowerCase();
        const r = document.getElementById("sr");
        if (q.length < 2) { r.style.display="none"; return; }
        const m = idx.filter(i => 
            i.t.toLowerCase().includes(q) || 
            (i.g && i.g.toLowerCase().includes(q))
        ).slice(0, 5);
        if (m.length > 0) {
            r.innerHTML = m.map(i => `<a href="\${i.u}" class="w3-bar-item w3-button w3-white">\${i.t}</a>`).join("");
            r.style.display="block";
        } else { r.style.display="none"; }
    }
    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/prism.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/plugins/autoloader/prism-autoloader.min.js"></script>'
}

// --- PAGE METHODS ---

fn (mut p Page) build_menu(all_pages []Page) {
	current_dir := os.dir(p.url)
	mut links := [
		'<a href="/${p.lang}/index.html" class="w3-bar-item w3-button">${p.lang} Home</a>\n',
	]
	for sib in all_pages {
		if sib.lang == p.lang && os.dir(sib.url) == current_dir && sib.url != p.url {
			links << '<a href="/${sib.url}" class="w3-bar-item w3-button">${sib.title}</a>\n'
		}
	}
	p.menu_html = links.join('')
}

fn (p Page) render(t Theme) string {
	keywords := p.tags.join(', ')

	// Only create the date HTML if the date string isn't empty
	date_html := if p.date != '' {
		'<hr>
        <p class="w3-small w3-text-grey">
			First Created: ${p.date}<br>
			Last Modified: ${p.modified}
		</p>'
	} else if p.modified != '' {
		'<hr><p class="w3-small w3-text-grey">Last Modified: ${p.modified}</p>'
	} else {
		''
	}

	// 1. Description snippet (Added below title)
	desc_html := if p.description.len > 0 {
		'<p class="w3-large w3-text-grey"><i>${p.description}</i></p>'
	} else {
		''
	}

	// Create Tag Links for the bottom of the page
	mut tags_html := ''
	if p.tags.len > 0 && p.tags[0] != 'Uncategorized' {
		tags_html = '<div class="w3-padding-16"><p><b>Tags:</b> '
		for tag in p.tags {
			tags_html += '<a href="/${p.lang}/tags/${tag}.html" class="w3-tag w3-light-grey w3-small w3-margin-bottom" style="text-decoration:none">${tag}</a> '
		}
		tags_html += '</p></div>'
	}

	return '<!DOCTYPE html>
<html lang="${p.lang}">
${t.header(p, keywords)}
<body class="w3-light-grey">
    <div class="w3-bar w3-black w3-card">
        ${p.menu_html}
        <input type="text" id="si" class="w3-bar-item w3-input w3-right" placeholder="Search..." onkeyup="search()">
        <div id="sr" class="w3-dropdown-content w3-bar-block w3-card-4" style="right:0; top:40px; display:none; position:absolute; z-index:999;"></div>
    </div>
    <div class="w3-content" style="max-width:1400px; margin:20px auto">
        <div class="w3-container w3-white w3-card-4 w3-padding-32">
            <h1>${p.title}</h1>
            ${desc_html}
            ${p.content}
            ${tags_html}
            ${date_html}
        </div>
    </div>
    ${t.scripts(p.lang)}
</body>
</html>'
}

// --- CORE GENERATOR LOGIC ---

fn main() {
	if os.args.len < 2 {
		println('Usage: v run generator.v [run|serve|path/to/new.md]')
		return
	}

	// Detect if the user wants to create a new page directly
	if os.args[1].ends_with('.md') {
		create_new_page(os.args[1])
		return
	}

	match os.args[1] {
		'serve' {
			println('Serving at http://localhost:8080')
			file.serve(folder: output_root, on: ':8080')
		}
		'run' {
			generate_site('--force' in os.args)
		}
		'fixdate' {
			fix_dates()
		}
		else {
			println('Unknown command')
		}
	}
}

fn fix_dates() {
	println('Scanning content...')
	mut pages := scan_content()
	for p in pages {
		path := os.join_path(os.home_dir(), 'Public', 'tamer.pw', 'md', p.path_md)
		stat := os.stat(path) or {
			println('Could not stat ${path}')
			continue
		}
		println('${path}')
		println('mtime: ${stat.mtime}')
		if p.date.len > 1 {
			println('Toml Date: ${p.date}')
		}
	}
}

fn create_new_page(rel_path string) {
	full_path := os.join_path(content_root, rel_path)

	if os.exists(full_path) {
		println('Error: ${rel_path} already exists.')
		return
	}

	// Get current timestamp
	now := time.now()
	date_str := now.format_ss() // Example: 2026-04-09 23:27:00

	// Pre-format title from filename
	title := os.file_name(rel_path).replace('.md', '').replace('_', ' ').replace('-',
		' ').title()

	template := '+++
title = "${title}"
date = "${date_str}"
description = ""
tags = []
+++

# ${title}

'
	os.mkdir_all(os.dir(full_path)) or { panic(err) }
	os.write_file(full_path, template) or { panic(err) }
	println('Created: ${full_path}')
}

fn generate_site(force bool) {
	println('Scanning content...')
	mut pages := scan_content()

	mut lang_map := map[string][]Page{}
	for p in pages {
		lang_map[p.lang] << p
	}

	mut total_sitemap := ''
	for lang, mut lang_pages in lang_map {
		println('Processing ${lang}...')
		os.mkdir_all('${output_root}/${lang}') or {}
		os.mkdir_all('${output_root}/${lang}/tags') or {} // Ensure tags dir exists

		real_content := lang_pages.filter(!it.url.ends_with('index.html'))

		generate_search_index(lang, real_content)

		generate_tag_archive_pages(lang, real_content)
		generate_tag_cloud(lang, real_content)
		generate_tag_api(lang, real_content)

		generate_rss_feed(lang, real_content)

		total_sitemap += render_pages(mut lang_pages, force)

		// Create missing folder indices index.html
		generate_auto_indices(lang, lang_pages)
	}

	generate_global_assets(total_sitemap)
	println('Site generation complete.')
}

fn scan_content() []Page {
	mut pages := []Page{}
	files := os.walk_ext(content_root, '.md')
	for path in files {
		// Identify the file name
		file_name := os.file_name(path)

		// SKIP _index.md files (these are handled by generate_auto_indices)
		if file_name == '_index.md' {
			continue
		}

		rel := path.all_after(content_root).trim_left('/')
		lang := rel.all_before('/')
		if lang !in supported_langs {
			continue
		}

		raw := os.read_file(path) or { continue }
		if !raw.starts_with('+++') {
			continue
		}
		parts := raw.split('+++')
		if parts.len < 3 {
			continue
		}

		toml_doc := toml.parse_text(parts[1].trim_space()) or { continue }

		mut modified := get_field(toml_doc, 'modified')
		if modified.len < 2 {
			modified = time.unix(os.file_last_mod_unix(path)).format()
		}

		// Safely extract tags:
		// 1. .array() converts the TOML value to []toml.Any
		// 2. .as_strings() converts them to []string
		// 3. .filter removes the Null artifact text and empty strings
		mut raw_tags := toml_doc.value('tags').array().as_strings().filter(it != ''
			&& !it.contains('toml.Any') && !it.contains('toml.Null'))

		if raw_tags.len == 0 {
			raw_tags = ['Uncategorized']
		}

		pages << Page{
			path_md:     path
			modified:    modified
			url:         rel.replace('.md', '.html')
			lang:        lang
			title:       get_field(toml_doc, 'title')
			date:        get_field(toml_doc, 'date')
			description: get_field(toml_doc, 'description')
			tags:        raw_tags
			content:     markdown.to_html(parts[2].trim_space())
			is_blog:     rel.contains('/blog/')
		}
	}
	return pages
}

// Helper to get a field safely without the toml.Null artifact
fn get_field(doc toml.Doc, key string) string {
	// Use the Result guard '!'
	// If the key is missing or there's an error, it goes to the 'else'
	if val := doc.value_opt(key) {
		// val is now toml.Any
		str := val.string().trim_space()
		// Final safety check against the internal string representation
		if str.contains('toml.Null') || str.contains('toml.Any') {
			return ''
		}
		return str
	}
	return ''
}

fn render_pages(mut pages []Page, force bool) string {
	mut acc := ''
	theme := Theme{}
	for mut p in pages {
		out_path := os.join_path(output_root, p.url)

		// Only render if source is newer than output
		// We get source path by rebuilding from content_root
		src_path := os.join_path(content_root, p.url.replace('.html', '.md'))
		// Logic: If not forced AND file exists AND source hasn't changed, skip.
		if !force && os.exists(out_path) {
			if os.file_last_mod_unix(src_path) <= os.file_last_mod_unix(out_path) {
				acc += '<url><loc>${site_url}/${p.url}</loc><lastmod>${p.date}</lastmod></url>'
				continue
			}
		}

		p.build_menu(pages)
		os.mkdir_all(os.dir(out_path)) or { continue }
		os.write_file(out_path, p.render(theme)) or { continue }
		acc += '<url><loc>${site_url}/${p.url}</loc><lastmod>${p.date}</lastmod></url>'
	}
	return acc
}

fn generate_search_index(lang string, pages []Page) {
	data := pages.map(SearchItem{
		t: it.title
		u: '/${it.url}'
		c: it.description
		g: it.tags.join(' ')
	})
	os.write_file('${output_root}/${lang}/search.json', json.encode(data)) or {}
}

fn generate_rss_feed(lang string, pages []Page) {
	mut posts := pages.filter(it.is_blog)
	posts.sort(a.date > b.date)
	mut items := ''
	for p in posts {
		items += '<item><title>${p.title}</title><link>${site_url}/${p.url}</link><pubDate>${p.date}T00:00:00Z</pubDate></item>'
	}
	rss := '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>TaMeR ${lang}</title>${items}</channel></rss>'
	os.write_file('${output_root}/${lang}/rss.xml', rss) or {}
}

fn generate_tag_cloud(lang string, pages []Page) {
	mut counts := map[string]int{}
	for p in pages {
		for tag in p.tags {
			counts[tag]++
		}
	}

	mut max := 1
	for _, count in counts {
		if count > max {
			max = count
		}
	}

	mut cloud_html := '<div class="tag-cloud">'
	for tag, count in counts {
		size := 0.9 + (f64(count) / f64(max)) * 1.5
		// Link to the tag-specific index page
		cloud_html += '<a href="/${lang}/tags/${tag}.html" class="tag-item" style="font-size: ${size}rem;">
            ${tag}<span class="tag-badge">${count}</span>
        </a> '
	}
	cloud_html += '</div>'

	mut p := Page{
		title:   if lang == 'tr' { 'Etiket Bulutu' } else { 'Tag Cloud' }
		content: cloud_html
		lang:    lang
		url:     '${lang}/tags.html'
	}
	p.build_menu(pages)
	os.write_file(os.join_path(output_root, p.url), p.render(Theme{})) or {}
}

fn generate_global_assets(sitemap_urls string) {
	sitemap := '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://sitemaps.org">${sitemap_urls}</urlset>'
	os.write_file('${output_root}/sitemap.xml', sitemap) or {}
	os.write_file('${output_root}/robots.txt', 'User-agent: *\nSitemap: ${site_url}/sitemap.xml') or {}
}

fn generate_tag_archive_pages(lang string, pages []Page) {
	mut tag_map := map[string][]Page{}

	// Group pages by tag
	for p in pages {
		for tag in p.tags {
			tag_map[tag] << p
		}
	}

	theme := Theme{}
	for tag, related_pages in tag_map {
		mut list_html := '<h2>Posts tagged: ${tag}</h2><ul class="w3-ul w3-hoverable w3-white">'
		for rp in related_pages {
			list_html += '<li><a href="/${rp.url}" style="text-decoration:none">
				<span class="w3-large">${rp.title}</span><br>
				<span class="w3-small w3-text-grey">${rp.date}</span>
			</a></li>'
		}
		list_html += '</ul>'

		mut p := Page{
			title:   'Tag: ${tag}'
			content: list_html
			lang:    lang
			url:     '${lang}/tags/${tag}.html'
		}

		// Build menu and render
		p.build_menu(pages)
		out_path := os.join_path(output_root, p.url)
		os.mkdir_all(os.dir(out_path)) or { continue }
		os.write_file(out_path, p.render(theme)) or { continue }
	}
}

fn generate_auto_indices(lang string, all_pages []Page) {
	tag_cloud := if lang == 'tr' { 'Etiket Bulutu' } else { 'Tag Cloud' }

	// 1. Manually identify all directories by looking at the page URLs
	// and adding their parent paths recursively.
	mut unique_dirs := map[string]bool{}
	for p in all_pages {
		if p.lang != lang {
			continue
		}
		mut current := os.dir(p.url)
		for current != '.' && current != '' {
			unique_dirs[current] = true
			current = os.dir(current)
		}
	}

	// 2. Also check for "empty" folders that might have an _index.md
	// but no other .md files inside them.
	lang_root := os.join_path(content_root, lang)
	if os.exists(lang_root) {
		os.walk(lang_root, fn [mut unique_dirs] (path string) {
			if os.is_dir(path) {
				rel := path.all_after(content_root).trim_left(os.path_separator)
				if rel != '' {
					unique_dirs[rel] = true
				}
			}
		})
	}

	theme := Theme{}
	for dir_path, _ in unique_dirs {
		// Skip if manual index.md exists (handled by render_pages)
		if os.exists(os.join_path(content_root, dir_path, 'index.md')) {
			continue
		}

		index_src := os.join_path(content_root, dir_path, '_index.md')
		index_path := os.join_path(output_root, dir_path, 'index.html')

		mut title := 'Index of ${os.file_name(dir_path)}'
		mut content := ''
		mut description := ''

		if os.exists(index_src) {
			raw := os.read_file(index_src) or { '' }
			if raw.starts_with('+++') {
				parts := raw.split('+++')
				if parts.len >= 3 {
					doc := toml.parse_text(parts[1].trim_space()) or { toml.Doc{} }
					t := get_field(doc, 'title')
					if t != '' {
						title = t
					}
					description = get_field(doc, 'description')
					content = markdown.to_html(parts[2].trim_space())
				}
			} else {
				content = markdown.to_html(raw)
			}
		}

		// 3. Build List: Subfolders + Files
		mut list_html := '<ul class="w3-ul w3-hoverable w3-white w3-card w3-margin-top">'

		// Find child directories (subfolders)
		mut sub_dirs := []string{}
		for sd, _ in unique_dirs {
			if os.dir(sd) == dir_path && sd != dir_path {
				sub_dirs << sd
			}
		}
		sub_dirs.sort()
		for sd in sub_dirs {
			list_html += '<li><a href="/${sd}/index.html" class="w3-text-blue"><b>&bull; ${os.file_name(sd)}</b></a></li>'
		}

		// Find child pages
		mut dir_items := all_pages.filter(os.dir(it.url) == dir_path
			&& !it.url.ends_with('index.html'))
		if dir_path.contains('blog') {
			dir_items.sort(a.date > b.date)
		} else {
			dir_items.sort(a.title < b.title)
		}

		for itm in dir_items {
			date_label := if itm.date != '' {
				'<span class="w3-right w3-tiny w3-text-grey">${itm.date}</span> '
			} else {
				''
			}
			list_html += '<li>${date_label}<a href="/${itm.url}" style="text-decoration:none">${itm.title}</a></li>'
		}
		list_html += '<li><a href="/${lang}/tags.html" class="w3-text-blue"><b>&bull; ${tag_cloud}</b></a></li>'
		list_html += '</ul>'

		mut p := Page{
			title:       title
			description: description
			content:     content + list_html
			lang:        lang
			url:         '${dir_path}/index.html'
		}

		// p.build_menu(all_pages) // No menu for indexes
		os.mkdir_all(os.dir(index_path)) or { continue }
		os.write_file(index_path, p.render(theme)) or { continue }
	}
}

fn generate_tag_api(lang string, pages []Page) {
	mut counts := map[string]int{}
	for p in pages {
		for tag in p.tags {
			counts[tag]++
		}
	}

	// Create a simple map for the API
	api_path := os.join_path(output_root, lang, 'tags.json')
	os.write_file(api_path, json.encode(counts)) or {
		eprintln('Failed to write Tag API for ${lang}')
	}
	println('API Generated: ${lang}/tags.json')
}

