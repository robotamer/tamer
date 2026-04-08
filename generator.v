module main

import os
import toml
import markdown
import json
import net.http.file // the server

// Site Configuration
const site_url = 'http://tamer.pw'
const content_root = os.join_path_single(os.getwd(), 'md') //  '/home/tamer/Public/tamer.pw/md'
const output_root = os.getwd()

struct Page {
mut:
	url         string
	content     string
	title       string
	date        string
	description string
	tags        []string
	lang        string
	is_blog     bool
}

struct SearchItem {
	t string @[json: 't'] // title
	u string @[json: 'u'] // url
	c string @[json: 'c'] // description/content
}

fn main() {
	if os.args.len == 1 {
		eprintln('options: ${os.args[0]} run or serve')
		exit(1)
	} else {
		match os.args[1] {
			'serve' {
				// --- SERVE OPTION ---
				// Usage: v run main.v serve
				println('Starting local server at http://localhost:8080')
				println('Serving: ${output_root}')

				// This starts a static server
				file.serve(folder: output_root, on: ':8080')
				return
			}
			'run' {
				println('Creating html from markdown')
			}
			else {
				eprintln('options: ${os.args[0]} run or serve')
				exit(1)
			}
		}
	}

	mut lang_pages := map[string][]Page{}
	mut lang_tags := map[string]map[string]int{}

	// --- PASS 1: SCAN ---
	files := os.walk_ext(content_root, '.md')

	for path in files {
		rel := path.all_after(content_root).trim_left('/')
		lang := rel.all_before('/')
		if lang !in ['en', 'tr'] {
			continue
		}

		raw := os.read_file(path) or { continue }
		content := raw.trim_space()
		if !content.starts_with('+++') {
			continue
		}

		parts := content.split('+++')
		if parts.len < 3 {
			continue
		}

		toml_doc := toml.parse_text(parts[1].trim_space()) or { continue }

		mut tags := []string{}
		tags_any := toml_doc.value('tags')
		for t in tags_any.array() {
			tags << t.string()
		}

		// Markdown conversion (using 1-argument signature common in standard vlib)
		html_body := markdown.to_html(parts[2].trim_space())

		p := Page{
			url:         rel.replace('.md', '.html')
			lang:        lang
			title:       toml_doc.value('title').string()
			date:        toml_doc.value('date').string()
			description: toml_doc.value('description').string()
			tags:        tags
			content:     html_body
			is_blog:     rel.contains('/blog/')
		}

		if lang !in lang_pages {
			lang_pages[lang] = []Page{}
		}
		if lang !in lang_tags {
			lang_tags[lang] = map[string]int{}
		}

		for tag in p.tags {
			lang_tags[lang][tag]++
		}
		lang_pages[lang] << p
		println('Parsed: ${p.url}')
	}

	// --- PASS 2: RENDER & GENERATE ASSETS ---
	mut sitemap_urls := ''

	for lang, pages in lang_pages {
		// Identify unique directories for auto-indexing
		mut all_dirs := map[string]bool{}
		for p in pages {
			all_dirs[os.dir(p.url)] = true
		}

		// 1. Generate Search Index
		mut search_data := []SearchItem{}
		for p in pages {
			search_data << SearchItem{
				t: p.title
				u: '/${p.url}'
				c: p.description
			}
		}
		os.write_file('${output_root}/${lang}/search.json', json.encode(search_data)) or {}

		// 2. Generate RSS Feed
		mut rss_items := ''
		mut feed_posts := pages.filter(it.is_blog)
		feed_posts.sort(a.date > b.date)
		for fp in feed_posts {
			rss_items += '<item><title>${fp.title}</title><link>${site_url}/${fp.url}</link><description>${fp.description}</description><pubDate>${fp.date}T00:00:00Z</pubDate></item>/n'
		}
		rss_xml := '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>
			<title>TaMeR - ${lang.to_upper()}</title>
			<link>${site_url}/${lang}/</link>
			<description>Latest posts</description>
			${rss_items}
		</channel></rss>'
		os.write_file('${output_root}/${lang}/rss.xml', rss_xml) or {}

		// 3. Render HTML Pages
		for p in pages {
			current_dir := os.dir(p.url)
			parent_dir := os.dir(current_dir)

			// Contextual Navigation
			mut menu_links := []string{}
			menu_links << '<a href="/${lang}/index.html" class="w3-bar-item w3-button">Home</a>'
			for sib in pages.filter(os.dir(it.url) == current_dir && it.url != p.url) {
				menu_links << '<a href="/${sib.url}" class="w3-bar-item w3-button">${sib.title}</a>'
			}

			// Subfolder discovery
			mut seen_subs := map[string]bool{}
			for pot in pages {
				p_dir := os.dir(pot.url)
				if p_dir.starts_with(current_dir) && p_dir != current_dir {
					sub := p_dir.all_after(current_dir).trim('/').all_before('/')
					if sub != '' && sub !in seen_subs {
						menu_links << '<a href="/${current_dir}/${sub}/index.html" class="w3-bar-item w3-button w3-blue">📁 ${sub}</a>'
						seen_subs[sub] = true
					}
				}
			}

			// Back button and content
			back_btn := if current_dir != lang {
				'<a href="/${parent_dir}/index.html" class="w3-button w3-light-grey">&laquo; Back</a>'
			} else {
				''
			}
			body := '${back_btn}<h1>${p.title}</h1><div class="w3-justify">${p.content}</div><hr><p class="w3-small w3-text-grey">Last Modified: ${p.date}</p>'

			out_path := os.join_path(output_root, p.url)
			os.mkdir_all(os.dir(out_path)) or { continue }
			os.write_file(out_path, render_layout(p.title, body, menu_links.join(''),
				p.lang)) or { continue }

			sitemap_urls += '<url><loc>${site_url}/${p.url}</loc><lastmod>${p.date}</lastmod></url>'
		}

		// 4. Auto-generate Index pages if missing
		for dir_path, _ in all_dirs {
			// Check if a manual index.md exists in the source folder
			// dir_path is like "en/blog", so we look in content_root/en/blog/index.md
			manual_index_md := os.join_path(content_root, dir_path, 'index.md')

			if os.exists(manual_index_md) {
				println('Skipping auto-index for ${dir_path} (manual index.md found)')
				continue
			}

			// Proceed to generate auto-index.html
			index_path := os.join_path(output_root, dir_path, 'index.html')

			mut dir_items := pages.filter(os.dir(it.url) == dir_path)

			// Sort by date (descending) for blog paths
			if dir_path.contains('/blog') || dir_items.any(it.is_blog) {
				dir_items.sort(a.date > b.date)
			} else {
				dir_items.sort(a.title < b.title)
			}

			parent_dir := os.dir(dir_path)
			back_btn := if dir_path != lang {
				'<a href="/${parent_dir}/index.html" class="w3-button w3-light-grey">&laquo; Back</a>'
			} else {
				''
			}

			mut list := '<ul>'
			for itm in dir_items {
				list += '<li><a href="/${itm.url}">${itm.title}</a> <span class="w3-tiny w3-text-grey">(${itm.date})</span></li>'
			}
			list += '</ul>'

			os.write_file(index_path, render_layout('Index', '${back_btn}<h2>Folder: ${dir_path}</h2>${list}',
				'', lang)) or { continue }
		}
	}

	// 5. Global Sitemap
	sitemap := '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://sitemaps.org">${sitemap_urls}</urlset>'
	os.write_file('${output_root}/sitemap.xml', sitemap) or { panic(err) }

	// 6. Robots.txt
	robots_txt := 'User-agent: *
Allow: /
Sitemap: ${site_url}/sitemap.xml'
	os.write_file('${output_root}/robots.txt', robots_txt) or { panic(err) }

	println('Done! Check: ${output_root}')
}

