// js/audio-runtime.js

let activeAudioContext = null;
let activeScriptNode = null;

export function stopAudioRuntime() {
	if (activeAudioContext) {
		try { activeAudioContext.close(); } catch (e) { }
		activeAudioContext = null;
	}
	if (activeScriptNode) {
		try { activeScriptNode.disconnect(); } catch (e) { }
		activeScriptNode = null;
	}
}

export function resumeAudioIfSuspended() {
	if (activeAudioContext && activeAudioContext.state === 'suspended') {
		activeAudioContext.resume();
	}
}

export function startAudioRuntime(instance) {
	const updateAudioFn = instance.wasmExports?.update_audio;
	if (!updateAudioFn) return;

	console.log("[Audio Runtime] Audio export detected. Starting Web Audio.");
	const AudioCtx = window.AudioContext || window['webkitAudioContext'];
	try {
		activeAudioContext = new AudioCtx({ sampleRate: 44100 });
	} catch (e) {
		activeAudioContext = new AudioCtx();
	}
	resumeAudioIfSuspended();

	const bufferSize = 1024;
	activeScriptNode = activeAudioContext.createScriptProcessor(bufferSize, 0, 1);

	activeScriptNode.onaudioprocess = (e) => {
		if (!instance) return;
		const ptr = updateAudioFn(bufferSize);
		const wasmMem = instance.wasmMemory || instance.wasmExports?.memory || instance.asm?.memory;
		const currentBuffer = wasmMem?.buffer;

		if (currentBuffer && ptr) {
			const wasmBuffer = new Float32Array(currentBuffer, ptr, bufferSize);
			const outputBuffer = e.outputBuffer;
			const channelData = outputBuffer.getChannelData(0);
			channelData.set(wasmBuffer);
		}
	};

	activeScriptNode.connect(activeAudioContext.destination);
}