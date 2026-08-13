// js/main.js
import { EXAMPLES_MANIFEST, fetchExampleCode } from './examples.js';
import { setupMonacoC3, parseCompilerErrors } from './monaco-c3.js';
import {
	preloadCompilerAssets,
	executeCompilerTask,
	queryCompilerVersion,
	queueDocgenUpdate
} from './compiler.js';
import { startCanvasRuntime, stopCanvasRuntime } from './canvas-runtime.js';
import { startAudioRuntime, stopAudioRuntime, resumeAudioIfSuspended } from './audio-runtime.js';
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

function setStatus(text, stateClass) {
	statusEl.textContent = text;
	statusEl.className = "status-badge " + (stateClass || "");
}

function stopExecution() {
	stopCanvasRuntime();
	stopAudioRuntime();
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

if (canvasFullscreenBtn) {
	canvasFullscreenBtn.onclick = () => {
		if (!document.fullscreenElement) {
			if (canvasContainer.requestFullscreen) canvasContainer.requestFullscreen();
		} else if (document.exitFullscreen) {
			document.exitFullscreen();
		}
		canvasFullscreenBtn.blur();
		const hiddenInput = document.getElementById("canvasHiddenInput");
		if (hiddenInput) {
			try { hiddenInput.focus(); } catch (e) { }
		}
	};
}

window.addEventListener('click', resumeAudioIfSuspended, { passive: true });

// Monaco Initialization
require.config({ paths: { vs: 'https://cdn.jsdelivr.net/npm/monaco-editor@0.56.0/min/vs' } });

require(['vs/editor/editor.main'], async () => {
	setupMonacoC3(monaco);

	// 1. Populate Examples Dropdown
	exampleSelect.replaceChildren();
	const placeholderOpt = document.createElement("option");
	placeholderOpt.value = "";
	placeholderOpt.disabled = true;
	placeholderOpt.selected = true;
	placeholderOpt.hidden = true;
	placeholderOpt.textContent = "Examples...";
	exampleSelect.appendChild(placeholderOpt);

	EXAMPLES_MANIFEST.forEach(ex => {
		const opt = document.createElement("option");
		opt.value = ex.file;
		opt.textContent = ex.name;
		exampleSelect.appendChild(opt);
	});

	// 2. Load Initial Code
	const sharedCode = await getSharedCode();
	const savedCode = localStorage.getItem("c3_playground_code");
	const initialCode = sharedCode || savedCode || await fetchExampleCode(EXAMPLES_MANIFEST[0].file);

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

	editor.layout();
	editor.focus();

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

	// 5. Fetch example only when explicitly chosen
	exampleSelect.onchange = async () => {
		if (!exampleSelect.value) return;
		clearConsole();
		const selectedFile = exampleSelect.value;
		const code = await fetchExampleCode(selectedFile);
		editor.setValue(code);
		localStorage.setItem("c3_playground_code", code);
		exampleSelect.value = selectedFile;
		if (window.location.hash) {
			history.replaceState(null, null, window.location.pathname + window.location.search);
		}
	};

	// 6. Compiler Pipeline Execution Handler
	compileBtn.onclick = () => {
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
	} catch (err) {
		setStatus("Initialization Failed", "");
		appendConsole(`\n[Fatal Error] Failed to initialize compiler: ${err.message}\n`);
	}
});

async function runEmscriptenProgram(wasmBuffer) {
	const runtimeFn = window.C3EmscriptenRuntime;
	if (!runtimeFn) {
		appendConsole("\n[Error] C3EmscriptenRuntime not found.\n");
		return;
	}

	try {
		const instance = await runtimeFn({
			wasmBinary: wasmBuffer,
			print: (t) => appendConsole(t + "\n"),
			printErr: (t) => appendConsole(t + "\n", true),
			onExit: (code) => appendConsole(`\nProgram exited with code: ${code}\n`),
			noInitialRun: true
		});

		const mainFn = instance.wasmExports?.main || instance.wasmExports?.['__main_argc_argv'];
		if (mainFn) {
			const ret = mainFn(0, 0);
			appendConsole(`\n[Process finished with exit code ${ret}]\n`);
			startCanvasRuntime(instance);
			startAudioRuntime(instance);
		}
	} catch (err) {
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