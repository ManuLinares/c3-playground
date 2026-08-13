// js/canvas-runtime.js
import { resumeAudioIfSuspended } from './audio-runtime.js';

let activeCanvasLoopId = null;
let activeInputCleanup = null;

export function stopCanvasRuntime() {
	const container = document.getElementById("canvasContainer");
	if (container) container.style.display = "none";

	if (activeCanvasLoopId) {
		cancelAnimationFrame(activeCanvasLoopId);
		activeCanvasLoopId = null;
	}
	if (activeInputCleanup) {
		activeInputCleanup();
		activeInputCleanup = null;
	}
}

function createWebGLRenderer(canvas, width, height) {
	const gl = canvas.getContext("webgl", { alpha: false, depth: false, antialias: false }) ||
		canvas.getContext("experimental-webgl");
	if (!gl) return null;

	const vs = `attribute vec2 a_p; attribute vec2 a_t; varying vec2 v_t; void main(){ gl_Position=vec4(a_p,0,1); v_t=a_t; }`;
	const fs = `precision mediump float; uniform sampler2D u_t; varying vec2 v_t; void main(){ gl_FragColor=texture2D(u_t, v_t); }`;

	function compileShader(type, src) {
		const s = gl.createShader(type);
		gl.shaderSource(s, src);
		gl.compileShader(s);
		return s;
	}

	const prog = gl.createProgram();
	gl.attachShader(prog, compileShader(gl.VERTEX_SHADER, vs));
	gl.attachShader(prog, compileShader(gl.FRAGMENT_SHADER, fs));
	gl.linkProgram(prog);
	gl.useProgram(prog);

	const verts = new Float32Array([-1, -1, 0, 1, 1, -1, 1, 1, -1, 1, 0, 0, 1, 1, 1, 0]);
	const buf = gl.createBuffer();
	gl.bindBuffer(gl.ARRAY_BUFFER, buf);
	gl.bufferData(gl.ARRAY_BUFFER, verts, gl.STATIC_DRAW);

	const posLoc = gl.getAttribLocation(prog, "a_p");
	const texLoc = gl.getAttribLocation(prog, "a_t");
	gl.enableVertexAttribArray(posLoc);
	gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 16, 0);
	gl.enableVertexAttribArray(texLoc);
	gl.vertexAttribPointer(texLoc, 2, gl.FLOAT, false, 16, 8);

	const tex = gl.createTexture();
	gl.bindTexture(gl.TEXTURE_2D, tex);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
	gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
	gl.viewport(0, 0, width, height);

	return {
		render(pixelBuffer) {
			gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixelBuffer);
			gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		}
	};
}

export const EVENT_KIND = {
	NONE: 0,
	MOUSE_MOVE: 1,
	MOUSE_DOWN: 2,
	MOUSE_UP: 3,
	MOUSE_WHEEL: 4,
	KEY_DOWN: 5,
	KEY_UP: 6,
	CHAR_INPUT: 7
};

// Must match sizeof(Event) in C3: 7 x 32-bit fields (kind, mouse_pos.x, mouse_pos.y, wheel, mouse_button, key, character)
const EVENT_STRUCT_BYTES = 7 * 4;
const MAX_EVENTS = 65536;

