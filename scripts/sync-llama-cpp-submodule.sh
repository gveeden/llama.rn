#!/bin/bash
set -euo pipefail

LLAMA_DIR="third_party/llama.cpp"
CPP_DIR="cpp"
SRC_DIR="src"
OS=$(uname)

echo "🔍 Ensuring PrismML prism branch is checked out..."
cd "$LLAMA_DIR"
git fetch origin
git checkout prism
cd -

echo "🧹 Cleaning up existing cpp directory..."
# Remove only llama.cpp-origin files; preserve rn-*.{h,cpp,hpp} which are llama.rn-native
rm -f "$CPP_DIR"/ggml*.c "$CPP_DIR"/ggml*.h "$CPP_DIR"/ggml*.cpp
rm -f "$CPP_DIR"/gguf*.h "$CPP_DIR"/gguf*.cpp
rm -f "$CPP_DIR"/llama*.h "$CPP_DIR"/llama*.cpp
rm -f "$CPP_DIR"/unicode*.h "$CPP_DIR"/unicode*.cpp
# anyascii is a vendored lib used by rn-tts.cpp — do not delete it
rm -rf "$CPP_DIR"/common "$CPP_DIR"/ggml-cpu "$CPP_DIR"/ggml-metal
rm -rf "$CPP_DIR"/models "$CPP_DIR"/tools

# 1. Copy GGML core
echo "📦 Copying GGML core..."
cp "$LLAMA_DIR"/ggml/src/ggml*.c "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/src/ggml*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/src/ggml*.cpp "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/src/gguf.cpp "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/include/ggml*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/include/gguf*.h "$CPP_DIR"/

