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

# Create a dummy libm.a placeholder.
# First, ensure any old, copied libm.a is completely deleted,
# as 'emar rcs' will append to an existing archive rather than overwrite it.
rm -f "${SYS_LIB_DIR}/libm.a"

echo "int __dummy_libm;" > "${SYS_LIB_DIR}/dummy_m.c"
emcc -c "${SYS_LIB_DIR}/dummy_m.c" -o "${SYS_LIB_DIR}/dummy_m.o"
emar rcs "${SYS_LIB_DIR}/libm.a" "${SYS_LIB_DIR}/dummy_m.o"
rm -f "${SYS_LIB_DIR}/dummy_m.c" "${SYS_LIB_DIR}/dummy_m.o"

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
  -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sFORCE_FILESYSTEM=1 -sEXIT_RUNTIME=0 -sINITIAL_MEMORY=256MB -sSTACK_SIZE=8MB -sERROR_ON_UNDEFINED_SYMBOLS=0 -sEXPORTED_RUNTIME_METHODS=FS,callMain -sEXPORTED_FUNCTIONS=_main,_fflush --preload-file ${HOST_LIB_DIR}@/usr/lib/c3 --preload-file ${SYS_LIB_DIR}@/usr/lib/c3/wasm32-emscripten"

cmake --build "${BUILD_DIR}"

# 3. Build standalone Emscripten runtime JS glue (LINKABLE=1 simplifies this completely)
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
  -s INCOMING_MODULE_JS_API="['wasmBinary','print','printErr','onExit','noInitialRun']"

# Apply standard text-replacement patches to the output JS file
python3 -c '
import sys

out_path = sys.argv[1]
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
cp "${BUILD_DIR}/c3c.wasm" "${DIST_DIR}/build/" # Directly copied!

echo ""
echo "Build complete."