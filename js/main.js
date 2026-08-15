// js/main.js
import { EXAMPLES_MANIFEST, fetchExampleCode, prefetchAllExamples } from './examples.js';
import { setupMonacoC3, parseCompilerErrors, registerEditorCommands } from './monaco-c3.js';
import {
	preloadCompilerAssets,
	executeCompilerTask,
	queryCompilerVersion,
	queueDocgenUpdate,
	triggerStdlibDocgenHtml,
	readStdlibFile,
	openStdlibDoc,
	getDocsIframePatchJs
} from './compiler.js';
import { getSharedCode, createShareLink } from './share.js';

// DOM Elements
const outputEl = document.getElementById("output");
const statusEl = document.getElementById("status");
const statusTooltipEl = document.getElementById("statusTooltip");
const compileBtn = document.getElementById("compileBtn");
const clearBtn = document.getElementById("clearBtn");
const copyBtn = document.getElementById("copyBtn");
const saveBtn = document.getElementById("saveBtn");
const shareBtn = document.getElementById("shareBtn");
const exampleSelect = document.getElementById("exampleSelect");
const resizer = document.getElementById("resizer");
const mainLayout = document.getElementById("mainLayout");

const settingsBtn = document.getElementById("settingsBtn");
const settingsPopover = document.getElementById("settingsPopover");
const extraFlagsInput = document.getElementById("extraFlagsInput");
const canvasFullscreenBtn = document.getElementById("canvasFullscreenBtn");
const canvasContainer = document.getElementById("canvasContainer");

let editor = null;
let rawConsoleOutput = "";

const DEFAULT_COPY_HTML = copyBtn.innerHTML;

// iOS Warning Dialog
if ((/iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1))
	&& !sessionStorage.getItem('dismissed_ios_warning')) {
	showIosWarningOverlay();
}

function showIosWarningOverlay() {
	const overlay = document.createElement('div');
	overlay.style.cssText = `
	position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
	background-color: #0f172a; color: #f8fafc; font-family: system-ui, sans-serif;
	padding: 24px; display: flex; flex-direction: column; align-items: center;
	justify-content: center; text-align: center; box-sizing: border-box; z-index: 99999;
  `;
	overlay.innerHTML = `
	<button id="closeIosWarning" style="position:absolute;top:16px;right:16px;background:none;border:none;color:#94a3b8;font-size:28px;cursor:pointer;">&times;</button>
	<img src="favicon.svg" style="height: 64px; margin-bottom: 24px;" alt="C3 Logo">
	<h1 style="color: #38bdf8; font-size: 1.5rem; margin-bottom: 12px;">Playground Not Fully Supported on iOS</h1>
	<p style="color: #94a3b8; font-size: 0.95rem; max-width: 420px; margin-bottom: 24px;">The C3 compiler in WebAssembly requires memory features restricted on iOS.</p>
	<button id="bypassIosBtn" style="background:#38bdf8;color:#0f172a;font-weight:600;border:none;padding:10px 20px;border-radius:6px;cursor:pointer;">Continue Anyway</button>
  `;
	document.body.appendChild(overlay);
	const dismiss = () => { sessionStorage.setItem('dismissed_ios_warning', 'true'); overlay.remove(); };
	document.getElementById('closeIosWarning').onclick = dismiss;
	document.getElementById('bypassIosBtn').onclick = dismiss;
}

// Layout Resizer
let leftPercentage = parseFloat(localStorage.getItem("c3_playground_left_percentage") || "50");
let topPercentage = parseFloat(localStorage.getItem("c3_playground_top_percentage") || "50");

function applyLayout() {
	if (window.innerWidth <= 768) {
		mainLayout.style.gridTemplateColumns = "1fr";
		mainLayout.style.gridTemplateRows = `${topPercentage}% 10px 1fr`;
	} else {
		mainLayout.style.gridTemplateRows = "1fr";
		mainLayout.style.gridTemplateColumns = `${leftPercentage}% 10px 1fr`;
	}
}
applyLayout();

window.addEventListener("resize", () => {
	applyLayout();
	if (editor) editor.layout();
});

let isDragging = false;
resizer.onmousedown = (e) => {
	isDragging = true;
	resizer.classList.add("dragging");
	document.body.style.cursor = window.innerWidth <= 768 ? "row-resize" : "col-resize";
	document.body.style.userSelect = "none";
	e.preventDefault();
};

