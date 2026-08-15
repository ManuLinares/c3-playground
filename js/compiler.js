// js/compiler.js

let isAnyCompilerTaskRunning = false;
let activeWorker = null;
let activeTaskType = null;
let compilerWorkerBlobUrl = null;

let compiledCompilerModule = null;
let c3cJsText = "";
let c3cDataBuffer = null;
let c3WorkerJsText = "";
let docsIframePatchJs = "";

let docDbSymbols = [];
let docgenTimeout = null;

let stdlibDocHtml = null; // cached docs.html HTML string, populated once on startup

// Persistent worker kept alive after docgen_html completes to handle read_file requests.
let _stdlibWorker = null;
let _stdlibWorkerReady = false;
const _stdlibFileCallbacks = new Map(); // path -> Array<(content, error) => void>
const _pendingFileReads = []; // Array<{ path: string, callback: (content, error) => void }>

export function getDocDbSymbols() {
	return docDbSymbols;
}

export function getDocsIframePatchJs() {
	return docsIframePatchJs;
}

export async function preloadCompilerAssets(onStatusChange) {
	if (onStatusChange) onStatusChange("Downloading files...", "");

	const wasmPromise = fetch('build/c3c.wasm')
		.then(r => {
			if (!r.ok) throw new Error('Failed to fetch c3c.wasm');
			return r.arrayBuffer();
		})
		.then(b => WebAssembly.compile(b))
		.then(m => { compiledCompilerModule = m; });

	const jsPromise = fetch('build/c3c.js')
		.then(r => { if (!r.ok) throw new Error('Failed to fetch c3c.js'); return r.text(); })
		.then(t => { c3cJsText = t; });

	const dataPromise = fetch('build/c3c.data')
		.then(r => { if (!r.ok) throw new Error('Failed to fetch c3c.data'); return r.arrayBuffer(); })
		.then(b => { c3cDataBuffer = b; });

	const workerPromise = fetch('c3-worker.js')
		.then(r => { if (!r.ok) throw new Error('Failed to fetch c3-worker.js'); return r.text(); })
		.then(t => { c3WorkerJsText = t; });

	const patchPromise = fetch('js/docs-iframe-patch.js')
		.then(r => { if (!r.ok) throw new Error('Failed to fetch js/docs-iframe-patch.js'); return r.text(); })
		.then(t => { docsIframePatchJs = t; });

	await Promise.all([wasmPromise, jsPromise, dataPromise, workerPromise, patchPromise]);
}

export function executeCompilerTask(taskType, sourceCode, onMessageCallback, extraFlags = '', setStatusCallback) {
	if (isAnyCompilerTaskRunning) {
		if (activeWorker && (activeTaskType === "docgen" || activeTaskType === "version")) {
			activeWorker.terminate();
			isAnyCompilerTaskRunning = false;
			activeWorker = null;
			activeTaskType = null;
		} else {
			return;
		}
	}

	isAnyCompilerTaskRunning = true;
	activeTaskType = taskType;

	if (taskType === "compile" && setStatusCallback) {
		setStatusCallback("Compiling...", "compiling");
	}

	if (!compilerWorkerBlobUrl) {
		const blob = new Blob([c3WorkerJsText], { type: 'application/javascript' });
		compilerWorkerBlobUrl = URL.createObjectURL(blob);
	}

	const tempWorker = new Worker(compilerWorkerBlobUrl);
	activeWorker = tempWorker;
	let initComplete = false;

	tempWorker.onerror = (err) => {
		tempWorker.terminate();
		isAnyCompilerTaskRunning = false;
		activeWorker = null;
		activeTaskType = null;
		if (taskType === "compile" && setStatusCallback) {
			setStatusCallback("Compiler Ready", "ready");
		}
		onMessageCallback({ type: `${taskType}_failed`, error: err.message || 'Worker crash' }, tempWorker);
	};

	tempWorker.onmessage = (e) => {
		const msg = e.data;

		if (msg.type === "ready") {
			initComplete = true;
			tempWorker.postMessage({ type: taskType, source: sourceCode, extraFlags: extraFlags });
			return;
		}

		if (taskType === "compile" && (msg.type === "stdout" || msg.type === "stderr")) {
			onMessageCallback(msg, tempWorker);
			return;
		}

		tempWorker.terminate();
		isAnyCompilerTaskRunning = false;
		activeWorker = null;
		activeTaskType = null;

		if (taskType === "compile" && setStatusCallback) {
			setStatusCallback("Compiler Ready", "ready");
		}

		onMessageCallback(msg, tempWorker);
	};

	setTimeout(() => {
		if (!initComplete) {
			tempWorker.terminate();
			isAnyCompilerTaskRunning = false;
			activeWorker = null;
			activeTaskType = null;
			if (taskType === "compile" && setStatusCallback) {
				setStatusCallback("Compiler Ready", "ready");
			}
			onMessageCallback({ type: `${taskType}_failed`, error: 'Timeout' }, tempWorker);
		}
	}, 5000);

	tempWorker.postMessage({
		type: "init_module",
		wasmModule: compiledCompilerModule,
		c3cJs: c3cJsText,
		c3cData: c3cDataBuffer
	});
}

