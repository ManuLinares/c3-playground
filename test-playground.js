// test-playground.js
//
// rm -rf build && ./build.sh && node test-playground.js
// or
// ./build.sh && node test-playground.js

const nodeFs = require('fs');
const nodePath = require('path');

// Write the sample C3 code you want to compile and execute
const testCode = `
module main;
import std;

fn void main() {
	io::printn("Hello from the headless C3 browser playground!");
	
	// Test slice & temporary allocation
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

const buildDir = nodePath.join(__dirname, 'build');
if (!nodeFs.existsSync(nodePath.join(buildDir, 'c3c.js')) || !nodeFs.existsSync(nodePath.join(buildDir, 'c3c.wasm'))) {
	console.error("Error: Please run `./build.sh` once first to generate build/ artifacts.");
	process.exit(1);
}

console.log("Loading WebAssembly compiler artifacts...");

const c3cJsText = nodeFs.readFileSync(nodePath.join(buildDir, 'c3c.js'), 'utf8');
const C3EmscriptenRuntime = require('./build/emscripten_runtime.js');

// Save the original working directory so we can restore it later
const originalCwd = process.cwd();

// Temporarily change Node's active working directory to 'build/'
// This ensures Emscripten's fetchRemotePackage can find 'c3c.data' via raw relative reads.
process.chdir(buildDir);

// Define our specific configuration object
const compilerModule = {
	noInitialRun: true,
	
	locateFile(p) {
		return nodePath.join(buildDir, p);
	},
	
	print(text) {
		console.log(`[Compiler STDOUT] ${text}`);
	},
	printErr(text) {
		// Quiet standard Emscripten unflushed streams warning
		if (text.includes("stdio streams had content in them that was not flushed")) return;
		console.error(`[Compiler STDERR] ${text}`);
	},
	onRuntimeInitialized() {
		console.log("WebAssembly compiler engine initialized successfully.");
		
		// Restore the original working directory now that startup is complete
		process.chdir(originalCwd);
		
		runCompilation();
	}
};

// Evaluate the compiler code inside a scoped function.
// By passing our configuration as a parameter named 'Module', we override
// Node's internal 'Module' constructor and prevent startup execution [1].
try {
	const runCompiler = new Function('Module', '__dirname', '__filename', 'require', 'exports', 'module', c3cJsText);
	runCompiler(
		compilerModule,
		buildDir,
		nodePath.join(buildDir, 'c3c.js'),
		require,
		exports,
		module
	);
} catch (e) {
	process.chdir(originalCwd);
	console.error("Failed to load and initialize build/c3c.js:", e);
	process.exit(1);
}

function runCompilation() {
	try {
		console.log("Writing virtual source file /main.c3...");
		try { compilerModule.FS.unlink('/main.c3'); } catch (e) {}
		try { compilerModule.FS.unlink('/main.wasm'); } catch (e) {}

		compilerModule.FS.writeFile('/main.c3', testCode);

		console.log("Compiling...");
		const exitCode = compilerModule.callMain([
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

		if (exitCode !== 0) {
			console.error(`Compilation failed with exit code: ${exitCode}`);
			process.exit(1);
		}

		console.log("Compilation successful! Extracting main.wasm binary...");
		const compiledWasm = compilerModule.FS.readFile('/main.wasm');

		executeCompiledWasm(compiledWasm);

	} catch (err) {
		console.error("Error during compilation execution:", err);
		process.exit(1);
	}
}

function executeCompiledWasm(wasmBuffer) {
	console.log("\nExecuting Compiled WASM via Emscripten User Runtime...");

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
		},
		noInitialRun: true
	}).then(instance => {
		const mainFn = instance.wasmExports?.main || instance.wasmExports?.['__main_argc_argv'];
		if (mainFn) {
			const ret = mainFn(0, 0);
			console.log(`\n[Run complete. Exit code returned: ${ret}]`);
		} else {
			console.error("Error: main function export not found in WASM program.");
		}
	}).catch(err => {
		console.error("WASM program crashed during execution:", err);
	});
}