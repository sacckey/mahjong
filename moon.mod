// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "sacckey/mahjong"

version = "0.4.0"

readme = "src/README.mbt.md"

repository = "https://github.com/sacckey/mahjong"

license = "Apache-2.0"

keywords = [ "mahjong", "riichi", "scoring" ]

preferred_target = "wasm"

description = "A four-player riichi mahjong scoring and hand analysis library for MoonBit."

source = "src"

// Derived trait methods are used through operators and trait calls only, so
// the implicit dot-syntax promotion is not part of this module's API.

warnings = "-implicit_impl_as_method"
