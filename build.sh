#!/usr/bin/env bash
set -euo pipefail

BUILD_TYPE="${1:-Debug}"
LLVM_TAG="${2:-latest}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#PROJECT_ROOT="${HOME}/scripts/c3c" # local debugging
PROJECT_ROOT="${SCRIPT_DIR}/c3c"
BUILD_DIR="${SCRIPT_DIR}/build"
SYS_LIB_DIR="${BUILD_DIR}/wasm32-emscripten"
DIST_DIR="${SCRIPT_DIR}/dist"
HOST_LIB_DIR="${PROJECT_ROOT}/lib"
RAYLIB_LIB="${SCRIPT_DIR}/lib/raylib6.c3l"

echo "Build Type:     ${BUILD_TYPE}"
echo "LLVM Tag:       ${LLVM_TAG}"
echo "Project Root:   ${PROJECT_ROOT}"
echo "Build Output:   ${BUILD_DIR}"
echo "Dist Directory: ${DIST_DIR}"
echo "Raylib Library: ${RAYLIB_LIB}"

# 1. Build and copy Emscripten system static archives for C3 builtin linker
mkdir -p "${SYS_LIB_DIR}"
embuilder build libc libdlmalloc libstubs libsockets libclang_rt.builtins

EM_CACHE="$(em-config CACHE)"
EM_CACHE_DIR="${EM_CACHE}/sysroot/lib/wasm32-emscripten"

for lib in libc.a libdlmalloc.a libstubs.a libsockets.a libclang_rt.builtins.a; do
  if [ -f "${EM_CACHE_DIR}/${lib}" ]; then
    cp "${EM_CACHE_DIR}/${lib}" "${SYS_LIB_DIR}/"
  else
    echo "Warning: ${lib} not found in ${EM_CACHE_DIR}"
  fi
done

# Create a dummy libm.a placeholder.
# Ensure any old, copied libm.a is completely deleted,
# as 'emar rcs' will append to an existing archive rather than overwrite it.
rm -f "${SYS_LIB_DIR}/libm.a"
echo "int __dummy_libm;" > "${SYS_LIB_DIR}/dummy_m.c"
emcc -c "${SYS_LIB_DIR}/dummy_m.c" -o "${SYS_LIB_DIR}/dummy_m.o"
emar rcs "${SYS_LIB_DIR}/libm.a" "${SYS_LIB_DIR}/dummy_m.o"
rm -f "${SYS_LIB_DIR}/dummy_m.c" "${SYS_LIB_DIR}/dummy_m.o"

# 2. Configure and compile c3c to WebAssembly
emcmake cmake -B "${BUILD_DIR}" -S "${PROJECT_ROOT}" -G Ninja \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DC3_WITH_LLVM=ON \
  -DC3_FETCH_LLVM=ON \
  -DC3_LLVM_TAG="${LLVM_TAG}" \
  -DC3_LINK_DYNAMIC=OFF \
  -DC3_ENABLE_CLANGD_LSP=OFF \
  -DC3_AVR_DISABLE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=OFF \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
  -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sFORCE_FILESYSTEM=1 -sEXIT_RUNTIME=0 -sINITIAL_MEMORY=256MB -sSTACK_SIZE=8MB -sERROR_ON_UNDEFINED_SYMBOLS=0 -sEXPORTED_RUNTIME_METHODS=FS,callMain -sEXPORTED_FUNCTIONS=_main,_fflush --preload-file ${HOST_LIB_DIR}@/usr/lib/c3 --preload-file ${SYS_LIB_DIR}@/usr/lib/c3/wasm32-emscripten --preload-file ${RAYLIB_LIB}@/usr/lib/c3/lib/raylib6.c3l"

cmake --build "${BUILD_DIR}"

