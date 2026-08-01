# sacckey/mahjong

MoonBitで実装する四人リーチ麻雀の点数計算ライブラリです。

通常ルールの一局について、入力検証、和了形列挙、役・ドラ・符の判定、支払い計算、最高点となる解釈の選択まで実装しています。ルールの初期仕様は [`docs/rules-v1.md`](docs/rules-v1.md) を参照してください。

## 開発

```sh
moon check --target all
moon test --target all
```