document.onmousemove = (e) => {
	if (!isDragging) return;
	const rect = mainLayout.getBoundingClientRect();
	if (window.innerWidth <= 768) {
		topPercentage = Math.max(15, Math.min(85, ((e.clientY - rect.top) / rect.height) * 100));
	} else {
		leftPercentage = Math.max(15, Math.min(85, ((e.clientX - rect.left) / rect.width) * 100));
	}
	applyLayout();
	if (editor) editor.layout();
};

document.onmouseup = () => {
	if (isDragging) {
		isDragging = false;
		resizer.classList.remove("dragging");
		document.body.style.cursor = "";
		document.body.style.userSelect = "";
		const isMobile = window.innerWidth <= 768;
		const key = isMobile ? "c3_playground_top_percentage" : "c3_playground_left_percentage";
		const val = isMobile ? topPercentage : leftPercentage;
		localStorage.setItem(key, val.toFixed(2));
	}
};

// Console & UI Helpers
function appendConsole(text, isErr = false) {
	const line = isErr ? `[ERR] ${text}` : text;
	rawConsoleOutput += line;
	outputEl.innerHTML = formatConsoleOutput(rawConsoleOutput);
	outputEl.scrollTop = outputEl.scrollHeight;
}

function clearConsole() {
	stopExecution();
	rawConsoleOutput = "";
	outputEl.textContent = "";
	if (window.monaco && editor) monaco.editor.setModelMarkers(editor.getModel(), "c3", []);
}

function formatConsoleOutput(text) {
	let escaped = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

	// Convert local main.c3 error paths to clickable spans (navigates to Monaco editor)
	escaped = escaped.replace(/(?:\/main\.c3|main\.c3):(\d+)(?::(\d+))?/g, (match, line, col) => {
		return `<span class="console-link" style="color:#38bdf8;cursor:pointer;font-weight:bold;" data-line="${line}" data-col="${col || 1}">${match}</span>`;
	});

	// Convert /usr/lib/c3/std/... error notes to GitHub source links
	const stdlibRegex = /(?:\/usr\/lib\/c3\/std\/|std\/)([^:\s)]+):(\d+)(?::(\d+))?/g;
	escaped = escaped.replace(stdlibRegex, (match, subpath, line) => {
		const githubUrl = `https://github.com/c3lang/c3c/blob/master/lib/std/${subpath}#L${line}`;
		return `<a href="${githubUrl}" target="_blank" class="console-link" style="color:#38bdf8;text-decoration:underline;cursor:pointer;font-weight:bold;">${match}</a>`;
	});

	return escaped;
}

// Global Audio Context Tracker to ensure audio never lingers across switches
const activeAudioContexts = new Set();
const OrigAudioContext = window.AudioContext || window.webkitAudioContext;
if (OrigAudioContext && !window.__c3AudioTracked) {
	window.__c3AudioTracked = true;
	const PatchedAudioContext = function(...args) {
		const ctx = new OrigAudioContext(...args);
		activeAudioContexts.add(ctx);
		const origClose = ctx.close;
		ctx.close = function() {
			activeAudioContexts.delete(ctx);
			return origClose.apply(this, arguments);
		};
		return ctx;
	};
	PatchedAudioContext.prototype = OrigAudioContext.prototype;
	window.AudioContext = PatchedAudioContext;
	if (window.webkitAudioContext) window.webkitAudioContext = PatchedAudioContext;
}

let currentEmscriptenInstance = null;

function setStatus(text, stateClass) {
	statusEl.textContent = text;
	statusEl.className = "status-badge " + (stateClass || "");
}

function resumeAudioIfSuspended() {
	for (const ctx of activeAudioContexts) {
		if (ctx && ctx.state === "suspended") {
			ctx.resume().catch(() => {});
		}
	}
	if (window.miniaudio && window.miniaudio.devices) {
		for (const dev of window.miniaudio.devices) {
			if (dev && dev.context && dev.context.state === "suspended") {
				dev.context.resume().catch(() => {});
			}
		}
	}
}

