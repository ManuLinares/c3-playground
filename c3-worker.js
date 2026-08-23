// c3-worker.js
console.log("[Worker] Worker script loaded and starting...");

let runtimeReady = false;

let docgenBuffer = [];
let isDocgenRunning = false;

let versionBuffer = [];
let isVersionRunning = false;

const SILENCE_EMSCRIPTEN_STDIO_WARNINGS = false;

// Common c3c flags ensuring consistent standard library and build directory paths across all workers
const COMMON_C3C_FLAGS = [
	'--stdlib', '/usr/lib/c3/std',
	'--libdir', '/usr/lib/c3/lib',
	'--lib', 'raylib6',
	'--build-dir', '/c3build',
];

const moduleProto = {
	wasmBinary: null,
	cachedData: null
};

var Module = Object.create(moduleProto);

Module.noInitialRun = true;
Module.preRun = [];
Module.postRun = [];

Module.instantiateWasm = function (imports, successCallback) {
	console.log("[Worker] instantiateWasm called by Emscripten loader.");
	if (!moduleProto.wasmBinary) {
		console.error("[Worker] wasmBinary not found in Module prototype!");
		return {};
	}
	const isModule = moduleProto.wasmBinary instanceof WebAssembly.Module;
	if (isModule) {
		console.log("[Worker] Instantiating from pre-compiled WebAssembly.Module...");
		WebAssembly.instantiate(moduleProto.wasmBinary, imports).then(instance => {
			console.log("[Worker] WebAssembly.instantiate success!");
			successCallback(instance);
		}).catch(err => {
			console.error("[Worker] instantiateWasm error:", err);
			postMessage({ type: 'failed', error: err.stack || String(err) });
		});
	} else {
		console.log("[Worker] Instantiating from ArrayBuffer/Uint8Array...");
		WebAssembly.instantiate(moduleProto.wasmBinary, imports).then(output => {
			console.log("[Worker] WebAssembly.instantiate success!");
			successCallback(output.instance);
		}).catch(err => {
			console.error("[Worker] instantiateWasm error:", err);
			postMessage({ type: 'failed', error: err.stack || String(err) });
		});
	}
	return {};
};

Module.getPreloadedPackage = function (remotePackageName, remotePackageSize) {
	console.log(`[Worker] getPreloadedPackage requested: ${remotePackageName}`);
	if (remotePackageName.endsWith('c3c.data') || remotePackageName.endsWith('.data')) {
		if (moduleProto.cachedData) {
			console.log(`[Worker] Returning preloaded data buffer (${moduleProto.cachedData.byteLength} bytes)`);
			return moduleProto.cachedData;
		}
		console.warn(`[Worker] cachedData is not yet set in Module prototype.`);
	}
	return null;
};

Module.print = function (text) {
	if (isDocgenRunning) {
		docgenBuffer.push(text);
	} else if (isVersionRunning) {
		versionBuffer.push(text);
	} else {
		postMessage({ type: 'stdout', text: text + '\n' });
	}
};

Module.printErr = function (text) {
	if (isDocgenRunning) {
		return;
	} else if (isVersionRunning) {
		return;
	}
	if (SILENCE_EMSCRIPTEN_STDIO_WARNINGS && text.includes('warning: no standard file descriptor')) {
		return;
	}
	postMessage({ type: 'stderr', text: text + '\n' });
};

Module.onRuntimeInitialized = function () {
	console.log("[Worker] Module.onRuntimeInitialized called!");
	runtimeReady = true;
	postMessage({ type: 'ready' });
};

