#!/usr/bin/env bash
set -euo pipefail

BUILD_TYPE="${1:-Debug}"
LLVM_TAG="${2:-latest}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#PROJECT_ROOT="${SCRIPT_DIR}/c3c"
PROJECT_ROOT="${HOME}/scripts/c3c"
BUILD_DIR="${SCRIPT_DIR}/build"
SYS_LIB_DIR="${BUILD_DIR}/wasm32-emscripten"
DIST_DIR="${SCRIPT_DIR}/dist"
HOST_LIB_DIR="${PROJECT_ROOT}/lib"

echo "Build Type:     ${BUILD_TYPE}"
echo "LLVM Tag:       ${LLVM_TAG}"
echo "Project Root:   ${PROJECT_ROOT}"
echo "Build Output:   ${BUILD_DIR}"
echo "Dist Directory: ${DIST_DIR}"

# 1. Build and copy Emscripten system static archives for C3 builtin linker
mkdir -p "${SYS_LIB_DIR}"
embuilder build libc libdlmalloc libstubs libsockets

EM_CACHE="$(em-config CACHE)"
EM_CACHE_DIR="${EM_CACHE}/sysroot/lib/wasm32-emscripten"

for lib in libc.a libdlmalloc.a libstubs.a libsockets.a; do
  if [ -f "${EM_CACHE_DIR}/${lib}" ]; then
    cp "${EM_CACHE_DIR}/${lib}" "${SYS_LIB_DIR}/"
  else
    echo "Warning: ${lib} not found in ${EM_CACHE_DIR}"
  fi
done

# Copy libc.a to libm.a. Emscripten embeds math symbols inside libc.a,
# which satisfies any implicit -lm requirements without compiling a dummy object.
cp "${SYS_LIB_DIR}/libc.a" "${SYS_LIB_DIR}/libm.a"

# 2. Configure and compile c3c to WebAssembly
emcmake cmake -B "${BUILD_DIR}" -S "${PROJECT_ROOT}" -G Ninja \
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
  -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sFORCE_FILESYSTEM=1 -sEXIT_RUNTIME=0 -sINITIAL_MEMORY=256MB -sSTACK_SIZE=8MB -sERROR_ON_UNDEFINED_SYMBOLS=0 -sEXPORTED_RUNTIME_METHODS=FS,callMain -sEXPORTED_FUNCTIONS=_main,_fflush -sINCOMING_MODULE_JS_API=wasmBinary,noInitialRun,instantiateWasm,locateFile,print,printErr,onRuntimeInitialized --preload-file ${HOST_LIB_DIR}@/usr/lib/c3 --preload-file ${SYS_LIB_DIR}@/usr/lib/c3/wasm32-emscripten"

cmake --build "${BUILD_DIR}"

# 3. Build standalone Emscripten runtime JS glue for user WASM execution
python3 -c '
import sys, os, json, subprocess, shutil

out_path = sys.argv[1]
emcc_path = shutil.which("emcc")
if emcc_path:
    em_dir = os.path.dirname(os.path.realpath(emcc_path))
    sys.path.insert(0, em_dir)

from tools.settings import settings
settings.INCLUDE_FULL_LIBRARY = True
from tools.link import get_js_sym_info

info = get_js_sym_info()
deps = info.get("deps", {})
syms = []
for name in deps.keys():
    if name.startswith("emscripten_asm_const") or name.startswith("GL"):
        continue
    syms.append(name if name.startswith("$") else "$" + name)

funcs_json = json.dumps(syms)
cmd = [
    "emcc", "-xc", "/dev/null", "-o", out_path,
    "-s", "INCLUDE_FULL_LIBRARY=1",
    "-s", "DEFAULT_LIBRARY_FUNCS_TO_INCLUDE=" + funcs_json,
    "-s", "ASSERTIONS=0",
    "-s", "ERROR_ON_UNDEFINED_SYMBOLS=0",
    "-s", "FORCE_FILESYSTEM=1",
    "-s", "ALLOW_MEMORY_GROWTH=1",
    "-s", "EXIT_RUNTIME=0",
    "-s", "MODULARIZE=1",
    "-s", "EXPORT_NAME=C3EmscriptenRuntime",
    "-s", "INCOMING_MODULE_JS_API=[\"wasmBinary\",\"print\",\"printErr\",\"onExit\",\"noInitialRun\"]"
]
res = subprocess.run(cmd)
if res.returncode != 0:
    sys.exit(res.returncode)

with open(out_path, "r") as f:
    content = f.read()

proxy_patch = """
wasmImports = new Proxy(wasmImports, {
  get(target, prop) {
    if (typeof prop === "string" && !(prop in target)) {
      try {
        var fn = eval("_" + prop);
        if (typeof fn === "function") return fn;
      } catch {}
      try {
        var fn = eval(prop);
        if (typeof fn === "function") return fn;
      } catch {}
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

target_cw = "wasmExports = await createWasm();"
if target_cw in content and "Module[\x27wasmExports\x27]" not in content:
    content = content.replace(target_cw, target_cw + "\nModule[\x27wasmExports\x27] = wasmExports;")

with open(out_path, "w") as f:
    f.write(content)
' "${BUILD_DIR}/emscripten_runtime.js"

# 4. Assemble Deployment Directory (dist/)
echo "Assembling deployment folder inside: ${DIST_DIR}..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}/build"

cp "${SCRIPT_DIR}/index.html" "${DIST_DIR}/"
cp "${SCRIPT_DIR}/c3-worker.js" "${DIST_DIR}/"

cp "${BUILD_DIR}/c3c.js" "${DIST_DIR}/build/"
cp "${BUILD_DIR}/c3c.data" "${DIST_DIR}/build/"
cp "${BUILD_DIR}/emscripten_runtime.js" "${DIST_DIR}/build/"

if [ -f "${BUILD_DIR}/c3c.wasm" ]; then
  if command -v split &>/dev/null; then
    echo "Splitting c3c.wasm into <25MB chunks..."
    split -b 20M "${BUILD_DIR}/c3c.wasm" "${DIST_DIR}/build/c3c.wasm.part_"
  else
    echo "Warning: 'split' tool not found, copying raw c3c.wasm..."
    cp "${BUILD_DIR}/c3c.wasm" "${DIST_DIR}/build/"
  fi
fi

# 5. Integrated Packaging (ZIP)
if command -v zip &> /dev/null; then
  echo "Packaging assets to ${BUILD_DIR}/site.zip..."
  rm -f "${BUILD_DIR}/site.zip"
  (
    cd "${DIST_DIR}"
    zip -q -r "${BUILD_DIR}/site.zip" .
  )
  echo "Successfully packaged to ${BUILD_DIR}/site.zip"
fi

echo ""
echo "Build complete."