# 3. Build standalone Emscripten runtime JS glue (with GLFW3 and WebGL2 support)
echo "Building standalone Emscripten runtime JS glue..."
emcc -xc /dev/null -o "${BUILD_DIR}/emscripten_runtime.js" \
  -s INCLUDE_FULL_LIBRARY=1 \
  -s LINKABLE=1 \
  -s ASSERTIONS=0 \
  -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
  -s FORCE_FILESYSTEM=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXIT_RUNTIME=0 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME=C3EmscriptenRuntime \
  -s INCOMING_MODULE_JS_API="['wasmBinary','print','printErr','onExit','noInitialRun','canvas']" \
  -s USE_GLFW=3 \
  -s USE_WEBGL2=1

# Clean up the dummy .wasm file generated from /dev/null compilation (the runtime uses user-provided wasmBinary)
rm -f "${BUILD_DIR}/emscripten_runtime.wasm"

# Post-process emscripten_runtime.js - four patches that cannot be replaced by emcc flags:
#
#  PATCH 1 - Dynamic EM_ASM proxy:
#    Emscripten's native EM_ASM requires emcc to extract JS snippets at link-time into a
#    static ASM_CONSTS[addr] table. Raylib compiled by c3c's builtin linker instead passes
#    the JS source as a plain char* (wasm memory pointer), which the native table lookup
#    cannot handle. We intercept wasmImports with a Proxy that dispatches through
#    runDynamicEmAsm(), executing the JS string via new Function(). The Proxy also stubs
#    SetCanvasIdJs, glfwGetProcAddress, implements Raylib's Web Clipboard API
#    (__asyncjs__RequestClipboardData / GetLastPastedText), and silently returns 0
#    for any other missing import.
#
#  PATCH 2 - syncHeapGlobals on memory growth:
#    The dynamic EM_ASM snippets run inside new Function() - a detached scope with no access
#    to the module-local HEAP8/HEAP32/... typed array views. After every WASM memory.grow,
#    we re-pin those views onto globalThis so EM_ASM code can read/write WASM memory.
#
#  PATCH 3 - miniaudio Web Audio bridge:
#    miniaudio's AudioWorkletProcessor calls back into WASM via globalThis._ma_device_*.
#    Emscripten's -s EXPORTED_FUNCTIONS only exposes symbols as Module._ma_*, not on
#    globalThis, so the AudioWorklet cannot reach them. We wire the exports manually after
#    createWasm() resolves. Also exposes Module.cancelMainLoop / pauseMainLoop aliases.
#
#  PATCH 4 - GLFW keyboard listeners redirected to canvas:
#    upstream libglfw.js hardcodes window.addEventListener('keydown/keyup/keypress', ...).
#    In this app multiple canvases can coexist; keyboard events must be scoped to the
#    focused canvas, not the window. We also add the missing GLFW charFunc dispatch for
#    printable characters (dead keys, backticks, etc.) that upstream onKeydown omits.
python3 - << 'PY_EOF' "${BUILD_DIR}/emscripten_runtime.js"
import sys

out_path = sys.argv[1]
with open(out_path, "r") as f:
    content = f.read()