# 2. Copy Llama core
echo "📦 Copying Llama core..."
cp "$LLAMA_DIR"/include/llama*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/src/llama*.cpp "$CPP_DIR"/
cp "$LLAMA_DIR"/src/llama*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/src/unicode.{h,cpp} "$CPP_DIR"/
cp "$LLAMA_DIR"/src/unicode-data.{h,cpp} "$CPP_DIR"/
mkdir -p "$CPP_DIR"/models
cp "$LLAMA_DIR"/src/models/models.h "$CPP_DIR"/models/
cp "$LLAMA_DIR"/src/models/*.cpp "$CPP_DIR"/models/

# 3a. Copy MTMD (multimodal) tools required by rn-mtmd.hpp
echo "📦 Copying MTMD tools..."
mkdir -p "$CPP_DIR/tools/mtmd" "$CPP_DIR/tools/mtmd/models"
cp "$LLAMA_DIR"/tools/mtmd/mtmd.{h,cpp} "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/mtmd-helper.{h,cpp} "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/mtmd-audio.{h,cpp} "$CPP_DIR/tools/mtmd/"
# Fix DEBUG macro conflict: Apple builds define DEBUG=1 which breaks constexpr bool DEBUG
if [ "$OS" = "Darwin" ]; then
    sed -i "" 's/constexpr bool DEBUG = /constexpr bool MTMD_AUDIO_DEBUG_FLAG = /g' "$CPP_DIR/tools/mtmd/mtmd-audio.cpp"
    sed -i "" 's/\bDEBUG\b/MTMD_AUDIO_DEBUG_FLAG/g' "$CPP_DIR/tools/mtmd/mtmd-audio.cpp"
else
    sed -i 's/constexpr bool DEBUG = /constexpr bool MTMD_AUDIO_DEBUG_FLAG = /g' "$CPP_DIR/tools/mtmd/mtmd-audio.cpp"
    sed -i 's/\bDEBUG\b/MTMD_AUDIO_DEBUG_FLAG/g' "$CPP_DIR/tools/mtmd/mtmd-audio.cpp"
fi
cp "$LLAMA_DIR"/tools/mtmd/clip.{h,cpp} "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/clip-graph.h "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/clip-impl.h "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/clip-model.h "$CPP_DIR/tools/mtmd/"
cp "$LLAMA_DIR"/tools/mtmd/models/models.h "$CPP_DIR/tools/mtmd/models/"
cp "$LLAMA_DIR"/tools/mtmd/models/*.cpp "$CPP_DIR/tools/mtmd/models/"

# 3. Copy Hardware Backends
echo "📦 Copying Hardware Backends..."
if [ -d "$LLAMA_DIR/ggml/src/ggml-metal" ]; then
    cp -r "$LLAMA_DIR/ggml/src/ggml-metal" "$CPP_DIR/ggml-metal"
fi
if [ -d "$LLAMA_DIR/ggml/src/ggml-cpu" ]; then
    cp -r "$LLAMA_DIR/ggml/src/ggml-cpu" "$CPP_DIR/ggml-cpu"
fi

# 4. Copy Common Utilities
echo "📦 Copying Common Utilities..."
mkdir -p "$CPP_DIR"/common
cp -r "$LLAMA_DIR"/common/*.h "$CPP_DIR"/common/
cp -r "$LLAMA_DIR"/common/*.cpp "$CPP_DIR"/common/
if [ -d "$LLAMA_DIR/common/jinja" ]; then
    cp -r "$LLAMA_DIR/common/jinja" "$CPP_DIR/common/jinja"
    # Rename jinja/string.h to avoid shadowing the system <string.h> via CocoaPods header maps
    if [ -f "$CPP_DIR/common/jinja/string.h" ]; then
        mv "$CPP_DIR/common/jinja/string.h" "$CPP_DIR/common/jinja/jinja-string.h"
        mv "$CPP_DIR/common/jinja/string.cpp" "$CPP_DIR/common/jinja/jinja-string.cpp"
        # Update all include references to the renamed file
        if [ "$OS" = "Darwin" ]; then
            sed -i "" 's|#include "string\.h"|#include "jinja-string.h"|g' "$CPP_DIR/common/jinja/value.h"
            sed -i "" 's|#include "jinja/string\.h"|#include "jinja/jinja-string.h"|g' "$CPP_DIR/common/jinja/jinja-string.cpp"
        else
            sed -i 's|#include "string\.h"|#include "jinja-string.h"|g' "$CPP_DIR/common/jinja/value.h"
            sed -i 's|#include "jinja/string\.h"|#include "jinja/jinja-string.h"|g' "$CPP_DIR/common/jinja/jinja-string.cpp"
        fi
    fi
fi

# 5. Copy Vendors
echo "📦 Copying Vendors..."
rm -rf "$CPP_DIR"/nlohmann
cp -r "$LLAMA_DIR"/vendor/nlohmann "$CPP_DIR"/nlohmann
# miniaudio and stb are required by tools/mtmd/mtmd-helper.cpp
mkdir -p "$CPP_DIR/tools/mtmd/miniaudio" "$CPP_DIR/tools/mtmd/stb"
cp "$LLAMA_DIR/vendor/miniaudio/miniaudio.h" "$CPP_DIR/tools/mtmd/miniaudio/"
cp "$LLAMA_DIR/vendor/stb/stb_image.h" "$CPP_DIR/tools/mtmd/stb/"

# 6. Apply Prefixing
echo "🔄 Applying LM_ prefix to symbols..."
while IFS= read -r -d '' file; do
  if [[ $file == *"/cpp/rn-"* ]]; then continue; fi

  if [ "$OS" = "Darwin" ]; then
    sed -i "" "s|GGML_|LM_GGML_|g" "$file"
    sed -i "" "s|ggml_|lm_ggml_|g" "$file"
    sed -i "" "s|GGUF_|LM_GGUF_|g" "$file"
    sed -i "" "s|gguf_|lm_gguf_|g" "$file"
    sed -i "" "s|GGMLMetalClass|LMGGMLMetalClass|g" "$file"
    sed -i "" 's|<nlohmann/json.hpp>|"nlohmann/json.hpp"|g' "$file"
    sed -i "" 's|<nlohmann/json_fwd.hpp>|"nlohmann/json_fwd.hpp"|g' "$file"
  else
    sed -i "s|GGML_|LM_GGML_|g" "$file"
    sed -i "s|ggml_|lm_ggml_|g" "$file"
    sed -i "s|GGUF_|LM_GGUF_|g" "$file"
    sed -i "s|gguf_|lm_gguf_|g" "$file"
    sed -i "s|GGMLMetalClass|LMGGMLMetalClass|g" "$file"
    sed -i 's|<nlohmann/json.hpp>|"nlohmann/json.hpp"|g' "$file"
    sed -i 's|<nlohmann/json_fwd.hpp>|"nlohmann/json_fwd.hpp"|g' "$file"
  fi
done < <(find ./cpp/ggml-metal ./cpp/ggml-cpu ./cpp/common ./cpp/models ./cpp/tools/mtmd \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.c" -o -name "*.m" -o -name "*.metal" \) \
    -print0 2>/dev/null; \
  find ./cpp -maxdepth 1 \
    \( -name "*.cpp" -o -name "*.h" -o -name "*.c" \) \
    -print0 2>/dev/null)

# 7. Get version info
cd "$LLAMA_DIR"
BUILD_NUMBER=$(git rev-list --count HEAD)
BUILD_COMMIT=$(git rev-parse --short=7 HEAD)
GGML_VERSION=$(grep "^set(GGML_VERSION_MAJOR" ggml/CMakeLists.txt | sed 's/[^0-9]//g').$(grep "^set(GGML_VERSION_MINOR" ggml/CMakeLists.txt | sed 's/[^0-9]//g').$(grep "^set(GGML_VERSION_PATCH" ggml/CMakeLists.txt | sed 's/[^0-9]//g')
cd -
rm -f "$SRC_DIR/version.ts"
echo "export const BUILD_NUMBER = $BUILD_NUMBER" > "$SRC_DIR/version.ts"
echo "export const BUILD_COMMIT = \"$BUILD_COMMIT\"" >> "$SRC_DIR/version.ts"

# 8a. Generate build-info.cpp (normally generated by CMake) with LLAMA build constants
LLAMA_BUILD_NUMBER=$(git -C "$LLAMA_DIR" rev-list --count HEAD)
cat > "$CPP_DIR/common/build-info.cpp" << EOF
int LLAMA_BUILD_NUMBER = ${LLAMA_BUILD_NUMBER};
char const *LLAMA_COMMIT = "${BUILD_COMMIT}";
char const *LLAMA_COMPILER = "clang";
char const *LLAMA_BUILD_TARGET = "arm64-apple-ios";
EOF
echo "📝 Generated common/build-info.cpp (build #${LLAMA_BUILD_NUMBER})"

# 8. Generate ggml-version.h (normally generated by CMake) and inject include into ggml.c
cat > "$CPP_DIR/ggml-version.h" << EOF
#pragma once
#define LM_GGML_VERSION "${GGML_VERSION}"
#define LM_GGML_COMMIT "${BUILD_COMMIT}"
EOF
echo "📝 Generated ggml-version.h (v${GGML_VERSION} @ ${BUILD_COMMIT})"
# Inject include at the top of ggml.c so LM_GGML_VERSION/COMMIT are available
if ! grep -q "ggml-version.h" "$CPP_DIR/ggml.c"; then
    if [ "$OS" = "Darwin" ]; then
        sed -i "" '1s|^|#include "ggml-version.h"\n|' "$CPP_DIR/ggml.c"
    else
        sed -i '1s|^|#include "ggml-version.h"\n|' "$CPP_DIR/ggml.c"
    fi
fi

# 9. Preprocess ggml-metal.metal to inline local headers for runtime compilation
# newLibraryWithSource: has no include path support, so headers must be inlined.
echo "📦 Preprocessing ggml-metal.metal (inlining headers for runtime compilation)..."
python3 - <<'PYEOF'
import os, re

base = "cpp/ggml-metal"
root = "cpp"

def read_file(path):
    with open(path, 'r', errors='replace') as f:
        return f.read()

def inline_includes(src, search_dirs, depth=0):
    if depth > 5:
        return src
    def replacer(m):
        fname = m.group(1)
        for d in search_dirs:
            fpath = os.path.join(d, fname)
            if os.path.exists(fpath):
                inner = read_file(fpath)
                return f"// --- begin inline: {fname} ---\n" + inline_includes(inner, [os.path.dirname(fpath)] + search_dirs, depth+1) + f"\n// --- end inline: {fname} ---"
        return m.group(0)  # keep original if not found
    return re.sub(r'^#include\s+"([^"]+)"', replacer, src, flags=re.MULTILINE)

metal_path = os.path.join(base, "ggml-metal.metal")
src = read_file(metal_path)
preprocessed = inline_includes(src, [base, root])
with open(metal_path, 'w') as f:
    f.write(preprocessed)
print(f"  Preprocessed {metal_path}")
PYEOF

echo "✨ Sync complete!"
