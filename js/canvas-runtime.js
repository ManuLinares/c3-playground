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

	let pendingEvents = [];
	function addEvent(kind, x, y, wheel, button, key) {
		if (pendingEvents.length < 64) {
			pendingEvents.push({ kind, x: x || 0, y: y || 0, wheel: wheel || 0, button: button || 0, key: key || 0 });
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

	const onMouseMove = (e) => { const c = getCanvasCoords(e); addEvent(1, c.x, c.y, 0, 0, 0); };
	const onMouseDown = (e) => { invalidateCanvasRect(); resumeAudioIfSuspended(); const c = getCanvasCoords(e); addEvent(2, c.x, c.y, 0, e.button, 0); };
	const onMouseUp = (e) => { const c = getCanvasCoords(e); addEvent(3, c.x, c.y, 0, e.button, 0); };
	const onWheel = (e) => { const c = getCanvasCoords(e); addEvent(6, c.x, c.y, e.deltaY > 0 ? -1.0 : 1.0, 0, 0); };

	const getKeyCode = (e) => {
		// Printable characters (a-z, A-Z, 0-9, symbols) return their ASCII/UTF-16 code
		if (e.key.length === 1) return e.key.charCodeAt(0);
		// Special keys (Control, Alt, Super, F1-F12, Arrows, etc.) return their standard key code
		return e.keyCode || 0;
	};

	const onKeyDown = (e) => {
		if (document.activeElement && ['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;
		const k = getKeyCode(e);
		if (k > 0) {
			addEvent(4, 0, 0, 0, 0, k);
			if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) e.preventDefault();
		}
	};

	const onKeyUp = (e) => {
		if (document.activeElement && ['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;
		const k = getKeyCode(e);
		if (k > 0) addEvent(5, 0, 0, 0, 0, k);
	};

	const onContextMenu = (e) => e.preventDefault();

	canvas.addEventListener('mousemove', onMouseMove);
	canvas.addEventListener('mousedown', onMouseDown);
	canvas.addEventListener('mouseup', onMouseUp);
	canvas.addEventListener('wheel', onWheel, { passive: true });
	canvas.addEventListener('contextmenu', onContextMenu);
	window.addEventListener('keydown', onKeyDown);
	window.addEventListener('keyup', onKeyUp);
	window.addEventListener('resize', invalidateCanvasRect);
	document.addEventListener('fullscreenchange', invalidateCanvasRect);

	const canvasResizeObserver = new ResizeObserver(() => invalidateCanvasRect());
	canvasResizeObserver.observe(container);

	const mallocFn = instance.wasmExports?.malloc;
	const freeFn = instance.wasmExports?.free;
	const eventsBufferPtr = mallocFn ? mallocFn(64 * 24) : 0;
	const sliceHeaderPtr = mallocFn ? mallocFn(8) : 0;

	activeInputCleanup = () => {
		canvas.removeEventListener('mousemove', onMouseMove);
		canvas.removeEventListener('mousedown', onMouseDown);
		canvas.removeEventListener('mouseup', onMouseUp);
		canvas.removeEventListener('wheel', onWheel);
		canvas.removeEventListener('contextmenu', onContextMenu);
		window.removeEventListener('keydown', onKeyDown);
		window.removeEventListener('keyup', onKeyUp);
		window.removeEventListener('resize', invalidateCanvasRect);
		document.removeEventListener('fullscreenchange', invalidateCanvasRect);
		canvasResizeObserver.disconnect();
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
				const i32 = new Int32Array(currentBuffer, eventsBufferPtr, eventCount * 6);
				const f32 = new Float32Array(currentBuffer, eventsBufferPtr, eventCount * 6);
				for (let i = 0; i < eventCount; i++) {
					const ev = pendingEvents[i];
					const offset = i * 6;
					i32[offset + 0] = ev.kind;
					f32[offset + 1] = ev.x;
					f32[offset + 2] = ev.y;
					f32[offset + 3] = ev.wheel;
					i32[offset + 4] = ev.button;
					i32[offset + 5] = ev.key;
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
				//ctx2d.putImageData(new ImageData(new Uint8ClampedArray(currentBuffer, ptr, size), width, height), 0, 0);
				cachedImageData.data.set(pixelView);
				ctx2d.putImageData(cachedImageData, 0, 0);
			}
		}

		activeCanvasLoopId = requestAnimationFrame(loop);
	}

	activeCanvasLoopId = requestAnimationFrame(loop);
}