proxy_patch = """
var syncHeapGlobals = function() {
  if (typeof HEAPF32 !== "undefined" && typeof globalThis !== "undefined") {
    globalThis.HEAP8 = HEAP8;
    globalThis.HEAP16 = HEAP16;
    globalThis.HEAPU8 = HEAPU8;
    globalThis.HEAPU16 = HEAPU16;
    globalThis.HEAP32 = HEAP32;
    globalThis.HEAPU32 = HEAPU32;
    globalThis.HEAPF32 = HEAPF32;
    globalThis.HEAPF64 = HEAPF64;
  }
};

var readEmAsmArgs = function(sigPtr, argbuf) {
  if (!sigPtr) return [];
  var sig = UTF8ToString(sigPtr);
  var args = [];
  var buf = argbuf;
  for (var i = 0; i < sig.length; i++) {
    var type = sig[i];
    if (type === "i") {
      args.push(HEAP32[buf >> 2]);
      buf += 4;
    } else if (type === "d") {
      args.push(HEAPF64[buf >> 3]);
      buf += 8;
    } else if (type === "p") {
      args.push(HEAPU32[buf >> 2]);
      buf += 4;
    } else if (type === "w") {
      args.push(HEAP32[buf >> 2]);
      buf += 8;
    }
  }
  return args;
};

var runDynamicEmAsm = function(code, sigPtr, argbuf) {
  syncHeapGlobals();
  var jsCode = UTF8ToString(code);
  var args = readEmAsmArgs(sigPtr, argbuf);
  var paramNames = args.map(function(_, idx) { return "$" + idx; });
  try {
    var fn = new Function("Module", "UTF8ToString", "stringToUTF8", "lengthBytesUTF8", ...paramNames, jsCode);
    return fn(Module, UTF8ToString, stringToUTF8, lengthBytesUTF8, ...args);
  } catch (e) {
    console.error("EM_ASM error:", e, jsCode);
    return 0;
  }
};

var _emscripten_asm_const_int = function(code, sigPtr, argbuf) {
  return runDynamicEmAsm(code, sigPtr, argbuf) | 0;
};
var _emscripten_asm_const_double = function(code, sigPtr, argbuf) {
  return Number(runDynamicEmAsm(code, sigPtr, argbuf));
};
var _SetCanvasIdJs = function(out, outSize) {
  var container = document.getElementById("canvasContainer");
  if (container) container.style.display = "block";
  if (typeof globalThis.fitCanvasToContainer === "function") {
    globalThis.fitCanvasToContainer();
  }
  var canvasId = "#" + ((Module.canvas && Module.canvas.id) ? Module.canvas.id : "canvas");
  stringToUTF8(canvasId, out, outSize);
};
var SetCanvasIdJs = _SetCanvasIdJs;

if (typeof window !== "undefined" && !window.__c3PasteListenerAttached) {
  window.__c3PasteListenerAttached = true;
  document.addEventListener("paste", function(e) {
    if (e.clipboardData) {
      window._lastClipboardString = e.clipboardData.getData("text/plain") || "";
      var isInput = e.target && (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA" || (e.target.closest && e.target.closest(".monaco-editor")));
      if (!isInput) {
        e.preventDefault();
      }
    }
  });
}

var _RequestClipboardData = function() {
  return 0;
};

if (typeof window !== "undefined" && !window._clipboardListenerAdded) {
  window._clipboardListenerAdded = true;
  window.addEventListener('paste', function(e) {
    if (e.clipboardData) {
      var text = e.clipboardData.getData('text');
      if (text) window._lastClipboardString = text;
    }
  });
}

var _GetLastPastedText = function() {
  var str = (typeof window !== "undefined" && window._lastClipboardString) ? window._lastClipboardString : "";
  var len = lengthBytesUTF8(str) + 1;
  var ptr = _malloc(len);
  stringToUTF8(str, ptr, len);
  return ptr;
};

var _SetWebClipboard = function(ptr) {
  var str = UTF8ToString(ptr);
  if (typeof window !== "undefined") {
    window._lastClipboardString = str;
  }
  if (typeof navigator !== "undefined" && navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(str).catch(function() {});
  }
};

wasmImports = new Proxy(wasmImports, {
  get(target, prop) {
    if (typeof prop === "string") {
      if (prop === "emscripten_set_resize_callback_on_thread" || prop === "_emscripten_set_resize_callback_on_thread" ||
          prop === "emscripten_set_resize_callback" || prop === "_emscripten_set_resize_callback") {
        return function() { return 0; };
      }
      if (prop === "glfwGetClipboardString" || prop === "_glfwGetClipboardString") return _GetLastPastedText;
      if (prop in target) return target[prop];
      if (prop === "emscripten_asm_const_int" || prop === "_emscripten_asm_const_int") return _emscripten_asm_const_int;
      if (prop === "emscripten_asm_const_double" || prop === "_emscripten_asm_const_double") return _emscripten_asm_const_double;
      if (prop === "SetCanvasIdJs" || prop === "_SetCanvasIdJs") return _SetCanvasIdJs;
      if (prop === "__asyncjs__RequestClipboardData" || prop === "RequestClipboardData" || prop === "_RequestClipboardData") return _RequestClipboardData;
      if (prop === "GetLastPastedText" || prop === "_GetLastPastedText") return _GetLastPastedText;
      if (prop === "set_web_clipboard" || prop === "_set_web_clipboard" || prop === "SetWebClipboard" || prop === "_SetWebClipboard") return _SetWebClipboard;
      if (prop === "glfwGetProcAddress" || prop === "_glfwGetProcAddress") return function() { return 0; };
      try {
        var fn = eval("_" + prop);
        if (typeof fn === "function") return fn;
      } catch {}
      try {
        var fn = eval(prop);
        if (typeof fn === "function") return fn;
      } catch {}
      try {
        if (typeof GL !== "undefined" && typeof GL[prop] === "function") return GL[prop];
        if (typeof GLFW !== "undefined" && typeof GLFW[prop] === "function") return GLFW[prop];
      } catch {}
      return function(...args) {
        console.warn("[Emscripten Runtime] Unhandled import called: " + prop, args);
        return 0;
      };
    }
    return target[prop];
  }
});
"""

