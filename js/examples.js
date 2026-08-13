// js/examples.js

export const EXAMPLES_MANIFEST = [
	{ id: "hello_world",          name: "Hello World",                                   file: "examples/01_Hello_World.c3" },
	{ id: "slices_and_defer",     name: "Slices & Defer",                                file: "examples/02_Slices___Defer.c3" },
	{ id: "reflection",           name: "Reflection",                                    file: "examples/03_Reflection.c3" },
	{ id: "json_pretty_print",    name: "JSON Pretty Print",                             file: "examples/04_JSON_Pretty_Print.c3" },
	{ id: "simd_vectors",         name: "SIMD Vectors",                                  file: "examples/05_SIMD_Vectors.c3" },
	{ id: "error_handling",       name: "Error Handling",                                file: "examples/06_Error_Handling.c3" },
	{ id: "bitstructs",           name: "Bitstructs",                                    file: "examples/07_Bitstructs.c3" },
	{ id: "brainfuck",            name: "Brainfuck interpreter",                         file: "examples/08_Brainfuck_interpreter.c3" },
	{ id: "psychedelic_vortex",   name: "Psychedelic Vortex Canvas",                     file: "examples/09_Psychedelic_Vortex_Canvas.c3" },
	{ id: "fm_synthesizer",       name: "Retro FM Synthesizer",                          file: "examples/10_Retro_FM_Synthesizer.c3" },
	{ id: "audio_and_canvas",     name: "Audio and Canvas",                              file: "examples/11_Audio_and_Canvas.c3" },
	{ id: "voxelspace",           name: "VoxelSpace Flight Simulator + Synthwave Beats", file: "examples/12_VoxelSpace_Flight_Simulator___Synthwave_Beats_V2.c3" },
	{ id: "interactive_canvas",   name: "Interactive Canvas & Input",                    file: "examples/13_Interactive_Canvas___Input.c3" },
	{ id: "neon_overdrive",       name: "NEON OVERDRIVE: CYBER ARENA",                   file: "examples/14_NEON_OVERDRIVE__CYBER_ARENA.c3" },
	{ id: "piano",                name: "Piano",                                         file: "examples/15_Piano.c3" },
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