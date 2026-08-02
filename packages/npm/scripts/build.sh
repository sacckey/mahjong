#!/bin/sh
set -eu

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repository_dir=$(CDPATH= cd -- "$package_dir/../.." && pwd)

moon -C "$repository_dir" build --target js src/ffi --release --deny-warn
moon -C "$repository_dir" build --target wasm-gc src/ffi --release --deny-warn

mkdir -p "$package_dir/dist"
cp "$repository_dir/_build/js/release/build/ffi/ffi.js" "$package_dir/dist/engine.js"
cp "$repository_dir/_build/wasm-gc/release/build/ffi/ffi.wasm" "$package_dir/dist/engine.wasm"
cp "$repository_dir/LICENSE" "$package_dir/LICENSE"