target_imports = "var wasmImports = {"
if target_imports in content and "new Proxy(wasmImports" not in content:
    idx = content.find("};", content.find(target_imports))
    if idx != -1:
        content = content[:idx+2] + "\n" + proxy_patch + content[idx+2:]

target_umv = "HEAPU64 = new BigUint64Array(b);"
if target_umv in content and "syncHeapGlobals" not in content[content.find(target_umv):content.find(target_umv)+100]:
    content = content.replace(target_umv, target_umv + "\n  if (typeof syncHeapGlobals === 'function') syncHeapGlobals();")

target_cw = "wasmExports = await createWasm();"
exports_setup = """wasmExports = await createWasm();
Module['wasmExports'] = wasmExports;
if (typeof FS !== 'undefined') Module['FS'] = FS;
if (typeof _emscripten_cancel_main_loop !== 'undefined') Module['cancelMainLoop'] = _emscripten_cancel_main_loop;
if (typeof _emscripten_pause_main_loop !== 'undefined') Module['pauseMainLoop'] = _emscripten_pause_main_loop;
if (typeof syncHeapGlobals === 'function') syncHeapGlobals();
if (typeof globalThis !== 'undefined') {
  globalThis._ma_device_process_pcm_frames_playback__webaudio = function(pDevice, bufferSize, pIntermediaryBuffer) {
    if (typeof syncHeapGlobals === 'function') syncHeapGlobals();
    return wasmExports.ma_device_process_pcm_frames_playback__webaudio ? wasmExports.ma_device_process_pcm_frames_playback__webaudio(pDevice, bufferSize, pIntermediaryBuffer) : 0;
  };
  globalThis._ma_device_process_pcm_frames_capture__webaudio = function(pDevice, bufferSize, pIntermediaryBuffer) {
    if (typeof syncHeapGlobals === 'function') syncHeapGlobals();
    return wasmExports.ma_device_process_pcm_frames_capture__webaudio ? wasmExports.ma_device_process_pcm_frames_capture__webaudio(pDevice, bufferSize, pIntermediaryBuffer) : 0;
  };
  globalThis._ma_device__on_notification_unlocked = function(pDevice) {
    return wasmExports.ma_device__on_notification_unlocked ? wasmExports.ma_device__on_notification_unlocked(pDevice) : 0;
  };
  globalThis._ma_malloc_emscripten = function(size, alignment) {
    return wasmExports.ma_malloc_emscripten ? wasmExports.ma_malloc_emscripten(size, alignment) : (wasmExports.malloc ? wasmExports.malloc(size) : 0);
  };
  globalThis._ma_free_emscripten = function(ptr) {
    if (wasmExports.ma_free_emscripten) wasmExports.ma_free_emscripten(ptr);
    else if (wasmExports.free) wasmExports.free(ptr);
  };
}"""

if target_cw in content and "globalThis._ma_device_process_pcm_frames_playback__webaudio" not in content:
    content = content.replace(target_cw, exports_setup)

import re