self.onmessage = function (e) {
	const msg = e.data;
	console.log(`[Worker] onmessage received type: ${msg.type}`);

	if (msg.type === 'init_module') {
		try {
			console.log("[Worker] Storing compiled WebAssembly.Module into prototype...");
			moduleProto.wasmBinary = msg.wasmModule;

			console.log("[Worker] Storing preloaded c3c.data ArrayBuffer into prototype...");
			moduleProto.cachedData = msg.c3cData;

			console.log("[Worker] Evaluating c3c.js text in global scope (Browser)...");
			(0, eval)(msg.c3cJs);
			console.log("[Worker] build/c3c.js evaluated successfully.");
		} catch (err) {
			console.error("[Worker] Error during init_module:", err);
			postMessage({ type: 'failed', error: 'Failed to load WASM runtime: ' + err.message });
		}
		return;
	}

	if (msg.type === 'version') {
		if (!runtimeReady) {
			postMessage({ type: 'version_failed', error: 'Not ready' });
			return;
		}
		isVersionRunning = true;
		versionBuffer = [];
		try {
			Module.callMain(['--target', 'emscripten', '--version']);
		} catch (exitErr) {
		} finally {
			isVersionRunning = false;
		}
		postMessage({
			type: 'version_info',
			text: versionBuffer.join('\n')
		});
		return;
	}

	if (msg.type === 'docgen') {
		if (!runtimeReady) return;

		let fileStream = null;
		let oldStdoutStream = null;
		let errFileStream = null;
		let oldStderrStream = null;
		let compilationFailed = false;

		try {
			removeFile('/main.c3');
			Module.FS.writeFile('/main.c3', msg.source);

			removeFile('/doc.json');
			Module.FS.writeFile('/doc.json', '');
			removeFile('/err.log');
			Module.FS.writeFile('/err.log', '');

			fileStream = Module.FS.open('/doc.json', 'w');
			errFileStream = Module.FS.open('/err.log', 'w');

			oldStdoutStream = Module.FS.streams[1];
			Module.FS.streams[1] = fileStream;

			oldStderrStream = Module.FS.streams[2];
			Module.FS.streams[2] = errFileStream;

			isDocgenRunning = true;

			try {
				Module.callMain([
					'docgen',
					'--json',
					'--target', 'emscripten',
					'--emit-stdlib=yes',
					...COMMON_C3C_FLAGS,
					'/main.c3',
					'--max-mem', '64',
				]);
			} catch (exitErr) {
			}
		} catch (docErr) {
			console.error("[Worker Docgen] Documentation generation failed:", docErr);
			compilationFailed = true;
		} finally {
			isDocgenRunning = false;

			const fflush = Module._fflush || Module['_fflush'];
			if (fflush) {
				try {
					fflush(0);
				} catch (e) { }
			}

			if (oldStdoutStream) {
				Module.FS.streams[1] = oldStdoutStream;
			}
			if (oldStderrStream) {
				Module.FS.streams[2] = oldStderrStream;
			}

			if (fileStream) {
				try {
					Module.FS.close(fileStream);
				} catch (e) { }
			}
			if (errFileStream) {
				try {
					Module.FS.close(errFileStream);
				} catch (e) { }
			}
		}

		if (compilationFailed) {
			postMessage({ type: 'docgen_failed' });
			return;
		}

		try {
			const rawJson = Module.FS.readFile('/doc.json', { encoding: 'utf8' });
			removeFile('/doc.json');
			removeFile('/err.log');

			if (rawJson && rawJson.trim().length > 0) {
				const parsedDb = JSON.parse(rawJson);
				postMessage({
					type: 'doc_db',
					db: parsedDb
				});
			} else {
				console.warn("[Worker Docgen] Documentation file was empty.");
				postMessage({ type: 'docgen_failed' });
			}
		} catch (jsonErr) {
			console.error("[Worker Docgen] JSON parsing error on docgen database:", jsonErr);
			postMessage({ type: 'docgen_failed' });
		}
		return;
	}

	// Generate a full docs.html for the stdlib (run once on startup).
	// c3c docgen without --json writes docs.html to the current working directory.
	if (msg.type === 'docgen_html') {
		if (!runtimeReady) return;

		let errFileStream = null;
		let oldStderrStream = null;

		try {
			// Silence compiler stderr during docgen_html
			removeFile('/docgen_html_err.log');
			Module.FS.writeFile('/docgen_html_err.log', '');
			errFileStream = Module.FS.open('/docgen_html_err.log', 'w');
			oldStderrStream = Module.FS.streams[2];
			Module.FS.streams[2] = errFileStream;

			isDocgenRunning = true;
			// Anchor CWD to / so docs.html is written to a known path
			Module.FS.chdir('/');
			removeFile('/docs.html');
			// c3c docgen needs at least one source file to run; write a minimal stub.
			// --emit-stdlib=yes ensures the full stdlib is documented alongside it.
			Module.FS.writeFile('/docgen_stub.c3', 'module docgen_stub;\n');

			try {
				Module.callMain([
					'docgen',
					'--target', 'emscripten',
					'--emit-stdlib=yes',
					...COMMON_C3C_FLAGS,
					'--max-mem', '64',
					'/docgen_stub.c3',
				]);
			} catch (exitErr) {}
			removeFile('/docgen_stub.c3');

		} catch (err) {
			console.error("[Worker DocgenHTML] Failed:", err);
		} finally {
			isDocgenRunning = false;

			const fflush = Module._fflush || Module['_fflush'];
			if (fflush) { try { fflush(0); } catch (e) {} }

			if (oldStderrStream) Module.FS.streams[2] = oldStderrStream;
			if (errFileStream) { try { Module.FS.close(errFileStream); } catch (e) {} }
			removeFile('/docgen_html_err.log');
		}

		// Try /docs.html first, then CWD/docs.html as fallback
		const cwd = Module.FS.cwd();
		const candidates = ['/docs.html', `${cwd}/docs.html`.replace('//', '/')];
		let html = null;
		for (const path of candidates) {
			try {
				const text = Module.FS.readFile(path, { encoding: 'utf8' });
				if (text && text.length > 0) {
					html = text;
					removeFile(path);
					break;
				}
			} catch (_) {}
		}

		if (html) {
			postMessage({ type: 'docgen_html_ready', html });
		} else {
			console.error(`[Worker DocgenHTML] docs.html not found. CWD was: ${cwd}`);
			postMessage({ type: 'docgen_html_failed' });
		}
		return;
	}

	// On-demand source file read from the Emscripten VFS (used by the persistent stdlib worker).
	if (msg.type === 'read_file') {
		if (!runtimeReady) {
			postMessage({ type: 'file_content', path: msg.path, content: null, error: 'Not ready' });
			return;
		}
		try {
			const content = Module.FS.readFile(msg.path, { encoding: 'utf8' });
			postMessage({ type: 'file_content', path: msg.path, content });
		} catch (e) {
			postMessage({ type: 'file_content', path: msg.path, content: null, error: e.message });
		}
		return;
	}

	if (msg.type !== 'compile') return;

	if (!runtimeReady) {
		console.warn("[Worker] compile message received but runtime is not ready!");
		postMessage({
			type: 'failed',
			error: 'Compiler runtime not ready'
		});
		return;
	}

	try {
		console.log("[Worker] Starting compilation step...");
		removeFile('/main.c3');
		removeFile('/main.wasm');

		// Write all required assets into the worker's virtual file system
		if (msg.assets && Array.isArray(msg.assets)) {
			for (const asset of msg.assets) {
				writeVfsFile(Module.FS, asset.path, asset.data);
			}
		}

		Module.FS.writeFile('/main.c3', msg.source);
		console.log("[Worker] Written main.c3 into virtual file system.");

		// Helper to tokenize command-line flag string safely
		function parseFlags(str) {
			if (!str || !str.trim()) return [];
			const regex = /[^\s"']+|"([^"]*)"|'([^']*)'/g;
			const args = [];
			let match;
			while ((match = regex.exec(str)) !== null) {
				args.push(match[1] ?? match[2] ?? match[0]);
			}
			return args;
		}

		const userFlags = parseFlags(msg.extraFlags);

		const hasMaxMem = userFlags.some(arg => arg === '--max-mem' || arg.startsWith('--max-mem='));
		const maxMemDefault = hasMaxMem ? [] : ['--max-mem', '64'];

		console.log("[Worker] Calling Module.callMain compiler command...");
		const exitCode = Module.callMain([
			'compile',
			...maxMemDefault,
			'--target', 'emscripten',
			'--linker=builtin',
			'--ansi=no',
			'-o', '/main.wasm',
			...COMMON_C3C_FLAGS,
			'-L', '/usr/lib/c3/wasm32-emscripten',
			'-l', 'c',
			'-l', 'dlmalloc',
			'-l', 'stubs',
			'-l', 'sockets',
			'-l', 'clang_rt.builtins',
			'-z', '--no-entry',
			'-z', '--export=main',
			'-z', '--export=__wasm_call_ctors',
			'-z', '--export=malloc',
			'-z', '--export=free',
			'-z', '--export=htons',
			'-z', '--export=ntohs',
			'-z', '--export=htonl',
			'-z', '--export=ntohl',
			'-z', '--export-table',
			'-z', '--allow-undefined',
			'-z', '-zstack-size=1048576',
			...userFlags,
			'/main.c3'
		]);

		console.log(`[Worker] callMain finished with exitCode: ${exitCode}`);

		if (exitCode !== 0) {
			postMessage({
				type: 'failed',
				error: 'Compiler exited with status code ' + exitCode
			});
			return;
		}

		console.log("[Worker] Reading compiled main.wasm from FS...");
		const wasm = Module.FS.readFile('/main.wasm');
		console.log(`[Worker] Read ${wasm.byteLength} bytes compiled wasm. Sending to main thread...`);

		postMessage(
			{ type: 'compiled', wasm: wasm.buffer },
			[wasm.buffer]
		);
	} catch (err) {
		console.error("[Worker] Error during compilation step:", err);
		postMessage({
			type: 'failed',
			error: err.stack || String(err)
		});
	}
};

function removeFile(path) {
	try {
		Module.FS.unlink(path);
	} catch { }
}

function writeVfsFile(fs, filePath, data) {
	if (!fs || !filePath || !data) return;
	const cleanPath = filePath.replace(/\\/g, '/');
	const normalizedPath = cleanPath.startsWith('/') ? cleanPath : '/' + cleanPath;
	const parts = normalizedPath.split('/').filter(Boolean);
	parts.pop();

	let cur = '';
	for (const p of parts) {
		cur += '/' + p;
		try {
			if (fs.analyzePath) {
				if (!fs.analyzePath(cur).exists) {
					fs.mkdir(cur);
				}
			} else {
				fs.mkdir(cur);
			}
		} catch (_) {}
	}

	try {
		fs.unlink(normalizedPath);
	} catch (_) {}

	const u8 = data instanceof Uint8Array ? data : new Uint8Array(data);
	fs.writeFile(normalizedPath, u8);
}