function stopExecution() {
	const container = document.getElementById("canvasContainer");
	if (container) container.style.display = "none";

	// 1. Cancel running Emscripten main loop / animation frame
	if (currentEmscriptenInstance) {
		try {
			if (typeof currentEmscriptenInstance.cancelMainLoop === "function") {
				currentEmscriptenInstance.cancelMainLoop();
			} else if (typeof currentEmscriptenInstance._emscripten_cancel_main_loop === "function") {
				currentEmscriptenInstance._emscripten_cancel_main_loop();
			} else if (currentEmscriptenInstance.Browser && currentEmscriptenInstance.Browser.mainLoop) {
				currentEmscriptenInstance.Browser.mainLoop.pause();
				currentEmscriptenInstance.Browser.mainLoop.func = null;
			}
		} catch (e) {}
		currentEmscriptenInstance = null;
	}

	// 2. Close all active Web Audio contexts
	for (const ctx of activeAudioContexts) {
		try {
			if (ctx && ctx.state !== "closed") {
				ctx.close().catch(() => {});
			}
		} catch (e) {}
	}
	activeAudioContexts.clear();

	// 3. Miniaudio device cleanup
	if (window.miniaudio && window.miniaudio.devices) {
		for (const dev of window.miniaudio.devices) {
			if (dev) {
				if (dev.node) {
					try { dev.node.disconnect(); } catch (e) {}
					dev.node.onaudioprocess = null;
				}
				if (dev.context && dev.context.state !== "closed") {
					try { dev.context.close().catch(() => {}); } catch (e) {}
				}
			}
		}
		window.miniaudio.devices = [];
	}

	getFreshCanvas();
}

// Extra Flags & Settings Popover
extraFlagsInput.value = localStorage.getItem("c3_playground_extra_flags") || "";
extraFlagsInput.oninput = () => {
	localStorage.setItem("c3_playground_extra_flags", extraFlagsInput.value);
};

extraFlagsInput.onkeydown = (e) => {
	if (e.key === "Enter") {
		settingsPopover.classList.remove("active");
		if (!compileBtn.disabled) compileBtn.click();
	}
};

settingsBtn.onclick = (e) => {
	e.stopPropagation();
	settingsPopover.classList.toggle("active");
	if (settingsPopover.classList.contains("active")) extraFlagsInput.focus();
};

document.onclick = (e) => {
	if (!settingsPopover.contains(e.target) && e.target !== settingsBtn) {
		settingsPopover.classList.remove("active");
	}
};

export function fitCanvasToContainer() {
	const wrapper = document.querySelector(".canvas-wrapper");
	const canvas = document.getElementById("canvas");
	if (!wrapper || !canvas || !canvas.width || !canvas.height) return;

	const wrapW = wrapper.clientWidth;
	const wrapH = wrapper.clientHeight;
	if (wrapW <= 0 || wrapH <= 0) return;

	const scale = Math.min(wrapW / canvas.width, wrapH / canvas.height);
	const targetW = Math.max(1, Math.floor(canvas.width * scale));
	const targetH = Math.max(1, Math.floor(canvas.height * scale));

	canvas.style.width = targetW + "px";
	canvas.style.height = targetH + "px";
}

globalThis.fitCanvasToContainer = fitCanvasToContainer;

const canvasResizeObserver = new ResizeObserver(() => {
	fitCanvasToContainer();
});

if (canvasFullscreenBtn) {
	canvasFullscreenBtn.onclick = () => {
		if (!document.fullscreenElement) {
			if (canvasContainer.requestFullscreen) canvasContainer.requestFullscreen();
		} else if (document.exitFullscreen) {
			document.exitFullscreen();
		}
		canvasFullscreenBtn.blur();
		const canvasEl = document.getElementById("canvas");
		if (canvasEl) {
			try { canvasEl.focus(); } catch (e) {}
		}
	};
}

document.addEventListener("fullscreenchange", () => {
	setTimeout(fitCanvasToContainer, 50);
});

window.addEventListener('click', resumeAudioIfSuspended, { passive: true });

// Monaco Initialization
require.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.56.0/min/vs' } });

