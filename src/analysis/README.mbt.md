# sacckey/mahjong/analysis

通常形、七対子、国士無双のシャンテン数、構造上の聴牌状態、待ち牌一覧を計算します。

`AnalysisInput.concealed_tiles`には現在手牌にある副露前の牌をすべて渡します。点数計算用の`HandInput`とは異なり、和了牌を分離しません。

```mbt check
///|
test {
  let tile = (suit, rank) => @mahjong.Tile::numbered(suit, rank)
  let input = @analysis.AnalysisInput::new([
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
  ])
  assert_eq(@analysis.calculate_shanten(input).minimum, 0)
  assert_true(@analysis.is_tenpai(input))
  assert_eq(@analysis.waiting_tiles(input), [Numbered(Sou, 6), Numbered(Sou, 9)])
}
```

シャンテン数は和了形を`-1`、聴牌を`0`とします。`waiting_tiles`は構造上13枚の入力だけを受け付け、役、フリテン、山に残る枚数は考慮しません。

