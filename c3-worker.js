// c3-worker.js
const isNode = typeof process === 'object' && typeof require === 'function';

if (isNode) {
	const path = require('path');
	global.self = global;
	global.require = require;
	global.exports = exports;
	global.module = module;
	global.__dirname = path.join(__dirname, 'build');
	global.__filename = path.join(global.__dirname, 'c3c.js');
}

console.log("[Worker] Worker script loaded and starting...");

let runtimeReady = false;
let originalCwd = null;

let docgenBuffer = [];
let isDocgenRunning = false;

let versionBuffer = [];
let isVersionRunning = false;

const SILENCE_EMSCRIPTEN_STDIO_WARNINGS = false;

const moduleProto = {
	wasmBinary: null,
	cachedData: null
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

// Synchronously intercept FS requests for c3c.data to prevent network fetches
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

function shouldSilenceWarning(text) {
	if (!SILENCE_EMSCRIPTEN_STDIO_WARNINGS) {
		return false;
	}
	return text.includes("stdio streams had content in them that was not flushed") ||
	       text.includes("you should set EXIT_RUNTIME to 1") ||
	       text.includes("this may also be due to not including full filesystem support");
}

Module.print = function (text) {
	if (shouldSilenceWarning(text)) {
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
	if (isDocgenRunning) {
		console.warn("[Worker Intercepted Docgen Stderr] " + text);
		return;
	}

	if (isVersionRunning) {
		versionBuffer.push(text);
		return;
	}

	if (shouldSilenceWarning(text)) {
		console.warn("[Worker Intercepted Warning] " + text);
		return;
	}

	postMessage({ type: 'stderr', text: text + '\n' });
};

Module.onRuntimeInitialized = function () {
	console.log("[Worker] Module.onRuntimeInitialized called!");
	runtimeReady = true;
	
	if (isNode && originalCwd) {
		process.chdir(originalCwd);
	}
	
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

			if (isNode) {
				const path = require('path');
				originalCwd = process.cwd();
				process.chdir(path.join(__dirname, 'build'));
				
				console.log("[Worker] Evaluating c3c.js text in scoped function (Node)...");
				const runCompiler = new Function('Module', '__dirname', '__filename', 'require', 'exports', 'module', msg.c3cJs);
				runCompiler(
					Module,
					global.__dirname,
					global.__filename,
					global.require,
					global.exports,
					global.module
				);
			} else {
				console.log("[Worker] Evaluating c3c.js text in global scope (Browser)...");
				(0, eval)(msg.c3cJs);
			}
			console.log("[Worker] build/c3c.js evaluated successfully.");
		} catch (err) {
			if (isNode && originalCwd) {
				process.chdir(originalCwd);
			}
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
					'--stdlib', '/usr/lib/c3/std',
					'/main.c3'
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
			'-l', 'stubs',
			'-l', 'sockets',
			'-z', '--no-entry',
			'-z', '--export=main',
			'-z', '--export=__wasm_call_ctors',
			'-z', '--export=malloc',
			'-z', '--export=free',
			'-z', '--export=htons',
			'-z', '--export=ntohs',
			'-z', '--export=htonl',
			'-z', '--export=ntohl',
			'-z', '--allow-undefined',
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

// ==========================================
// --- NODE.JS TEST SUITE BINDING LAYER ---
// ==========================================
if (isNode) {
	const fs = require('fs');
	const path = require('path');
	const buildDir = path.join(__dirname, 'build');

	if (!fs.existsSync(path.join(buildDir, 'c3c.js')) || !fs.existsSync(path.join(buildDir, 'c3c.wasm'))) {
		console.error("Error: Please run `./build.sh` once first to generate build/ artifacts.");
		process.exit(1);
	}

	console.log("[Node] Initializing unified offline test harness...");

	const testCode = `
	module main;
	import std;

	fn void main() {
		io::printn("Hello from the headless C3 browser playground!");
		
		@pool() {
			double[] temp_vals = mem::temp_array(double, 3);
			temp_vals[0] = 3.14159;
			temp_vals[1] = 2.71828;
			temp_vals[2] = 1.61803;
			
			foreach (idx, val : temp_vals) {
				io::printfn("temp_vals[%d] = %.5f", idx, val);
			}
		};
	}
	`;

	const c3cJsText = fs.readFileSync(path.join(buildDir, 'c3c.js'), 'utf8');
	const c3cWasmBuffer = fs.readFileSync(path.join(buildDir, 'c3c.wasm'));
	const c3cDataBuffer = fs.readFileSync(path.join(buildDir, 'c3c.data'));

	const c3cDataArrayBuffer = c3cDataBuffer.buffer.slice(
		c3cDataBuffer.byteOffset,
		c3cDataBuffer.byteOffset + c3cDataBuffer.byteLength
	);

	// Intercept postMessage for terminal reporting
	global.postMessage = function (msg) {
		if (msg.type === 'ready') {
			console.log("[Node] Compiler ready. Dispatching test compile event...");
			self.onmessage({
				data: {
					type: 'compile',
					source: testCode
				}
			});
		} else if (msg.type === 'stdout') {
			process.stdout.write(`[Compiler STDOUT] ${msg.text}`);
		} else if (msg.type === 'stderr') {
			process.stderr.write(`[Compiler STDERR] ${msg.text}`);
		} else if (msg.type === 'compiled') {
			console.log(`\n[Node] Compilation successful! (${msg.wasm.byteLength} bytes)`);
			runUserProgram(msg.wasm);
		} else if (msg.type === 'failed') {
			console.error("\n[Node] Compilation failed:", msg.error);
			process.exit(1);
		}
	};

	function runUserProgram(wasmBuffer) {
		console.log("\nExecuting Compiled WASM via Emscripten User Runtime...");
		const C3EmscriptenRuntime = require(path.join(buildDir, 'emscripten_runtime.js'));

		C3EmscriptenRuntime({
			wasmBinary: wasmBuffer,
			print(text) {
				console.log(`[USER PROGRAM] ${text}`);
			},
			printErr(text) {
				console.error(`[USER ERR] ${text}`);
			},
			onExit(code) {
				console.log(`[USER EXIT] Code: ${code}`);
				process.exit(code); // Propagate user program exit code to shell for CI testing [2]
			},
			noInitialRun: true
		}).then(instance => {
			const mainFn = instance.wasmExports?.main || instance.wasmExports?.['__main_argc_argv'];
			if (mainFn) {
				const ret = mainFn(0, 0);
				console.log(`\n[Run complete. Exit code returned: ${ret}]`);
			} else {
				console.error("Error: main function export not found in WASM program.");
				process.exit(1);
			}
		}).catch(err => {
			console.error("WASM program crashed during execution:", err);
			process.exit(1);
		});
	}

	WebAssembly.compile(c3cWasmBuffer).then(wasmModule => {
		self.onmessage({
			data: {
				type: 'init_module',
				wasmModule: wasmModule,
				c3cJs: c3cJsText,
				c3cData: c3cDataArrayBuffer
			}
		});
	}).catch(err => {
		console.error("[Node] Failed to compile c3c.wasm:", err);
		process.exit(1);
	});
}