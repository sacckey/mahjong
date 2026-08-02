///|
fn tile(suit : @mahjong.Suit, rank : Int) -> @mahjong.Tile raise {
  @mahjong.Tile::numbered(suit, rank)
}

///|
fn honor(honor : @mahjong.Honor) -> @mahjong.Tile {
  @mahjong.Tile::honor(honor)
}

///|
test "standard shanten distinguishes tenpai and one-shanten hands" {
  let tenpai = @analysis.AnalysisInput::new([
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
  let result = @analysis.calculate_shanten(tenpai)
  assert_eq(result.minimum, 0)
  assert_eq(result.standard, 0)
  assert_true(@analysis.is_tenpai(tenpai))
  assert_eq(@analysis.waiting_tiles(tenpai), [
    Numbered(Sou, 6),
    Numbered(Sou, 9),
  ])
  let one_shanten = @analysis.AnalysisInput::new([
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
    tile(Pin, 6),
  ])
  assert_eq(@analysis.calculate_shanten(one_shanten).minimum, 1)
  assert_false(@analysis.is_tenpai(one_shanten))
  assert_eq(@analysis.waiting_tiles(one_shanten), [])
}

///|
test "seven pairs and thirteen orphans contribute to minimum shanten" {
  let seven_pairs = @analysis.AnalysisInput::new([
    tile(Man, 1),
    tile(Man, 1),
    tile(Man, 3),
    tile(Man, 3),
    tile(Man, 5),
    tile(Man, 5),
    tile(Man, 7),
    tile(Man, 7),
    tile(Man, 9),
    tile(Man, 9),
    tile(Pin, 1),
    tile(Pin, 1),
    tile(Pin, 3),
  ])
  let pairs_result = @analysis.calculate_shanten(seven_pairs)
  assert_eq(pairs_result.minimum, 0)
  assert_eq(pairs_result.seven_pairs, Some(0))
  assert_eq(@analysis.waiting_tiles(seven_pairs), [Numbered(Pin, 3)])
  let kokushi = @analysis.AnalysisInput::new([
    tile(Man, 1),
    tile(Man, 9),
    tile(Pin, 1),
    tile(Pin, 9),
    tile(Sou, 1),
    tile(Sou, 9),
    honor(East),
    honor(South),
    honor(West),
    honor(North),
    honor(White),
    honor(Green),
    honor(Red),
  ])
  let kokushi_result = @analysis.calculate_shanten(kokushi)
  assert_eq(kokushi_result.minimum, 0)
  assert_eq(kokushi_result.thirteen_orphans, Some(0))
  assert_eq(@analysis.waiting_tiles(kokushi).length(), 13)
}

///|
test "melds count as fixed groups and disable special hands" {
  let chi : @mahjong.Meld = {
    kind: Chi,
    tiles: [tile(Man, 1), tile(Man, 2), tile(Man, 3)],
  }
  let input = @analysis.AnalysisInput::new(
    [
      tile(Pin, 4),
      tile(Pin, 5),
      tile(Pin, 6),
      tile(Sou, 7),
      tile(Sou, 8),
      tile(Sou, 9),
      honor(East),
      honor(East),
      honor(East),
      tile(Pin, 2),
    ],
    melds=[chi],
  )
  let result = @analysis.calculate_shanten(input)
  assert_eq(result.minimum, 0)
  assert_eq(result.standard, 0)
  assert_eq(result.seven_pairs, None)
  assert_eq(result.thirteen_orphans, None)
  assert_eq(@analysis.waiting_tiles(input), [Numbered(Pin, 2)])
}

///|
test "complete fourteen-tile hands have minus-one shanten" {
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
    tile(Sou, 9),
    tile(Pin, 5),
    tile(Pin, 5),
  ])
  assert_eq(@analysis.calculate_shanten(input).minimum, -1)
  try @analysis.waiting_tiles(input) catch {
    InvalidHandSize(size) => assert_eq(size, 14)
    _ => fail("unexpected analysis error")
  } noraise {
    _ => fail("expected invalid hand size")
  }
}

///|
test "analysis validates tile copies and meld structure" {
  let invalid_tile : @mahjong.Tile = { kind: Numbered(Man, 10), is_red: false }
  let invalid = @analysis.AnalysisInput::new(Array::make(13, invalid_tile))
  try @analysis.calculate_shanten(invalid) catch {
    InvalidTile(_) => ()
    _ => fail("unexpected analysis error")
  } noraise {
    _ => fail("expected invalid tile")
  }
  let five_east = @analysis.AnalysisInput::new([
    honor(East),
    honor(East),
    honor(East),
    honor(East),
    honor(East),
    tile(Man, 1),
    tile(Man, 2),
    tile(Man, 3),
    tile(Pin, 1),
    tile(Pin, 2),
    tile(Pin, 3),
    tile(Sou, 1),
    tile(Sou, 2),
  ])
  try @analysis.calculate_shanten(five_east) catch {
    TooManyCopies(HonorTile(East), 5) => ()
    _ => fail("unexpected analysis error")
  } noraise {
    _ => fail("expected too many copies")
  }
}
