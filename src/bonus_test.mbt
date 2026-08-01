///|
fn bt_m(rank : Int, red? : Bool = false) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Man, rank, red~)
}

///|
fn bt_p(rank : Int, red? : Bool = false) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Pin, rank, red~)
}

///|
fn bt_s(rank : Int, red? : Bool = false) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Sou, rank, red~)
}

///|
fn bt_h(honor : @mahjong.Honor) -> @mahjong.Tile {
  @mahjong.Tile::honor(honor)
}

///|
fn bt_context(riichi? : @mahjong.RiichiState = NoRiichi) -> @mahjong.WinContext {
  {
    win_method: Ron,
    seat_wind: South,
    round_wind: East,
    riichi,
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
}

///|
fn bt_input(
  concealed : Array[@mahjong.Tile],
  winning : @mahjong.Tile,
  melds? : Array[@mahjong.Meld] = [],
  dora? : Array[@mahjong.Tile] = [],
  ura? : Array[@mahjong.Tile] = [],
  context? : @mahjong.WinContext = bt_context(),
) -> @mahjong.HandInput {
  {
    concealed_tiles: concealed,
    winning_tile: winning,
    melds,
    dora_indicators: dora,
    ura_dora_indicators: ura,
    context,
  }
}

///|
fn bt_red_hand(
  context? : @mahjong.WinContext = bt_context(),
  dora? : Array[@mahjong.Tile] = [],
  ura? : Array[@mahjong.Tile] = [],
) -> @mahjong.HandInput {
  bt_input(
    [
      bt_m(5, red=true),
      bt_m(5),
      bt_p(5, red=true),
      bt_m(1),
      bt_m(2),
      bt_m(3),
      bt_p(1),
      bt_p(2),
      bt_p(3),
      bt_s(1),
      bt_s(2),
      bt_s(3),
      bt_h(East),
    ],
    bt_s(5, red=true),
    dora~,
    ura~,
    context~,
  )
}

///|
test "numbered nines and terminal honors wrap to the first tile" {
  let hand = bt_input(
    [
      bt_m(1),
      bt_m(1),
      bt_p(1),
      bt_s(1),
      bt_s(1),
      bt_s(1),
      bt_h(East),
      bt_h(East),
      bt_h(White),
      bt_h(White),
      bt_h(White),
      bt_m(2),
      bt_p(2),
    ],
    bt_h(White),
    dora=[bt_m(9), bt_p(9), bt_s(9), bt_h(North), bt_h(Red)],
  )
  assert_eq(try! @mahjong.calculate_bonus_han(hand), {
    dora: 12,
    ura_dora: 0,
    aka_dora: 0,
  })
}

///|
test "every honor indicator advances within its own cycle" {
  let hand = bt_input(
    [
      bt_h(East),
      bt_h(South),
      bt_h(West),
      bt_h(North),
      bt_h(White),
      bt_h(Green),
      bt_h(Red),
      bt_m(1),
      bt_m(2),
      bt_m(3),
      bt_p(1),
      bt_p(2),
      bt_p(3),
    ],
    bt_s(1),
    dora=[
      bt_h(East),
      bt_h(South),
      bt_h(West),
      bt_h(North),
      bt_h(White),
      bt_h(Green),
      bt_h(Red),
    ],
  )
  assert_eq(try! @mahjong.calculate_bonus_han(hand).dora, 7)
}

///|
test "red tiles are both aka dora and ordinary dora when indicated" {
  let hand = bt_red_hand(dora=[bt_m(4), bt_p(4), bt_s(4), bt_m(5, red=true)])
  assert_eq(try! @mahjong.calculate_bonus_han(hand), {
    dora: 4,
    ura_dora: 0,
    aka_dora: 3,
  })
}

///|
test "ura dora require riichi and duplicate indicators stack" {
  let indicators = [bt_m(4), bt_m(4), bt_p(4)]
  let no_riichi = bt_red_hand(ura=indicators)
  assert_eq(try! @mahjong.calculate_bonus_han(no_riichi).ura_dora, 0)
  let riichi = bt_red_hand(context=bt_context(riichi=Riichi), ura=indicators)
  assert_eq(try! @mahjong.calculate_bonus_han(riichi).ura_dora, 5)
  let double_riichi = bt_red_hand(
    context=bt_context(riichi=DoubleRiichi),
    ura=indicators,
  )
  assert_eq(try! @mahjong.calculate_bonus_han(double_riichi).ura_dora, 5)
}

///|
test "an open kan contributes all four physical tiles and its red tile" {
  let kan : @mahjong.Meld = {
    kind: OpenKan,
    tiles: [bt_m(5, red=true), bt_m(5), bt_m(5), bt_m(5)],
  }
  let hand = bt_input(
    [
      bt_m(1),
      bt_m(2),
      bt_m(3),
      bt_p(1),
      bt_p(2),
      bt_p(3),
      bt_s(1),
      bt_s(2),
      bt_s(3),
      bt_h(East),
    ],
    bt_h(East),
    melds=[kan],
    dora=[bt_m(4), bt_m(4)],
  )
  assert_eq(try! @mahjong.calculate_bonus_han(hand), {
    dora: 8,
    ura_dora: 0,
    aka_dora: 1,
  })
}

///|
test "bonus calculation validates indicator representations" {
  let hand = bt_red_hand()
  let invalid : @mahjong.HandInput = {
    ..hand,
    dora_indicators: [{ kind: Numbered(Man, 10), is_red: false }],
  }
  try @mahjong.calculate_bonus_han(invalid) catch {
    InvalidTile(_) => ()
    _ => fail("expected InvalidTile")
  } noraise {
    _ => fail("expected calculate_bonus_han to raise")
  }
}
