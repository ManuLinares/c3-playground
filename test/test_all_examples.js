const nodeFs = require('fs');
const nodePath = require('path');
const { execFileSync } = require('child_process');

const targetFile = process.argv[2];
const playgroundDir = nodePath.resolve(__dirname, '..');
const buildDir = nodePath.join(playgroundDir, 'build');
const examplesDir = nodePath.join(playgroundDir, 'examples');

if (targetFile) {
	// Single file compilation mode
	const c3cJsText = nodeFs.readFileSync(nodePath.join(buildDir, 'c3c.js'), 'utf8');
	const c3cWasmBuffer = nodeFs.readFileSync(nodePath.join(buildDir, 'c3c.wasm'));
	const c3cDataBuffer = nodeFs.readFileSync(nodePath.join(buildDir, 'c3c.data'));

	const c3cDataArrayBuffer = c3cDataBuffer.buffer.slice(
		c3cDataBuffer.byteOffset,
		c3cDataBuffer.byteOffset + c3cDataBuffer.byteLength
	);

	const moduleProto = {
		wasmBinary: c3cWasmBuffer,
		cachedData: c3cDataArrayBuffer
	};

	var Module = Object.create(moduleProto);
	Module.noInitialRun = true;
	Module.preRun = [];
	Module.postRun = [];
	Module.instantiateWasm = function (imports, successCallback) {
		const isModule = Module.wasmBinary instanceof WebAssembly.Module;
		WebAssembly.instantiate(Module.wasmBinary, imports).then(output => {
			const instance = isModule ? output : output.instance;
			successCallback(instance);
		}).catch(err => {
			console.error(err);
		});
		return {};
	};
	Module.getPreloadedPackage = function (remotePackageName) {
		if (remotePackageName.endsWith('c3c.data')) return moduleProto.cachedData;
		return null;
	};
	Module.locateFile = function (p) {
		if (p.endsWith('.data')) return nodePath.join(buildDir, 'c3c.data');
		if (p.endsWith('.wasm')) return nodePath.join(buildDir, 'c3c.wasm');
		return p;
	};

	let currentOutput = '';
	Module.print = (t) => { currentOutput += t + '\n'; };
	Module.printErr = (t) => { currentOutput += t + '\n'; };

	Module.onRuntimeInitialized = function () {
		const code = nodeFs.readFileSync(nodePath.join(examplesDir, targetFile), 'utf-8');
		Module.FS.writeFile('/tmp/test.c3', code);

		const args = [
			'compile',
			'--max-mem', '128',
			'--target', 'emscripten',
			'--linker=builtin',
			'--ansi=no',
			'-o', '/tmp/test.wasm',
			'--stdlib', '/usr/lib/c3/std',
			'--libdir', '/usr/lib/c3/lib',
			'--lib', 'raylib6',
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
			'/tmp/test.c3'
		];

		const exitCode = Module.callMain(args);

		if (exitCode === 0 && Module.FS.analyzePath('/tmp/test.wasm').exists) {
			const wasmSize = Module.FS.stat('/tmp/test.wasm').size;
			console.log(`[PASS] ${targetFile} (WASM size: ${wasmSize} bytes)`);
			process.exit(0);
		} else {
			console.error(`[FAIL] ${targetFile} (Exit code: ${exitCode})`);
			console.error(currentOutput);
			process.exit(1);
		}
	};

	global.Module = Module;
	eval(c3cJsText);
} else {
	// Runner mode
	function getC3Files(dir, base = '') {
		let results = [];
		const entries = nodeFs.readdirSync(dir, { withFileTypes: true });
		for (const entry of entries) {
			const rel = base ? `${base}/${entry.name}` : entry.name;
			const full = nodePath.join(dir, entry.name);
			if (entry.isDirectory()) {
				results = results.concat(getC3Files(full, rel));
			} else if (entry.isFile() && entry.name.endsWith('.c3')) {
				results.push(rel);
			}
		}
		return results;
	}

	const files = getC3Files(examplesDir).sort();

	console.log(`Testing all ${files.length} examples...`);

	for (const f of files) {
		try {
			const out = execFileSync(process.execPath, [__filename, f], { encoding: 'utf-8' });
			process.stdout.write(out);
		} catch (err) {
			console.error(`Failed on ${f}:`);
			console.error(err.stdout || err.stderr || err.message);
			process.exit(1);
		}
	}

	console.log(`\n🎉 ALL ${files.length} EXAMPLES COMPILED TO WASM SUCCESSFULLY!`);
}