require(['vs/editor/editor.main'], async () => {
	setupMonacoC3(monaco);

	// 1. Populate Examples Dropdown with Categorized optgroup Sections
	exampleSelect.replaceChildren();
	const placeholderOpt = document.createElement("option");
	placeholderOpt.value = "";
	placeholderOpt.disabled = true;
	placeholderOpt.selected = true;
	placeholderOpt.hidden = true;
	placeholderOpt.textContent = "Examples...";
	exampleSelect.appendChild(placeholderOpt);

	// Group examples by category
	const categories = new Map();
	EXAMPLES_MANIFEST.forEach(ex => {
		const cat = ex.category || "General";
		if (!categories.has(cat)) categories.set(cat, []);
		categories.get(cat).push(ex);
	});

	for (const [catName, examples] of categories.entries()) {
		const group = document.createElement("optgroup");
		group.label = catName;
		examples.forEach(ex => {
			const opt = document.createElement("option");
			opt.value = ex.file;
			opt.dataset.id = ex.id;
			opt.textContent = ex.name;
			group.appendChild(opt);
		});
		exampleSelect.appendChild(group);
	}

	// 2. Load Initial Code (supporting URL example, paste snippet, or localStorage)
	const shared = await getSharedCode();
	let initialCode = "";
	let matchedExampleFile = null;

	if (shared && shared.type === 'example') {
		const found = EXAMPLES_MANIFEST.find(e => e.id === shared.id || e.file === shared.id);
		if (found) {
			matchedExampleFile = found.file;
			initialCode = await fetchExampleCode(found.file);
		}
	} else if (shared && shared.type === 'snippet') {
		initialCode = shared.code;
	}

	if (!initialCode) {
		const savedCode = localStorage.getItem("c3_playground_code");
		initialCode = savedCode || await fetchExampleCode(EXAMPLES_MANIFEST[0].file);
		if (!savedCode) matchedExampleFile = EXAMPLES_MANIFEST[0].file;
	}

	// 3. Create Monaco Instance with Full Settings
	editor = monaco.editor.create(document.getElementById("code"), {
		value: initialCode,
		language: 'c3',
		theme: 'c3PlaygroundTheme',
		automaticLayout: true,
		fontSize: 14,
		lineHeight: 22,
		tabSize: 4,
		insertSpaces: false,
		detectIndentation: false,
		minimap: { enabled: true },
		unicodeHighlight: {
			allowedLocales: { el: true }
		}
	});

	if (matchedExampleFile) {
		exampleSelect.value = matchedExampleFile;
	}

	editor.layout();
	editor.focus();
	registerEditorCommands(monaco);

	// 4. Save edits & reset dropdown placeholder when code changes
	editor.onDidChangeModelContent(() => {
		const code = editor.getValue();
		localStorage.setItem("c3_playground_code", code);
		exampleSelect.value = "";
		queueDocgenUpdate(code);
	});

	editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, () => {
		if (!compileBtn.disabled) compileBtn.click();
	});

	editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, saveCodeToDisk);

	// 5. Fetch example, update URL query & auto-compile and run immediately
	exampleSelect.onchange = async () => {
		if (!exampleSelect.value) return;
		clearConsole();
		const selectedFile = exampleSelect.value;
		const code = await fetchExampleCode(selectedFile);
		editor.setValue(code);
		editor.setScrollPosition({ scrollTop: 0, scrollLeft: 0 });
		editor.setPosition({ lineNumber: 1, column: 1 });
		localStorage.setItem("c3_playground_code", code);
		exampleSelect.value = selectedFile;

		// Update URL parameter so example is shareable
		const selectedEx = EXAMPLES_MANIFEST.find(e => e.file === selectedFile);
		if (selectedEx) {
			const newUrl = new URL(window.location);
			newUrl.searchParams.set('example', selectedEx.id);
			newUrl.hash = '';
			history.replaceState(null, null, newUrl.toString());
		}

		// Auto-compile and run the selected example
		if (!compileBtn.disabled) {
			compileBtn.click();
		}

		// Return focus to the editor so the user can read/edit immediately
		editor.focus();
	};

	// 6. Compiler Pipeline Execution Handler
	compileBtn.onclick = () => {
		stopExecution();
		resumeAudioIfSuspended();
		clearConsole();

		let compileStderrBuffer = [];
		const codeValue = editor.getValue();

		executeCompilerTask("compile", codeValue, async (msg) => {
			if (msg.type === "stdout") {
				appendConsole(msg.text);
			} else if (msg.type === "stderr") {
				compileStderrBuffer.push(msg.text);
				appendConsole(msg.text, true);
			} else if (msg.type === "compiled") {
				appendConsole(`\n[WASM Linked: ${msg.wasm.byteLength} bytes]\n`);
				await runEmscriptenProgram(msg.wasm);
				const markers = parseCompilerErrors(compileStderrBuffer.join('\n'), editor.getModel(), monaco);
				monaco.editor.setModelMarkers(editor.getModel(), "c3", markers);
			} else if (msg.type === "failed") {
				appendConsole(`\n[Compilation Failed]\n${msg.error}\n`);
				const markers = parseCompilerErrors(compileStderrBuffer.join('\n'), editor.getModel(), monaco);
				monaco.editor.setModelMarkers(editor.getModel(), "c3", markers);
			}
		}, extraFlagsInput.value, setStatus);
	};

	try {
		await preloadCompilerAssets(setStatus);
		queryCompilerVersion(vText => { statusTooltipEl.textContent = vText; });
		setStatus("Compiler Ready", "ready");
		compileBtn.disabled = false;
		queueDocgenUpdate(editor.getValue());
		// Kick off stdlib HTML docgen in the background - no-op if already cached
		setTimeout(() => triggerStdlibDocgenHtml(), 100);

		// Auto-run on startup if loaded directly from an example URL param
		if (shared && shared.type === 'example' && matchedExampleFile) {
			compileBtn.click();
		}

		// Background prefetch all examples so dropdown switches are instant
		prefetchAllExamples();
	} catch (err) {
		setStatus("Initialization Failed", "");
		appendConsole(`\n[Fatal Error] Failed to initialize compiler: ${err.message}\n`);
	}
});

