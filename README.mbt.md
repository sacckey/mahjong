# sacckey/mahjong

MoonBitで実装する四人リーチ麻雀の点数計算ライブラリです。

通常ルールの一局について、入力検証、和了形列挙、役・ドラ・符の判定、支払い計算、最高点となる解釈の選択まで実装しています。ルールの初期仕様は [`docs/rules-v1.md`](docs/rules-v1.md) を参照してください。

## 公開API

基本の入口は、標準ルールで計算する`score_standard`と、`RuleSet`を指定する`score`です。入力の`HandInput.concealed_tiles`には和了牌を含めず、和了牌は`winning_tile`へ指定します。

```mbt nocheck
let result = @mahjong.score_standard(input)
println("\{result.han} han / \{result.fu} fu")
```

和了形かどうかだけを調べる場合は`is_winning_hand`、既に確定した翻数と符から支払いを計算する場合は`calculate_points`を使用できます。役判定、符計算、ドラ計算、和了形分解は`score`の内部処理です。

## 開発

```sh
moon check --target all
moon test --target all
```