fn render_layout(title string, content string, menu_html string, lang string) string {
	return '<!DOCTYPE html>
<html lang="${lang}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/w3.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/themes/prism-okaidia.min.css">
    <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="/${lang}/rss.xml">
    <title>${title}</title>
</head>
<body class="w3-light-grey">
    <div class="w3-bar w3-black w3-card">
        ${menu_html}
        <input type="text" id="si" class="w3-bar-item w3-input w3-right" placeholder="Search..." onkeyup="search()">
        <div id="sr" class="w3-dropdown-content w3-bar-block w3-card-4" style="right:0; top:40px; display:none; position:absolute; z-index:999;"></div>
    </div>
    <div class="w3-content" style="max-width:1400px; margin:20px auto">
        <div class="w3-container w3-white w3-card-4 w3-padding-32">${content}</div>
    </div>
    <script>
    let idx = [];
    async function init() { const r = await fetch("/${lang}/search.json"); idx = await r.json(); }
    init();
    function search() {
        const q = document.getElementById("si").value.toLowerCase();
        const r = document.getElementById("sr");
        if (q.length < 2) { r.style.display="none"; return; }
        const m = idx.filter(i => i.t.toLowerCase().includes(q)).slice(0, 5);
        if (m.length > 0) {
            r.innerHTML = m.map(i => `<a href="\${i.u}" class="w3-bar-item w3-button w3-white">\${i.t}</a>`).join("");
            r.style.display="block";
        } else { r.style.display="none"; }
    }
    </script>

	<!-- Prism.js Core -->
	<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/prism.min.js"></script>
	<!-- Autoloader: Automatically loads languages  -->
	<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.22.0/plugins/autoloader/prism-autoloader.min.js"></script>
</body>
</html>'
}