export function queryCompilerVersion(onVersionLoaded) {
	executeCompilerTask("version", "", (msg) => {
		if (msg.type === "version_info") {
			if (onVersionLoaded) onVersionLoaded(msg.text.trim());
		}
	});
}

function flushPendingFileReads() {
	while (_pendingFileReads.length > 0) {
		const req = _pendingFileReads.shift();
		dispatchReadFile(req.path, req.callback);
	}
}

function dispatchReadFile(path, callback) {
	let list = _stdlibFileCallbacks.get(path);
	if (!list) {
		list = [];
		_stdlibFileCallbacks.set(path, list);
	}
	list.push(callback);
	_stdlibWorker.postMessage({ type: 'read_file', path });
}

function failAllFileReads(errorMsg) {
	for (const req of _pendingFileReads) {
		try { req.callback(null, errorMsg); } catch (_) {}
	}
	_pendingFileReads.length = 0;

	for (const [path, callbacks] of _stdlibFileCallbacks.entries()) {
		for (const cb of callbacks) {
			try { cb(null, errorMsg); } catch (_) {}
		}
	}
	_stdlibFileCallbacks.clear();
}

// Run c3c docgen (HTML output) in a background worker and cache the result.
// The worker is kept alive after docgen_html completes to handle on-demand read_file requests.
// Subsequent calls are no-ops if the worker is already running or the HTML is already cached.
export function triggerStdlibDocgenHtml() {
	if (stdlibDocHtml || _stdlibWorker) return;

	// Reuse the same blob URL as regular compiler tasks
	if (!compilerWorkerBlobUrl) {
		const blob = new Blob([c3WorkerJsText], { type: 'application/javascript' });
		compilerWorkerBlobUrl = URL.createObjectURL(blob);
	}

	_stdlibWorker = new Worker(compilerWorkerBlobUrl);

	_stdlibWorker.onerror = (err) => {
		console.error('[StdlibWorker] Error:', err);
		_stdlibWorkerReady = false;
		failAllFileReads('Stdlib worker failed');
	};

	_stdlibWorker.onmessage = (e) => {
		const msg = e.data;
		if (msg.type === 'ready') {
			_stdlibWorkerReady = true;
			_stdlibWorker.postMessage({ type: 'docgen_html', source: '' });
			flushPendingFileReads();
		} else if (msg.type === 'docgen_html_ready') {
			stdlibDocHtml = msg.html;
			console.log(`[Compiler] stdlib docs.html cached (${(stdlibDocHtml.length / 1024).toFixed(0)} KB)`);
		} else if (msg.type === 'docgen_html_failed') {
			console.warn('[Compiler] stdlib docgen failed - go-to-def will fall back to website');
		} else if (msg.type === 'file_content') {
			const callbacks = _stdlibFileCallbacks.get(msg.path);
			if (callbacks && callbacks.length > 0) {
				_stdlibFileCallbacks.delete(msg.path);
				for (const cb of callbacks) {
					try { cb(msg.content, msg.error); } catch (err) { console.error(err); }
				}
			}
		}
	};

	_stdlibWorker.postMessage({
		type: 'init_module',
		wasmModule: compiledCompilerModule,
		c3cJs: c3cJsText,
		c3cData: c3cDataBuffer
	});
}

// Read a stdlib source file from the persistent worker's Emscripten VFS.
// Automatically triggers worker startup and queues request if worker runtime is initializing.
export function readStdlibFile(path, callback) {
	if (!_stdlibWorker) {
		triggerStdlibDocgenHtml();
	}
	if (!_stdlibWorkerReady) {
		_pendingFileReads.push({ path, callback });
		return;
	}
	dispatchReadFile(path, callback);
}

// Open the cached stdlib docs modal anchored to the given symbol UID.
// Dispatches a custom event consumed by main.js to keep modal logic centralised.
export function openStdlibDoc(uid) {
	if (!stdlibDocHtml) {
		// Docs not ready yet - fall back to website
		window.open(`https://c3-lang.org/standard-library/docs.html#${uid}`, '_blank');
		return;
	}
	window.dispatchEvent(new CustomEvent('open-stdlib-doc', { detail: { html: stdlibDocHtml, uid } }));
}

export function triggerSilentDocgen(codeValue) {
	executeCompilerTask("docgen", codeValue, (msg) => {
		if (msg.type === "doc_db") {
			// Update symbols only on success, keep last good result on failure
			docDbSymbols = flattenDocgen(msg.db);
		}
	});
}

export function queueDocgenUpdate(codeValue) {
	clearTimeout(docgenTimeout);
	docgenTimeout = setTimeout(() => {
		triggerSilentDocgen(codeValue);
	}, 800);
}

function flattenDocgen(db) {
	const symbols = [];
	if (!db || !db.modules) return symbols;

	for (const [moduleName, mod] of Object.entries(db.modules)) {
		const categories = ['functions', 'macros', 'types', 'globals', 'methods', 'constants', 'variables'];
		for (const cat of categories) {
			if (Array.isArray(mod[cat])) {
				for (const item of mod[cat]) {
					symbols.push({ ...item, module: moduleName, category: cat });
				}
			}
		}
	}
	return symbols;
}