# 1. Ensure canvas is resolved at start of _glfwInit and _glfwTerminate
content, n1 = re.subn(r'var _glfwInit = \(\) => \{', r'var _glfwInit = () => {\n      var canvas = Browser.getCanvas();', content)
content, n2 = re.subn(r'var _glfwTerminate = \(\) => \{', r'var _glfwTerminate = () => {\n      var canvas = Browser.getCanvas();', content)
assert n1 == 1, f"Failed to patch _glfwInit: matched {n1}"
assert n2 == 1, f"Failed to patch _glfwTerminate: matched {n2}"

# 2. Redirect GLFW window key listeners to canvas
content, n3 = re.subn(r'window\.(add|remove)EventListener\(([\x27"])key(down|press|up)\2,\s*GLFW\.', r'if (canvas) canvas.\1EventListener(\2key\3\2, GLFW.', content)
assert n3 == 6, f"Failed to redirect GLFW key listeners to canvas: matched {n3}, expected 6"

# 3. Support dead keys, backticks, and character input reliably on keydown (specifically in GLFW)
kd_pattern = r'onKeydown:\(event\) => \{\s*GLFW\.onKeyChanged\(event\.keyCode, 1\);[\s\S]*?event\.preventDefault\(\);\s*\}\s*\},'
kd_replacement = """onKeydown:(event) => {
        GLFW.onKeyChanged(event.keyCode, 1);

        var isBrowserControl = (event.ctrlKey || event.metaKey) && ['r', 'w', 't', 'n', 'l', 'v'].indexOf((event.key || '').toLowerCase()) !== -1;
        if (!isBrowserControl && event.key !== 'F5' && event.key !== 'F12') {
          event.preventDefault();
        }

        if (event.key && event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
          if (GLFW.active && GLFW.active.charFunc) {
            var cp = event.key.codePointAt(0);
            if (cp >= 32) {
              getWasmTableEntry(GLFW.active.charFunc)(GLFW.active.id, cp);
            }
          }
        }
      },
  onKeyPress:(event) => {},"""

content, n4 = re.subn(kd_pattern, kd_replacement, content)
assert n4 == 1, f"Failed to patch GLFW.onKeydown: matched {n4}, expected 1"

# 4. Patch _emscripten_hide_mouse to set canvas.style.cursor directly rather than mutating document.styleSheets
hide_mouse_pattern = r'var _emscripten_hide_mouse = \(\) => \{[\s\S]*?styleSheet\.insertRule\([^\)]+\);\s*\};'
hide_mouse_replacement = """var _emscripten_hide_mouse = () => {
      var canvas = Browser.getCanvas();
      if (canvas) canvas.style.cursor = 'none';
    };"""
content, n5 = re.subn(hide_mouse_pattern, hide_mouse_replacement, content)
assert n5 == 1, f"Failed to patch _emscripten_hide_mouse: matched {n5}, expected 1"

# 5. Patch _glfwGetClipboardString to return _GetLastPastedText()
content = re.sub(r'var _glfwGetClipboardString = \([^\)]*\) => 0;', r'var _glfwGetClipboardString = (win) => _GetLastPastedText();', content)

# 6. Patch _emscripten_set_resize_callback_on_thread to prevent Raylib from attaching window.onresize listeners
content, n6 = re.subn(r'var _emscripten_set_resize_callback_on_thread = \([^)]*\) =>[^;]*;', r'var _emscripten_set_resize_callback_on_thread = () => 0;', content)
assert n6 == 1, f"Failed to patch _emscripten_set_resize_callback_on_thread: matched {n6}, expected 1"

# 7. Support InitWindow(0, 0) / monitor resolution by resolving 0 width/height to container or screen size in glfwCreateWindow
create_window_pattern = r'if \(width <= 0 \|\| height <= 0\) return 0;'
create_window_replacement = """if (width <= 0 || height <= 0) {
          var wrapper = document.querySelector(".canvas-wrapper") || document.getElementById("canvasContainer");
          var w = (wrapper && wrapper.clientWidth > 0) ? wrapper.clientWidth : (typeof screen !== "undefined" && screen.width > 0 ? screen.width : 800);
          var h = (wrapper && wrapper.clientHeight > 0) ? wrapper.clientHeight : (typeof screen !== "undefined" && screen.height > 0 ? screen.height : 450);
          if (width <= 0) width = w;
          if (height <= 0) height = h;
        }"""
