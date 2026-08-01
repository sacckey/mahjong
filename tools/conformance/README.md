# MahjongRepository conformance check

`MahjongRepository/mahjong`が計算した結果と、このライブラリの公開APIが返す結果を比較する開発用ツールです。参照実装はコミット`51675182ae0c040a4cb143eb1e109dc06e0a78b2`に固定しています。

## 実行

MoonBitと[`uv`](https://docs.astral.sh/uv/)が必要です。

```sh
uv run tools/conformance/check.py
```

既定では、固定シードから通常形、七対子、国士無双、門前、副露、槓を含む500件を生成します。役、ドラ、翻、符、上限、基本点、支払い、本場、供託を比較します。

件数やシードは変更できます。

```sh
uv run tools/conformance/check.py --cases 5000 --seed 42
```

生成したMoonBitテストは成功時に削除されます。不一致がある場合は`src/conformance_generated_*_test.mbt`へ残るため、単独で再実行して調査できます。参照実装との不一致は、直ちにこのライブラリの不具合を意味しません。ルール設定と変換処理を確認してから回帰テストへ追加してください。

このツールとPython依存は通常の`moon check`、`moon test`、Wasm・nativeビルドには含まれません。
