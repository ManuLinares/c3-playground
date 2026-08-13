// js/compiler.js

let isAnyCompilerTaskRunning = false;
let activeWorker = null;
let activeTaskType = null;
let compilerWorkerBlobUrl = null;

let compiledCompilerModule = null;
let c3cJsText = "";
let c3cDataBuffer = null;
let c3WorkerJsText = "";

let docDbSymbols = [];
let docgenTimeout = null;

export function getDocDbSymbols() {
	return docDbSymbols;
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

	await Promise.all([wasmPromise, jsPromise, dataPromise, workerPromise]);
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

export function triggerSilentDocgen(codeValue) {
	executeCompilerTask("docgen", codeValue, (msg) => {
		if (msg.type === "doc_db") {
			docDbSymbols = flattenDocgen(msg.db);
		} else {
			docDbSymbols = [];
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