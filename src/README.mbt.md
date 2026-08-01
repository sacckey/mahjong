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
  let context : @mahjong.WinContext = {
    win_method: Ron,
    seat_wind: South,
    round_wind: East,
    riichi: Riichi,
    ippatsu: false,
    rinshan: false,
    chankan: false,
    haitei: false,
    houtei: false,
    tenhou: false,
    chiihou: false,
    honba: 0,
    riichi_sticks: 0,
  }
  let input : @mahjong.HandInput = {
    concealed_tiles: [
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
    winning_tile: tile(Sou, 9),
    melds: [],
    dora_indicators: [],
    ura_dora_indicators: [],
    context,
  }
  let result = @mahjong.score_standard(input)
  assert_eq(result.han, 2)
  assert_eq(result.fu, 30)
  assert_eq(result.payment, RonPayment(discarder=2000))
  assert_eq(result.winner_gain, 2000)
}
```

和了形かどうかだけを調べる場合は`is_winning_hand`、既に確定した翻数と符から支払いを計算する場合は`calculate_points`を使用できます。役判定、符計算、ドラ計算、和了形分解は`score`の内部処理です。

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
