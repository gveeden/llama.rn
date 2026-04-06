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
rm -rf "$CPP_DIR"/*.c "$CPP_DIR"/*.h "$CPP_DIR"/*.cpp
rm -rf "$CPP_DIR"/common "$CPP_DIR"/ggml-cpu "$CPP_DIR"/ggml-metal
rm -rf "$CPP_DIR"/models "$CPP_DIR"/tools

# 1. Copy GGML core
echo "📦 Copying GGML core..."
cp "$LLAMA_DIR"/ggml/src/ggml*.c "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/src/ggml*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/src/ggml*.cpp "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/include/ggml*.h "$CPP_DIR"/
cp "$LLAMA_DIR"/ggml/include/gguf*.h "$CPP_DIR"/

# 2. Copy Llama core
echo "📦 Copying Llama core..."
cp "$LLAMA_DIR"/include/llama.h "$CPP_DIR"/
cp "$LLAMA_DIR"/src/llama*.cpp "$CPP_DIR"/
cp "$LLAMA_DIR"/src/llama*.h "$CPP_DIR"/

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

# 5. Copy Vendors
echo "📦 Copying Vendors..."
rm -rf "$CPP_DIR"/nlohmann
cp -r "$LLAMA_DIR"/vendor/nlohmann "$CPP_DIR"/nlohmann

# 6. Apply Prefixing
echo "🔄 Applying LM_ prefix to symbols..."
files_add_lm_prefix=(
  ./cpp/ggml-metal/*.cpp
  ./cpp/ggml-metal/*.h
  ./cpp/ggml-metal/*.m
  ./cpp/ggml-metal/*.metal
  ./cpp/ggml-cpu/*.h
  ./cpp/ggml-cpu/*.c
  ./cpp/ggml-cpu/*.cpp
  ./cpp/*.h
  ./cpp/*.cpp
  ./cpp/*.c
  ./cpp/common/*.h
  ./cpp/common/*.cpp
)

for file in "${files_add_lm_prefix[@]}"; do
  if [ ! -f "$file" ]; then continue; fi
  if [[ $file == *"/cpp/rn-"* ]]; then continue; fi

  if [ "$OS" = "Darwin" ]; then
    sed -i "" "s|GGML_|LM_GGML_|g" "$file"
    sed -i "" "s|ggml_|lm_ggml_|g" "$file"
    sed -i "" "s|GGUF_|LM_GGUF_|g" "$file"
    sed -i "" "s|gguf_|lm_gguf_|g" "$file"
    sed -i "" "s|GGMLMetalClass|LMGGMLMetalClass|g" "$file"
    sed -i "" "s|<nlohmann/json.hpp>|"nlohmann/json.hpp"|g" "$file"
    sed -i "" "s|<nlohmann/json_fwd.hpp>|"nlohmann/json_fwd.hpp"|g" "$file"
  else
    sed -i "s|GGML_|LM_GGML_|g" "$file"
    sed -i "s|ggml_|lm_ggml_|g" "$file"
    sed -i "s|GGUF_|LM_GGUF_|g" "$file"
    sed -i "s|gguf_|lm_gguf_|g" "$file"
    sed -i "s|GGMLMetalClass|LMGGMLMetalClass|g" "$file"
    sed -i "s|<nlohmann/json.hpp>|"nlohmann/json.hpp"|g" "$file"
    sed -i "s|<nlohmann/json_fwd.hpp>|"nlohmann/json_fwd.hpp"|g" "$file"
  fi
done

# 7. Get version info
cd "$LLAMA_DIR"
BUILD_NUMBER=$(git rev-list --count HEAD)
BUILD_COMMIT=$(git rev-parse --short=7 HEAD)
cd -
rm -f "$SRC_DIR/version.ts"
echo "export const BUILD_NUMBER = "$BUILD_NUMBER"" > "$SRC_DIR/version.ts"
echo "export const BUILD_COMMIT = "$BUILD_COMMIT"" >> "$SRC_DIR/version.ts"

echo "✨ Sync complete!"