export function startCanvasRuntime(instance) {
	const updateCanvasFn = instance.wasmExports?.update_canvas;
	if (!updateCanvasFn) return;

	console.log("[Canvas Runtime] Canvas export detected. Starting render loop.");
	const canvas = document.getElementById("canvas");
	const container = document.getElementById("canvasContainer");
	const width = 640, height = 480;

	container.style.display = "block";
	void container.offsetHeight;

	canvas.width = width;
	canvas.height = height;

	let cachedCanvasRect = null;
	const invalidateCanvasRect = () => { cachedCanvasRect = null; };

	let webglRenderer = createWebGLRenderer(canvas, width, height);
	let ctx2d = webglRenderer ? null : canvas.getContext("2d");
	let cachedImageData = ctx2d ? ctx2d.createImageData(width, height) : null;

	window.dispatchEvent(new Event('resize'));

	// Invisible Textarea for Native OS Text Composition (Dead Keys, Accents, AltGr, IME)
	let hiddenInput = document.getElementById("canvasHiddenInput");
	if (!hiddenInput) {
		hiddenInput = document.createElement("textarea");
		hiddenInput.id = "canvasHiddenInput";
		hiddenInput.style.cssText = "position:fixed; opacity:0; width:1px; height:1px; top:0; left:0; z-index:-1; pointer-events:none;";
		hiddenInput.autocomplete = "off";
		hiddenInput.autocorrect = "off";
		hiddenInput.autocapitalize = "off";
		hiddenInput.spellcheck = false;
		document.body.appendChild(hiddenInput);
	}

	let pendingEvents = [];
	function addEvent(kind, x, y, wheel, button, key, character) {
		if (pendingEvents.length < MAX_EVENTS) {
			pendingEvents.push({
				kind,
				x: x || 0,
				y: y || 0,
				wheel: wheel || 0,
				button: button || 0,
				key: key || 0,
				character: character || 0
			});
		}
	}

	function getCanvasCoords(e) {
		if (!cachedCanvasRect) cachedCanvasRect = canvas.getBoundingClientRect();
		const rect = cachedCanvasRect;
		const aspect = width / height;
		const containerAspect = rect.width / rect.height;

		let renderW = rect.width, renderH = rect.height;
		let offsetX = 0, offsetY = 0;

		if (containerAspect > aspect) {
			renderW = rect.height * aspect;
			offsetX = (rect.width - renderW) / 2;
		} else {
			renderH = rect.width / aspect;
			offsetY = (rect.height - renderH) / 2;
		}

		if (renderW <= 0 || renderH <= 0) return { x: 0, y: 0 };
		const relX = e.clientX - rect.left - offsetX;
		const relY = e.clientY - rect.top - offsetY;

		return {
			x: Math.max(0, Math.min(width, (relX / renderW) * width)),
			y: Math.max(0, Math.min(height, (relY / renderH) * height))
		};
	}

	const focusHiddenInput = () => {
		try { hiddenInput.focus(); } catch (e) { }
	};

	const isExternalInputFocused = () => {
		return document.activeElement &&
			['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName) &&
			document.activeElement !== hiddenInput;
	};

	const onMouseMove = (e) => { const c = getCanvasCoords(e); addEvent(EVENT_KIND.MOUSE_MOVE, c.x, c.y, 0, 0, 0, 0); };
	const onMouseDown = (e) => {
		invalidateCanvasRect();
		resumeAudioIfSuspended();
		// Re-focus after browser's default click cycle finishes
		setTimeout(focusHiddenInput, 0);
		const c = getCanvasCoords(e);
		addEvent(EVENT_KIND.MOUSE_DOWN, c.x, c.y, 0, e.button, 0, 0);
	};
	const onMouseUp = (e) => { const c = getCanvasCoords(e); addEvent(EVENT_KIND.MOUSE_UP, c.x, c.y, 0, e.button, 0, 0); };
	const onWheel = (e) => { const c = getCanvasCoords(e); addEvent(EVENT_KIND.MOUSE_WHEEL, c.x, c.y, e.deltaY > 0 ? -1.0 : 1.0, 0, 0, 0); };

	// Standard GLFW Virtual Keycodes (>= 256 for non-printable control keys)
	const VIRTUAL_KEY_MAP = {
		'Backspace': 259, 'Tab': 258, 'Enter': 257, 'Escape': 256,
		'Delete': 261, 'Insert': 260, 'PageUp': 266, 'PageDown': 267,
		'End': 269, 'Home': 268, 'ArrowLeft': 263, 'ArrowUp': 265,
		'ArrowRight': 262, 'ArrowDown': 264, 'Shift': 340, 'Control': 341,
		'Alt': 342, 'AltGraph': 346, 'Meta': 343, 'CapsLock': 280,
		'NumLock': 282, 'ScrollLock': 281,
		'F1': 290, 'F2': 291, 'F3': 292, 'F4': 293, 'F5': 294, 'F6': 295,
		'F7': 296, 'F8': 297, 'F9': 298, 'F10': 299, 'F11': 300, 'F12': 301
	};

	// Non-printable keys that scroll the page or shift focus
	const NAV_PREVENT_DEFAULT = new Set([
		'Tab', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'PageUp', 'PageDown',
		'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11'
	]);

	const getVirtualKey = (e) => {
		if (!e || !e.key) return e?.keyCode || 0;
		if (VIRTUAL_KEY_MAP[e.key] !== undefined) return VIRTUAL_KEY_MAP[e.key];
		if (e.key.length === 1 && e.key !== 'Dead') {
			return /^[a-zA-Z]$/.test(e.key) ? e.key.toUpperCase().charCodeAt(0) : e.key.charCodeAt(0);
		}
		return e.keyCode || 0;
	};

	// Text Composition Handler (Processes dead keys, accents, AltGr, IME)
	const onBeforeInput = (e) => {
		if (e.isComposing || e.inputType === 'insertCompositionText' || e.inputType === 'insertFromPaste') return;
		if (e.data) {
			for (const char of e.data) {
				if (char === '\r') continue;
				const cp = char.codePointAt(0);
				if (cp) addEvent(EVENT_KIND.CHAR_INPUT, 0, 0, 0, 0, getVirtualKey({ key: char }), cp);
			}
		}
		setTimeout(() => { hiddenInput.value = ""; }, 0);
	};

	const onCopy = (e) => {
		const getClipboardFn = instance.wasmExports?.get_clipboard_text;
		if (getClipboardFn) {
			const ptr = getClipboardFn();
			if (ptr) {
				const wasmMem = instance.wasmMemory || instance.wasmExports?.memory || instance.asm?.memory;
				if (wasmMem?.buffer) {
					const u8 = new Uint8Array(wasmMem.buffer, ptr);
					let end = 0;
					while (u8[end] !== 0 && end < 512 * 1024) end++;
					if (end > 0) {
						const str = new TextDecoder().decode(u8.subarray(0, end));
						e.clipboardData?.setData('text/plain', str);
						e.preventDefault();
					}
				}
			}
		}
	};

	const onCut = (e) => {
		onCopy(e);
	};

	const onPaste = (e) => {
		const text = e.clipboardData?.getData('text/plain');
		if (text) {
			for (const char of text) {
				if (char === '\r') continue;
				const cp = char.codePointAt(0);
				if (cp) addEvent(EVENT_KIND.CHAR_INPUT, 0, 0, 0, 0, getVirtualKey({ key: char }), cp);
			}
			e.preventDefault();
			setTimeout(() => { hiddenInput.value = ""; }, 0);
		}
	};

	const onKeyDown = (e) => {
		if (isExternalInputFocused()) return;
		
		const k = getVirtualKey(e);
		if (k > 0) {
			addEvent(EVENT_KIND.KEY_DOWN, 0, 0, 0, 0, k, 0);

			if (NAV_PREVENT_DEFAULT.has(e.key)) {
				e.preventDefault();
			}
		}
	};

	const onKeyUp = (e) => {
		if (isExternalInputFocused()) return;
		const k = getVirtualKey(e);
		if (k > 0) {
			addEvent(EVENT_KIND.KEY_UP, 0, 0, 0, 0, k, 0);
			if (e.key === 'Tab') e.preventDefault();
		}
	};

	const onContextMenu = (e) => e.preventDefault();

	const onFullscreenChange = () => {
		invalidateCanvasRect();
		setTimeout(focusHiddenInput, 0);
	};

	canvas.addEventListener('mousemove', onMouseMove);
	canvas.addEventListener('mousedown', onMouseDown);
	canvas.addEventListener('mouseup', onMouseUp);
	canvas.addEventListener('wheel', onWheel, { passive: true });
	canvas.addEventListener('contextmenu', onContextMenu);
	hiddenInput.addEventListener('beforeinput', onBeforeInput);
	hiddenInput.addEventListener('copy', onCopy);
	hiddenInput.addEventListener('cut', onCut);
	hiddenInput.addEventListener('paste', onPaste);
	window.addEventListener('keydown', onKeyDown);
	window.addEventListener('keyup', onKeyUp);
	window.addEventListener('resize', invalidateCanvasRect);
	document.addEventListener('fullscreenchange', onFullscreenChange);

	const canvasResizeObserver = new ResizeObserver(() => invalidateCanvasRect());
	canvasResizeObserver.observe(container);

	focusHiddenInput();

	const mallocFn = instance.wasmExports?.malloc;
	const freeFn = instance.wasmExports?.free;
	// Allocates buffer for MAX_EVENTS events x EVENT_STRUCT_BYTES each
	const eventsBufferPtr = mallocFn ? mallocFn(MAX_EVENTS * EVENT_STRUCT_BYTES) : 0;
	const sliceHeaderPtr = mallocFn ? mallocFn(8) : 0;

	activeInputCleanup = () => {
		canvas.removeEventListener('mousemove', onMouseMove);
		canvas.removeEventListener('mousedown', onMouseDown);
		canvas.removeEventListener('mouseup', onMouseUp);
		canvas.removeEventListener('wheel', onWheel);
		canvas.removeEventListener('contextmenu', onContextMenu);
		hiddenInput.removeEventListener('beforeinput', onBeforeInput);
		hiddenInput.removeEventListener('copy', onCopy);
		hiddenInput.removeEventListener('cut', onCut);
		hiddenInput.removeEventListener('paste', onPaste);
		window.removeEventListener('keydown', onKeyDown);
		window.removeEventListener('keyup', onKeyUp);
		window.removeEventListener('resize', invalidateCanvasRect);
		document.removeEventListener('fullscreenchange', onFullscreenChange);
		canvasResizeObserver.disconnect();

		if (hiddenInput && hiddenInput.parentNode) {
			hiddenInput.parentNode.removeChild(hiddenInput);
		}

		if (freeFn) {
			if (eventsBufferPtr) freeFn(eventsBufferPtr);
			if (sliceHeaderPtr) freeFn(sliceHeaderPtr);
		}
	};

	let lastFrameTime = performance.now();

	function loop(currentTime) {
		if (!instance) return;
		const dt = Math.min((currentTime - lastFrameTime) / 1000.0, 0.1);
		lastFrameTime = currentTime;

		const eventCount = pendingEvents.length;
		const wasmMem = instance.wasmMemory || instance.wasmExports?.memory || instance.asm?.memory;
		let currentBuffer = wasmMem?.buffer;

		if (currentBuffer && eventsBufferPtr) {
			if (eventCount > 0) {
				const i32 = new Int32Array(currentBuffer, eventsBufferPtr, eventCount * 7);
				const f32 = new Float32Array(currentBuffer, eventsBufferPtr, eventCount * 7);
				for (let i = 0; i < eventCount; i++) {
					const ev = pendingEvents[i];
					const offset = i * 7;
					i32[offset + 0] = ev.kind;
					f32[offset + 1] = ev.x;
					f32[offset + 2] = ev.y;
					f32[offset + 3] = ev.wheel;
					i32[offset + 4] = ev.button;
					i32[offset + 5] = ev.key;
					i32[offset + 6] = ev.character;
				}
				pendingEvents.length = 0;
			}

			if (sliceHeaderPtr) {
				const headerView = new Int32Array(currentBuffer, sliceHeaderPtr, 2);
				headerView[0] = eventsBufferPtr;
				headerView[1] = eventCount;
			}
		}

		let ptr = updateCanvasFn.length === 4
			? updateCanvasFn(width, height, dt, sliceHeaderPtr)
			: updateCanvasFn(width, height, dt);

		currentBuffer = wasmMem?.buffer;

		if (currentBuffer && ptr) {
			const size = width * height * 4;
			const pixelView = new Uint8Array(currentBuffer, ptr, size);
			if (webglRenderer) {
				webglRenderer.render(pixelView);
			} else if (ctx2d) {
				cachedImageData.data.set(pixelView);
				ctx2d.putImageData(cachedImageData, 0, 0);
			}
		}

		activeCanvasLoopId = requestAnimationFrame(loop);
	}

	activeCanvasLoopId = requestAnimationFrame(loop);
}