// --- Stdlib Docs Modal ---
const stdlibDocsModal = document.getElementById('stdlibDocsModal');
const stdlibDocsIframe = document.getElementById('stdlibDocsIframe');
const stdlibDocsClose = document.getElementById('stdlibDocsClose');

function closeStdlibModal() {
	stdlibDocsModal.classList.remove('open');
	stdlibDocsIframe.src = 'about:blank';
}

stdlibDocsClose.addEventListener('click', closeStdlibModal);
stdlibDocsModal.addEventListener('click', (e) => {
	if (e.target === stdlibDocsModal) closeStdlibModal();
});
document.addEventListener('keydown', (e) => {
	if (e.key === 'Escape' && stdlibDocsModal.classList.contains('open')) closeStdlibModal();
});

// Nav docs button → open local docs modal
document.getElementById('docsBtn').addEventListener('click', () => openStdlibDoc(''));


window.addEventListener('message', (e) => {
	if (!e.data || e.source !== stdlibDocsIframe.contentWindow) return;
	if (e.data.type === 'close-stdlib-docs') {
		closeStdlibModal();
	} else if (e.data.type === 'read_stdlib_file') {
		const { path, line } = e.data;
		readStdlibFile(path, (content, error) => {
			try {
				stdlibDocsIframe.contentWindow.postMessage(
					{ type: 'stdlib_file_content', path, line, content, error }, '*'
				);
			} catch (_) {}
		});
	}
});

window.addEventListener('open-stdlib-doc', (e) => {
	const { html, uid } = e.detail;

	// Patch the HTML before injecting as srcdoc:
	let patched = html;

	// 1. Inject iframe patch script (history sandbox override, file link observer, source viewer)
	const patchScript = getDocsIframePatchJs();
	if (patchScript) {
		patched = patched.replace('<head>', `<head><script>${patchScript}<\/script>`);
	}

	// 2. Remove c3-lang.org assets blocked by CORP
	patched = patched.replace(/<link[^>]+c3-lang\.org[^>]+>/gi, '');
	patched = patched.replace(/<img[^>]+c3-lang\.org[^>]+>/gi, '');

	stdlibDocsIframe.srcdoc = patched;
	stdlibDocsModal.classList.add('open');
	stdlibDocsIframe.onload = () => {
		try { stdlibDocsIframe.contentWindow.location.hash = encodeURIComponent(uid); } catch {}
		stdlibDocsIframe.onload = null;
	};
});


