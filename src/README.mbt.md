# sacckey/mahjong

MoonBitで実装する四人リーチ麻雀の点数計算ライブラリです。

通常ルールの一局について、入力検証、和了形列挙、役・ドラ・符の判定、支払い計算、最高点となる解釈の選択まで実装しています。ルールの初期仕様は[`docs/rules-v1.md`](../docs/rules-v1.md)を参照してください。

## 公開API

基本の入口は、標準ルールで計算する`score_standard`と、`RuleSet`を指定する`score`です。入力の`HandInput.concealed_tiles`には和了牌を含めず、和了牌は`winning_tile`へ指定します。

次の例は、南家が立直して平和をロン和了した場合です。2翻30符、2,000点になります。

```mbt check
///|
test "score a standard riichi hand" {
  let tile = (suit, rank) => @mahjong.Tile::numbered(suit, rank)
  let context = {
    ..@mahjong.WinContext::new(Ron, seat_wind=South, round_wind=East),
    riichi: Riichi,
  }
  let input = @mahjong.HandInput::new(
    [
      tile(Man, 1),
      tile(Man, 2),
      tile(Man, 3),
      tile(Man, 4),
      tile(Man, 5),
      tile(Man, 6),
      tile(Pin, 1),
      tile(Pin, 2),
      tile(Pin, 3),
      tile(Sou, 7),
      tile(Sou, 8),
      tile(Pin, 5),
      tile(Pin, 5),
    ],
    winning_tile=tile(Sou, 9),
    context~,
  )
  let result = @mahjong.score_standard(input)
  assert_eq(result.han, 2)
  assert_eq(result.fu, 30)
  assert_eq(result.payment, RonPayment(discarder=2000))
  assert_eq(result.winner_gain, 2000)
}
```

和了形かどうかだけを調べる場合は`is_winning_hand`、既に確定した翻数と符から支払いを計算する場合は`calculate_points`を使用できます。役判定、符計算、ドラ計算、和了形分解は`score`の内部処理です。

## JS・Wasm-GCから使う

MoonBit外との境界には`sacckey/mahjong/ffi`パッケージを使用します。JSとWasm-GCのどちらにも、同じJSONプロトコルを受け取る`mahjong_score_json`と、プロトコルバージョンを返す`mahjong_api_version`がexportされます。

JSONの入力、結果、エラーコードは[`docs/json-api-v1.md`](../docs/json-api-v1.md)で定義しています。境界層はコアのMoonBit APIから分離されているため、MoonBitから利用する場合は引き続き型付きの`score_standard`または`score`を使えます。

## ブラウザ利用例

手牌、和了牌、鳴き・槓、ドラ表示牌、和了条件をGUIで入力できる静的アプリを[`examples/browser`](../examples/browser/)に置いています。

公開版は<https://sacckey.github.io/mahjong/>で試せます。ローカルで動かす場合は、リポジトリのルートで次を実行します。

```sh
moon build --target wasm-gc src/ffi
moon build --target js src/ffi
python3 -m http.server 8000
```

<http://127.0.0.1:8000/examples/browser/>を開いてください。Wasm-GCを優先し、未対応のブラウザではMoonBitのJavaScript生成物へ切り替わります。このアプリと生成物はmooncakesの配布物には含まれません。

## 開発

```sh
moon check --target all
moon test --target all
```

`MahjongRepository/mahjong`との開発用差分検証は次のコマンドで実行できます。Python依存と生成ケースは配布ライブラリには含まれません。

```sh
uv run tools/conformance/check.py
```

詳細は[`tools/conformance/README.md`](../tools/conformance/README.md)を参照してください。
