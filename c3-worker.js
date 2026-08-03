console.log("[Worker] Worker script loaded and starting...");

let runtimeReady = false;

// Flags and buffers to safely capture docgen JSON output without polluting stdout/stderr
let docgenBuffer = [];
let isDocgenRunning = false;

let versionBuffer = [];
let isVersionRunning = false;

const moduleProto = {
	wasmBinary: null,
	cachedData: null // Holds the pre-downloaded c3c.data ArrayBuffer
};

var Module = Object.create(moduleProto);

Module.noInitialRun = true;

Module.instantiateWasm = function (imports, successCallback) {
	console.log("[Worker] Module.instantiateWasm called!");
	const isModule = Module.wasmBinary instanceof WebAssembly.Module;
	console.log(`[Worker] instantiateWasm: isModule = ${isModule}`);
	WebAssembly.instantiate(Module.wasmBinary, imports).then(output => {
		const instance = isModule ? output : output.instance;
		console.log("[Worker] WebAssembly.instantiate completed successfully.");
		successCallback(instance);
	}).catch(err => {
		console.error("[Worker] WebAssembly.instantiate failed:", err);
		postMessage({ type: 'stderr', text: 'instantiateWasm error: ' + err + '\n' });
	});
	return {};
};

// Return the pre-loaded ArrayBuffer synchronously to Emscripten,
// preventing any virtual filesystem fetch operations.
Module.getPreloadedPackage = function (remotePackageName, remotePackageSize) {
	console.log("[Worker] Module.getPreloadedPackage requested:", remotePackageName);
	if (remotePackageName.endsWith('c3c.data')) {
		console.log("[Worker] Returning cached c3c.data buffer from memory!");
		return moduleProto.cachedData;
	}
	return null;
};

Module.locateFile = function (path) {
	console.log(`[Worker] Module.locateFile called for: ${path}`);
	if (path.endsWith('.data')) return 'build/c3c.data';
	return path;
};

Module.print = function (text) {
	// Intercept and silence the Emscripten unflushed stdio assertion warning
	if (text.includes("stdio streams had content in them that was not flushed") ||
		text.includes("you should set EXIT_RUNTIME to 1") ||
		text.includes("this may also be due to not including full filesystem support")) {
		console.warn("[Worker Intercepted Warning] " + text);
		return;
	}

	if (isVersionRunning) {
		versionBuffer.push(text);
	} else if (isDocgenRunning) {
		docgenBuffer.push(text);
	} else {
		postMessage({ type: 'stdout', text: text + '\n' });
	}
};

Module.printErr = function (text) {
	// Completely suppress standard error output when docgen is running
	if (isDocgenRunning) {
		console.warn("[Worker Intercepted Docgen Stderr] " + text);
		return;
	}

	if (isVersionRunning) {
		versionBuffer.push(text);
		return;
	}

	// Intercept and silence the Emscripten unflushed stdio assertion warning on stderr
	if (text.includes("stdio streams had content in them that was not flushed") ||
		text.includes("you should set EXIT_RUNTIME to 1") ||
		text.includes("this may also be due to not including full filesystem support")) {
		console.warn("[Worker Intercepted Warning] " + text);
		return;
	}

	postMessage({ type: 'stderr', text: text + '\n' });
};

Module.onRuntimeInitialized = function () {
	console.log("[Worker] Module.onRuntimeInitialized called!");
	runtimeReady = true;
	postMessage({ type: 'ready' });
};

// Helper to strip non-JSON header logs or warnings from stdout
function extractJSON(str) {
	const firstBrace = str.indexOf('{');
	const lastBrace = str.lastIndexOf('}');
	if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
		return str.substring(firstBrace, lastBrace + 1);
	}
	return str;
}

self.onmessage = function (e) {
	const msg = e.data;
	console.log(`[Worker] onmessage received type: ${msg.type}`);

	if (msg.type === 'init_module') {
		try {
			console.log("[Worker] Storing compiled WebAssembly.Module into prototype...");
			moduleProto.wasmBinary = msg.wasmModule;

			console.log("[Worker] Storing preloaded c3c.data ArrayBuffer into prototype...");
			moduleProto.cachedData = msg.c3cData;

			console.log("[Worker] Evaluating c3c.js text in global scope...");
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
			// Trap exit status
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

			// Set up target VFS files to trap standard output and error output securely
			removeFile('/doc.json');
			Module.FS.writeFile('/doc.json', '');
			removeFile('/err.log');
			Module.FS.writeFile('/err.log', '');

			// Open the files as write streams
			fileStream = Module.FS.open('/doc.json', 'w');
			errFileStream = Module.FS.open('/err.log', 'w');

			// Temporarily redirect standard output (fd 1) directly inside the FS layer
			oldStdoutStream = Module.FS.streams[1];
			Module.FS.streams[1] = fileStream;

			// Temporarily redirect standard error (fd 2) directly inside the FS layer
			oldStderrStream = Module.FS.streams[2];
			Module.FS.streams[2] = errFileStream;

			isDocgenRunning = true;

			// Run the compiler docgen task
			try {
				Module.callMain([
					'docgen',
					'--json',
					'--target', 'emscripten',
					'--emit-stdlib=yes',
					'--stdlib', '/usr/lib/c3/std',
					'/main.c3'
				]);
			} catch (exitErr) {
				// Emscripten exit throws ExitStatus; we trap it so the finally block executes cleanly
			}
		} catch (docErr) {
			console.error("[Worker Docgen] Documentation generation failed:", docErr);
			compilationFailed = true;
		} finally {
			isDocgenRunning = false;

			// Force-flush Musl's C-level stdout/stderr streams to ensure all blocks are written to VFS files
			const fflush = Module._fflush || Module['_fflush'];
			if (fflush) {
				try {
					fflush(0);
				} catch (e) { }
			}

			// Restore standard streams so standard compilation reports error outputs to the console as expected
			if (oldStdoutStream) {
				Module.FS.streams[1] = oldStdoutStream;
			}
			if (oldStderrStream) {
				Module.FS.streams[2] = oldStderrStream;
			}

			// Close the streams, finalizing the VFS files
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

		// Handle structural crash state by notifying the main thread to recycle the worker context immediately
		if (compilationFailed) {
			postMessage({ type: 'docgen_failed' });
			return;
		}

		// Read and parse the flushed JSON documentation output
		try {
			const rawJson = Module.FS.readFile('/doc.json', { encoding: 'utf8' });
			removeFile('/doc.json'); // Cleanup
			removeFile('/err.log');  // Discard syntax error logs silently

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

		Module.FS.writeFile('/main.c3', msg.source);
		console.log("[Worker] Written main.c3 into virtual file system.");

		console.log("[Worker] Calling Module.callMain compiler command...");
		const exitCode = Module.callMain([
			'compile',
			'--target', 'emscripten',
			'--linker=builtin',
			'--ansi=no',
			'-o', '/main.wasm',
			'--stdlib', '/usr/lib/c3/std',
			'-L', '/usr/lib/c3/wasm32-emscripten',
			'-l', 'c',
			'-l', 'dlmalloc',
			'-l', 'clang_rt.builtins',
			'-l', 'stubs',
			'-z', '/usr/lib/c3/wasm32-emscripten/libemscripten_js_symbols.so',
			'-z', '--no-entry',
			'-z', '--export=main',
			'-z', '--export=__wasm_call_ctors',
			'-z', '--export-table',
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