function getFreshCanvas() {
	const oldCanvas = document.getElementById("canvas");
	if (!oldCanvas) return null;
	const newCanvas = oldCanvas.cloneNode(false);
	newCanvas.className = '';
	newCanvas.style.cursor = '';
	newCanvas.tabIndex = 0;
	newCanvas.addEventListener("mousedown", () => newCanvas.focus());
	newCanvas.addEventListener("contextmenu", (e) => e.preventDefault());
	oldCanvas.parentNode.replaceChild(newCanvas, oldCanvas);

	if (document.pointerLockElement) {
		try { document.exitPointerLock(); } catch (_) {}
	}

	const wrapper = document.querySelector(".canvas-wrapper");
	if (wrapper) {
		canvasResizeObserver.disconnect();
		canvasResizeObserver.observe(wrapper);
	}
	return newCanvas;
}

async function runEmscriptenProgram(wasmBuffer) {
	const runtimeFn = window.C3EmscriptenRuntime;
	if (!runtimeFn) {
		appendConsole("\n[Error] C3EmscriptenRuntime not found.\n");
		return;
	}

	try {
		const canvasEl = getFreshCanvas();

		const instance = await runtimeFn({
			wasmBinary: wasmBuffer,
			canvas: canvasEl,
			print: (t) => appendConsole(t + "\n"),
			printErr: (t) => appendConsole(t + "\n", true),
			onExit: (code) => appendConsole(`\nProgram exited with code: ${code}\n`),
			noInitialRun: true
		});

		currentEmscriptenInstance = instance;

		const mainFn = instance.wasmExports?.main || instance.wasmExports?.['__main_argc_argv'];
		if (mainFn) {
			const ret = mainFn(0, 0);
			appendConsole(`\n[Process finished with exit code ${ret}]\n`);
		}
	} catch (err) {
		if (err === "unwind" || err?.name === "ExitStatus") {
			// Normal Emscripten loop unwinding when simulate_infinite_loop is 1
			return;
		}
		appendConsole(`\n[Execution Error] ${err}\n`);
	}
}

// Console Line Click Navigation
outputEl.onclick = (e) => {
	if (e.target && e.target.classList.contains('console-link')) {
		const line = parseInt(e.target.getAttribute('data-line'), 10);
		const col = parseInt(e.target.getAttribute('data-col'), 10);
		if (editor && line) {
			editor.revealLineInCenter(line);
			editor.setPosition({ lineNumber: line, column: col });
			editor.focus();
		}
	}
};

clearBtn.onclick = clearConsole;
saveBtn.onclick = saveCodeToDisk;

function saveCodeToDisk() {
	if (!editor) return;
	const blob = new Blob([editor.getValue()], { type: 'text/plain;charset=utf-8' });
	const url = URL.createObjectURL(blob);
	const a = document.createElement('a');
	a.href = url;
	a.download = 'main.c3';
	document.body.appendChild(a);
	a.click();
	document.body.removeChild(a);
	URL.revokeObjectURL(url);
}

copyBtn.onclick = () => {
	if (!editor) return;
	navigator.clipboard.writeText(editor.getValue()).then(() => {
		copyBtn.innerHTML = `
	  <svg viewBox="0 0 24 24" fill="none" stroke="#34d399" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
		<polyline points="20 6 9 17 4 12"></polyline>
	  </svg>
	`;
		copyBtn.title = "Copied!";
		setTimeout(() => {
			copyBtn.innerHTML = DEFAULT_COPY_HTML;
			copyBtn.title = "Copy Code";
		}, 1500);
	});
};

const DEFAULT_SHARE_HTML = shareBtn.innerHTML;
let shareResetTimeout = null;

shareBtn.onclick = async () => {
	if (!editor) return;
	shareBtn.disabled = true;
	shareBtn.title = "Generating Link...";

	try {
		await createShareLink(editor.getValue());
		shareBtn.innerHTML = `
	  <svg viewBox="0 0 24 24" fill="none" stroke="#34d399" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
		<polyline points="20 6 9 17 4 12"></polyline>
	  </svg>
	`;
		shareBtn.title = "Link Copied!";
	} catch (err) {
		console.error("Failed to share code:", err);
		alert("Could not reach pastes.dev API");
	} finally {
		shareBtn.disabled = false;
		clearTimeout(shareResetTimeout);
		shareResetTimeout = setTimeout(() => {
			shareBtn.innerHTML = DEFAULT_SHARE_HTML;
			shareBtn.title = "Share Code";
		}, 1500);
	}
};