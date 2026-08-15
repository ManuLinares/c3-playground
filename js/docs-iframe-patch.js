// js/docs-iframe-patch.js
// Injected into the stdlib docs srcdoc iframe to patch navigation, observe file:// links,
// and render the floating source-code viewer panel.

(function () {
	// 1. Override history.pushState/replaceState and window.open
	// These throw "insecure operation" inside a srcdoc iframe.
	history.pushState = function (state, title, url) {
		if (url) {
			var hash = url.indexOf('#') >= 0 ? url.slice(url.indexOf('#')) : '';
			if (hash) location.hash = hash;
		}
	};
	history.replaceState = function () {};
	window.open = function (url) {
		if (!url || url.startsWith('file://') || url.startsWith('http')) return;
	};

	// 2. Rewrite file:// links immediately upon DOM insertion
	function patchFileLinks(root) {
		var links = root.querySelectorAll ? root.querySelectorAll('a[href]') : [];
		if (root.tagName === 'A' && root.href && root.href.startsWith('file://')) links = [root];
		Array.prototype.forEach.call(links, function (a) {
			if (!a.href.startsWith('file://')) return;
			var path = a.href.replace(/^file:\/\//, '');
			if (!path.startsWith('/')) path = '/' + path;
			a.dataset.filepath = path;
			a.setAttribute('href', '#');
			a.removeAttribute('target');
		});
	}

	document.addEventListener('DOMContentLoaded', function () { patchFileLinks(document.body); });

	var mo = new MutationObserver(function (mutations) {
		mutations.forEach(function (m) {
			m.addedNodes.forEach(function (n) {
				if (n.nodeType === 1) patchFileLinks(n);
			});
		});
	});
	mo.observe(document.documentElement, { childList: true, subtree: true });

	// 3. Click handler for file links
	document.addEventListener('click', function (e) {
		var a = e.target.closest('[data-filepath]');
		if (!a) return;
		e.preventDefault();
		e.stopPropagation();
		var path = a.dataset.filepath;
		var lineMatch = a.textContent.match(/:(\d+)/);
		var line = lineMatch ? parseInt(lineMatch[1], 10) : 0;
		window.parent.postMessage({ type: 'read_stdlib_file', path: path, line: line }, '*');
	}, true);

	// 4. Keyboard ESC handling
	document.addEventListener('keydown', function (e) {
		if (e.key !== 'Escape') return;
		var sv = document.getElementById('__sv');
		if (sv && sv.style.display !== 'none') {
			e.stopPropagation();
			sv.style.display = 'none';
			return;
		}
		setTimeout(function () {
			var inputs = document.querySelectorAll('input');
			var anyFilled = Array.prototype.some.call(inputs, function (i) { return i.value.length > 0; });
			if (!anyFilled) window.parent.postMessage({ type: 'close-stdlib-docs' }, '*');
		}, 30);
	}, true);

	// 5. Message listener from parent for file contents
	window.addEventListener('message', function (e) {
		if (e.data && e.data.type === 'stdlib_file_content') {
			showSrc(e.data.path, e.data.content, e.data.line, e.data.error);
		}
	});

	// 6. Floating source viewer panel
	var stylesInjected = false;
	function injectStyles() {
		if (stylesInjected) return;
		stylesInjected = true;
		var style = document.createElement('style');
		style.textContent = `
			#__sv {
				position: fixed;
				inset: 0;
				z-index: 99999;
				background: rgba(0, 0, 0, 0.82);
				display: flex;
				align-items: center;
				justify-content: center;
			}
			.__sv-panel {
				width: 92%;
				max-width: 900px;
				height: 80vh;
				background: #0d1117;
				border: 1px solid #30363d;
				border-radius: 10px;
				display: flex;
				flex-direction: column;
				overflow: hidden;
				box-shadow: 0 20px 56px rgba(0, 0, 0, 0.8);
			}
			.__sv-header {
				display: flex;
				align-items: center;
				gap: 8px;
				padding: 8px 14px;
				background: #161b22;
				border-bottom: 1px solid #30363d;
				min-width: 0;
			}
			.__sv-path {
				font-family: monospace;
				color: #58a6ff;
				font-size: 0.82em;
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
				flex: 1;
			}
			.__sv-close {
				background: none;
				border: none;
				color: #8b949e;
				font-size: 1.4em;
				cursor: pointer;
				padding: 2px 7px;
				border-radius: 4px;
				flex-shrink: 0;
				line-height: 1;
				transition: color 0.15s, background-color 0.15s;
			}
			.__sv-close:hover {
				color: #f0f6fc;
				background: rgba(255, 255, 255, 0.1);
			}
			.__sv-body {
				flex: 1;
				overflow: auto;
				margin: 0;
				padding: 8px 0;
				font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
				font-size: 0.78em;
				line-height: 1.6;
				color: #e6edf3;
				background: #0d1117;
				tab-size: 4;
			}
			.__sv-line {
				display: flex;
			}
			.__sv-line.highlight {
				background: #1c2a3a;
			}
			.__sv-lineno {
				color: #4b5563;
				min-width: 4ch;
				text-align: right;
				padding-right: 16px;
				user-select: none;
				flex-shrink: 0;
			}
		`;
		document.head.appendChild(style);
	}

	function showSrc(path, content, line, error) {
		injectStyles();
		var sv = document.getElementById('__sv');
		if (!sv) {
			sv = document.createElement('div');
			sv.id = '__sv';
			sv.innerHTML = '<div class="__sv-panel">'
				+ '<div class="__sv-header">'
				+ '<span id="__sv_path" class="__sv-path"></span>'
				+ '<button id="__sv_x" class="__sv-close" title="Close (\u00d7)" aria-label="Close">\u00d7</button>'
				+ '</div>'
				+ '<pre id="__sv_pre" class="__sv-body"></pre>'
				+ '</div>';
			document.body.appendChild(sv);
			document.getElementById('__sv_x').onclick = function () { sv.style.display = 'none'; };
			sv.addEventListener('click', function (ev) {
				if (ev.target === sv || (ev.target.closest && ev.target.closest('.type-link'))) {
					sv.style.display = 'none';
				}
			});
		}
		sv.style.display = 'flex';
		document.getElementById('__sv_path').textContent = path + (line ? ':' + line : '');
		var pre = document.getElementById('__sv_pre');
		if (error || !content) {
			pre.textContent = error || 'File not found in VFS';
			return;
		}
		var lines = content.split('\n');
		var hlFn = typeof highlightC3 === 'function' ? highlightC3 : (typeof window.highlightC3 === 'function' ? window.highlightC3 : null);
		pre.innerHTML = lines.map(function (l, i) {
			var n = i + 1;
			var lineHtml = hlFn ? hlFn(l) : l.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
			var hlClass = n === line ? '__sv-line highlight' : '__sv-line';
			return '<div id="__L' + n + '" class="' + hlClass + '">'
				+ '<span class="__sv-lineno">' + n + '</span>'
				+ '<span>' + lineHtml + '</span></div>';
		}).join('');
		if (line) {
			var el = document.getElementById('__L' + line);
			if (el) el.scrollIntoView({ block: 'center' });
		}
	}
})();
