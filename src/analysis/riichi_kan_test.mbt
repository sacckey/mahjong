///|
fn numbered(suit : @mahjong.Suit, rank : Int) -> @mahjong.Tile raise {
  @mahjong.Tile::numbered(suit, rank)
}

///|
test "riichi closed kan accepts an independent concealed triplet" {
  let input = @analysis.AnalysisInput::new([
    numbered(Man, 5),
    numbered(Man, 5),
    numbered(Man, 5),
    numbered(Pin, 1),
    numbered(Pin, 2),
    numbered(Pin, 3),
    numbered(Pin, 4),
    numbered(Pin, 5),
    numbered(Pin, 6),
    numbered(Sou, 7),
    numbered(Sou, 8),
    @mahjong.Tile::honor(East),
    @mahjong.Tile::honor(East),
  ])
  assert_true(@analysis.can_closed_kan_after_riichi(input, numbered(Man, 5)))
}

///|
test "riichi closed kan rejects when the kan tile is also a winning tile" {
  let input = @analysis.AnalysisInput::new([
    numbered(Man, 3),
    numbered(Man, 4),
    numbered(Man, 5),
    numbered(Man, 5),
    numbered(Man, 5),
    numbered(Pin, 1),
    numbered(Pin, 2),
    numbered(Pin, 3),
    numbered(Sou, 7),
    numbered(Sou, 8),
    numbered(Sou, 9),
    @mahjong.Tile::honor(East),
    @mahjong.Tile::honor(East),
  ])
  assert_false(@analysis.can_closed_kan_after_riichi(input, numbered(Man, 5)))
}

///|
test "riichi closed kan rejects one forbidden decomposition among valid ones" {
  let input = @analysis.AnalysisInput::new([
    numbered(Man, 1),
    numbered(Man, 1),
    numbered(Man, 1),
    numbered(Man, 1),
    numbered(Man, 2),
    numbered(Man, 2),
    numbered(Man, 3),
    numbered(Man, 3),
    numbered(Man, 4),
    numbered(Man, 5),
    numbered(Man, 7),
    numbered(Man, 7),
    numbered(Man, 7),
  ])
  assert_false(@analysis.can_closed_kan_after_riichi(input, numbered(Man, 7)))
}

///|
test "riichi closed kan supports an existing closed kan" {
  let closed_kan : @mahjong.Meld = {
    kind: ClosedKan,
    tiles: [
      numbered(Sou, 1),
      numbered(Sou, 1),
      numbered(Sou, 1),
      numbered(Sou, 1),
    ],
  }
  let input = @analysis.AnalysisInput::new(
    [
      numbered(Man, 5),
      numbered(Man, 5),
      numbered(Man, 5),
      numbered(Pin, 1),
      numbered(Pin, 2),
      numbered(Pin, 3),
      numbered(Pin, 7),
      numbered(Pin, 8),
      @mahjong.Tile::honor(East),
      @mahjong.Tile::honor(East),
    ],
    melds=[closed_kan],
  )
  assert_true(@analysis.can_closed_kan_after_riichi(input, numbered(Man, 5)))
}

///|
test "riichi closed kan rejects unmet structural prerequisites" {
  let input = @analysis.AnalysisInput::new([
    numbered(Man, 1),
    numbered(Man, 2),
    numbered(Man, 3),
    numbered(Man, 4),
    numbered(Man, 5),
    numbered(Man, 6),
    numbered(Pin, 1),
    numbered(Pin, 2),
    numbered(Pin, 3),
    numbered(Sou, 7),
    numbered(Sou, 8),
    numbered(Pin, 5),
    numbered(Pin, 5),
  ])
  assert_false(@analysis.can_closed_kan_after_riichi(input, numbered(Pin, 5)))
}
