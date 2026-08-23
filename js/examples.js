import { parseAssetDirectives, fetchAssets } from './assets.js';

export const EXAMPLES_MANIFEST = [
	// 1. Tutorials (Pure C3, no graphics — simple → complex)
	{ id: "hello_world",          category: "Tutorials", name: "Hello World",              file: "examples/tutorials/01_hello_world.c3" },
	{ id: "slices_and_defer",     category: "Tutorials", name: "Slices & Defer",           file: "examples/tutorials/02_slices_and_defer.c3" },
	{ id: "reflection",           category: "Tutorials", name: "Reflection",               file: "examples/tutorials/03_reflection.c3" },
	{ id: "error_handling",       category: "Tutorials", name: "Error Handling",           file: "examples/tutorials/04_error_handling.c3" },
	{ id: "json_pretty_print",    category: "Tutorials", name: "JSON Pretty Print",        file: "examples/tutorials/05_json_pretty_print.c3" },
	{ id: "bitstructs",           category: "Tutorials", name: "Bitstructs",               file: "examples/tutorials/06_bitstructs.c3" },
	{ id: "simd_vectors",         category: "Tutorials", name: "SIMD Vectors",             file: "examples/tutorials/07_simd_vectors.c3" },
	{ id: "brainfuck",            category: "Tutorials", name: "Brainfuck Interpreter",    file: "examples/tutorials/08_brainfuck_interpreter.c3" },

	// 2. Examples (Raylib demos — simple → complex)
	{ id: "raylib_beep",          category: "Examples",  name: "Beep & Draw",              file: "examples/examples/01_raylib_beep.c3" },
	{ id: "particles_and_input",  category: "Examples",  name: "Particles & Input",        file: "examples/examples/02_particles_and_input.c3" },
	{ id: "raylib_3d_camera",     category: "Examples",  name: "3D FPS Camera",            file: "examples/examples/03_raylib_3d_camera.c3" },
	{ id: "shader_vortex",        category: "Examples",  name: "GLSL Shader Vortex",       file: "examples/examples/04_shader_vortex.c3" },
	{ id: "audio_visualizer",     category: "Examples",  name: "Audio Visualizer",         file: "examples/examples/05_audio_visualizer.c3" },
	{ id: "fm_synthesizer",       category: "Examples",  name: "FM Synthesizer",           file: "examples/examples/06_fm_synthesizer.c3" },
	{ id: "voxelspace_synthwave", category: "Examples",  name: "VoxelSpace + Synthwave",   file: "examples/examples/07_voxelspace_synthwave.c3" },
	{ id: "earth_explorer",       category: "Examples",  name: "Earth Explorer (3D)",      file: "examples/examples/08_earth_explorer.c3" },

	// 3. Games
	{ id: "neon_overdrive",       category: "Games",     name: "Neon Overdrive",           file: "examples/games/01_neon_overdrive.c3" },
	{ id: "snake",                category: "Games",     name: "Snake",                    file: "examples/games/02_snake.c3" },

	// 4. Apps
	{ id: "piano",                category: "Apps",      name: "Piano & MIDI Recorder",    file: "examples/apps/01_piano.c3" },
	{ id: "text_editor",          category: "Apps",      name: "Text Editor",              file: "examples/apps/02_text_editor.c3" },

	// 5. AI
	{ id: "neural_engine",        category: "AI",        name: "Neural Engine (karpathy/tinyllamas)", file: "examples/apps/01_neural_engine.c3" },
];

const cache = new Map();

export async function fetchExampleCode(fileUrl) {
	if (cache.has(fileUrl)) return cache.get(fileUrl);
	const res = await fetch(fileUrl);
	if (!res.ok) throw new Error(`Failed to fetch example at ${fileUrl}`);
	const text = await res.text();
	cache.set(fileUrl, text);
	return text;
}

// Background prefetch for all examples and their @asset dependencies to make switching instant
export function prefetchAllExamples() {
	const prefetch = async () => {
		for (const ex of EXAMPLES_MANIFEST) {
			try {
				let code = cache.get(ex.file);
				if (!code) {
					code = await fetchExampleCode(ex.file);
				}
				if (code) {
					const assets = parseAssetDirectives(code);
					if (assets.length > 0) {
						fetchAssets(assets).catch(() => {});
					}
				}
			} catch (_) {}
		}
	};

	if (typeof window !== "undefined" && "requestIdleCallback" in window) {
		window.requestIdleCallback(prefetch, { timeout: 2000 });
	} else {
		setTimeout(prefetch, 500);
	}
}