content, n7 = re.subn(create_window_pattern, create_window_replacement, content)
assert n7 == 1, f"Failed to patch createWindow: matched {n7}, expected 1"

# 8. Patch _glfwGetVideoMode to return container / screen resolution
video_mode_replacement = """var _glfwGetVideoMode = (monitor) => {
      var wrapper = document.querySelector(".canvas-wrapper") || document.getElementById("canvasContainer");
      var w = (wrapper && wrapper.clientWidth > 0) ? wrapper.clientWidth : (typeof screen !== "undefined" && screen.width > 0 ? screen.width : 800);
      var h = (wrapper && wrapper.clientHeight > 0) ? wrapper.clientHeight : (typeof screen !== "undefined" && screen.height > 0 ? screen.height : 450);
      GLFW.videoMode ||= _malloc(24);
      HEAP32[((GLFW.videoMode)>>2)] = w;
      HEAP32[(((GLFW.videoMode)+4)>>2)] = h;
      HEAP32[(((GLFW.videoMode)+8)>>2)] = 8;
      HEAP32[(((GLFW.videoMode)+12)>>2)] = 8;
      HEAP32[(((GLFW.videoMode)+16)>>2)] = 8;
      HEAP32[(((GLFW.videoMode)+20)>>2)] = 60;
      return GLFW.videoMode;
    };"""
content, n8 = re.subn(r'var _glfwGetVideoMode = \([^)]*\) => 0;', video_mode_replacement, content)
assert n8 == 1, f"Failed to patch _glfwGetVideoMode: matched {n8}, expected 1"

# 9. Ensure initial window and framebuffer size callbacks notify Raylib upon registration
wsc_pattern = r'win\.windowSizeFunc = cbfun;\s*return prevcbfun;'
wsc_replacement = """win.windowSizeFunc = cbfun;
        if (cbfun && win.width > 0 && win.height > 0) {
          getWasmTableEntry(cbfun)(win.id, win.width, win.height);
        }
        return prevcbfun;"""
content, n9 = re.subn(wsc_pattern, wsc_replacement, content)
assert n9 == 1, f"Failed to patch setWindowSizeCallback: matched {n9}, expected 1"

fsc_pattern = r'win\.framebufferSizeFunc = cbfun;\s*return prevcbfun;'
fsc_replacement = """win.framebufferSizeFunc = cbfun;
      if (cbfun && win.framebufferWidth > 0 && win.framebufferHeight > 0) {
        getWasmTableEntry(cbfun)(win.id, win.framebufferWidth, win.framebufferHeight);
      }
      return prevcbfun;"""
content, n10 = re.subn(fsc_pattern, fsc_replacement, content)
assert n10 == 1, f"Failed to patch setFramebufferSizeCallback: matched {n10}, expected 1"

with open(out_path, "w") as f:
    f.write(content)
PY_EOF

# 4. Assemble Deployment Directory (dist/)
echo "Assembling deployment folder inside: ${DIST_DIR}..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}/build"

cp "${SCRIPT_DIR}/index.html" "${DIST_DIR}/"
cp "${SCRIPT_DIR}/c3-worker.js" "${DIST_DIR}/"
cp "${SCRIPT_DIR}/favicon.svg" "${DIST_DIR}/"

# Copy JS modules & C3 examples folders
cp -r "${SCRIPT_DIR}/js" "${DIST_DIR}/"
cp -r "${SCRIPT_DIR}/examples" "${DIST_DIR}/"

cp "${BUILD_DIR}/c3c.js" "${DIST_DIR}/build/"
cp "${BUILD_DIR}/c3c.data" "${DIST_DIR}/build/"
cp "${BUILD_DIR}/emscripten_runtime.js" "${DIST_DIR}/build/"
cp "${BUILD_DIR}/c3c.wasm" "${DIST_DIR}/build/"

echo ""
echo "Build complete."