///|
fn m(rank : Int) -> Tile {
  try! Tile::numbered(Man, rank)
}

///|
fn p(rank : Int) -> Tile {
  try! Tile::numbered(Pin, rank)
}

///|
fn s(rank : Int) -> Tile {
  try! Tile::numbered(Sou, rank)
}

///|
fn h(honor : Honor) -> Tile {
  Tile::honor(honor)
}

///|
fn context(
  win_method : WinMethod,
  riichi? : RiichiState = NoRiichi,
) -> WinContext {
  {
    win_method,
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
fn input(
  concealed_tiles : Array[Tile],
  winning_tile : Tile,
  melds? : Array[Meld] = [],
  win_context? : WinContext = context(Ron),
) -> HandInput {
  {
    concealed_tiles,
    winning_tile,
    melds,
    dora_indicators: [],
    ura_dora_indicators: [],
    context: win_context,
  }
}

///|
fn basic_standard_input() -> HandInput {
  input(
    [
      m(1),
      m(2),
      m(3),
      p(1),
      p(2),
      p(3),
      s(1),
      s(2),
      s(3),
      s(7),
      s(8),
      s(9),
      h(East),
    ],
    h(East),
  )
}

///|
test "tile kinds use canonical 34-kind indices" {
  assert_eq((Numbered(Man, 1) : TileKind).index(), 0)
  assert_eq((Numbered(Man, 9) : TileKind).index(), 8)
  assert_eq((Numbered(Pin, 1) : TileKind).index(), 9)
  assert_eq((Numbered(Sou, 9) : TileKind).index(), 26)
  assert_eq((HonorTile(East) : TileKind).index(), 27)
  assert_eq((HonorTile(Red) : TileKind).index(), 33)
}

///|
test "decompose a standard hand with a tanki wait" {
  let shapes = decompose(basic_standard_input())
  let expected : HandShape = Standard(
    pair=HonorTile(East),
    groups=[
      Sequence(Numbered(Man, 1), is_open=false),
      Sequence(Numbered(Pin, 1), is_open=false),
      Sequence(Numbered(Sou, 1), is_open=false),
      Sequence(Numbered(Sou, 7), is_open=false),
    ],
    wait=Tanki,
  )
  assert_eq(shapes, [expected])
  assert_true(is_winning_hand(basic_standard_input()))
}

///|
test "identify standard wait shapes" {
  let ryanmen = input(
    [
      m(4),
      m(5),
      p(1),
      p(2),
      p(3),
      s(1),
      s(2),
      s(3),
      s(7),
      s(8),
      s(9),
      h(East),
      h(East),
    ],
    m(3),
  )
  assert_true(
    decompose(ryanmen).any(shape => shape is Standard(wait=Ryanmen, ..)),
  )
  let kanchan = input(
    [
      m(3),
      m(5),
      p(1),
      p(2),
      p(3),
      s(1),
      s(2),
      s(3),
      s(7),
      s(8),
      s(9),
      h(East),
      h(East),
    ],
    m(4),
  )
  assert_true(
    decompose(kanchan).any(shape => shape is Standard(wait=Kanchan, ..)),
  )
  let penchan = input(
    [
      m(1),
      m(2),
      p(1),
      p(2),
      p(3),
      s(1),
      s(2),
      s(3),
      s(7),
      s(8),
      s(9),
      h(East),
      h(East),
    ],
    m(3),
  )
  assert_true(
    decompose(penchan).any(shape => shape is Standard(wait=Penchan, ..)),
  )
  let shanpon = input(
    [
      h(White),
      h(White),
      h(Green),
      h(Green),
      h(Green),
      p(1),
      p(2),
      p(3),
      s(1),
      s(2),
      s(3),
      h(East),
      h(East),
    ],
    h(White),
  )
  assert_true(
    decompose(shanpon).any(shape => shape is Standard(wait=Shanpon, ..)),
  )
}

///|
test "decompose called melds and normalize their tile order" {
  let chi : Meld = { kind: Chi, tiles: [m(3), m(1), m(2)] }
  let hand = input(
    [p(4), p(5), p(6), s(7), s(8), s(9), h(White), h(White), h(White), h(East)],
    h(East),
    melds=[chi],
  )
  let shapes = decompose(hand)
  assert_eq(shapes, [
    Standard(
      pair=HonorTile(East),
      groups=[
        Sequence(Numbered(Man, 1), is_open=true),
        Sequence(Numbered(Pin, 4), is_open=false),
        Sequence(Numbered(Sou, 7), is_open=false),
        Triplet(HonorTile(White), is_open=false),
      ],
      wait=Tanki,
    ),
  ])
  let counts = hand_tile_counts(hand)
  assert_eq(counts[0], 1)
  assert_eq(counts[1], 1)
  assert_eq(counts[2], 1)
  assert_eq(counts[27], 2)
  assert_eq(counts[31], 3)
}

///|
test "a closed kan keeps the hand closed and counts four physical tiles" {
  let closed_kan : Meld = { kind: ClosedKan, tiles: [m(1), m(1), m(1), m(1)] }
  let hand = input(
    [p(1), p(2), p(3), s(1), s(2), s(3), h(White), h(White), h(White), h(East)],
    h(East),
    melds=[closed_kan],
    win_context=context(Ron, riichi=Riichi),
  )
  validate_hand(hand)
  let shapes = decompose(hand)
  assert_true(
    shapes.any(shape => {
      shape
      is Standard(
        groups=[
          Quad(Numbered(Man, 1), is_open=false),
          Sequence(Numbered(Pin, 1), is_open=false),
          Sequence(Numbered(Sou, 1), is_open=false),
          Triplet(HonorTile(White), is_open=false),
        ],
        wait=Tanki,
        ..
      )
    }),
  )
  assert_eq(hand_tile_counts(hand)[0], 4)
}

///|
test "decompose seven pairs" {
  let hand = input(
    [
      m(1),
      m(1),
      m(2),
      m(2),
      p(3),
      p(3),
      p(4),
      p(4),
      s(5),
      s(5),
      s(6),
      s(6),
      h(East),
    ],
    h(East),
  )
  assert_eq(decompose(hand), [
    SevenPairs([
      Numbered(Man, 1),
      Numbered(Man, 2),
      Numbered(Pin, 3),
      Numbered(Pin, 4),
      Numbered(Sou, 5),
      Numbered(Sou, 6),
      HonorTile(East),
    ]),
  ])
}

///|
fn thirteen_orphans_tiles() -> Array[Tile] {
  [
    m(1),
    m(9),
    p(1),
    p(9),
    s(1),
    s(9),
    h(East),
    h(South),
    h(West),
    h(North),
    h(White),
    h(Green),
    h(Red),
  ]
}

///|
test "distinguish thirteen-sided and single thirteen-orphans waits" {
  let thirteen_sided = input(thirteen_orphans_tiles(), h(East))
  assert_eq(decompose(thirteen_sided), [
    ThirteenOrphans(wait=KokushiThirteenSided),
  ])
  let single = input(
    [
      m(1),
      m(9),
      p(1),
      p(9),
      s(1),
      s(9),
      h(South),
      h(South),
      h(West),
      h(North),
      h(White),
      h(Green),
      h(Red),
    ],
    h(East),
  )
  assert_eq(decompose(single), [ThirteenOrphans(wait=KokushiSingle)])
}

///|
test "enumerate every interpretation of an ambiguous hand" {
  let hand = input(
    [
      m(1),
      m(1),
      m(2),
      m(2),
      m(3),
      m(3),
      m(4),
      m(4),
      m(5),
      m(5),
      m(6),
      m(6),
      m(7),
    ],
    m(7),
  )
  let shapes = decompose(hand)
  assert_true(
    shapes.contains(
      SevenPairs([
        Numbered(Man, 1),
        Numbered(Man, 2),
        Numbered(Man, 3),
        Numbered(Man, 4),
        Numbered(Man, 5),
        Numbered(Man, 6),
        Numbered(Man, 7),
      ]),
    ),
  )
  assert_true(shapes.any(shape => shape is Standard(..)))
}

///|
test "tile order does not affect decomposition order" {
  let reordered = input(
    [
      h(East),
      s(9),
      s(8),
      s(7),
      s(3),
      s(2),
      s(1),
      p(3),
      p(2),
      p(1),
      m(3),
      m(2),
      m(1),
    ],
    h(East),
  )
  assert_eq(decompose(reordered), decompose(basic_standard_input()))
}

///|
test "reject invalid tiles and excess copies" {
  let invalid_rank : Tile = { kind: Numbered(Man, 0), is_red: false }
  let bad_rank = basic_standard_input()
  bad_rank.concealed_tiles[0] = invalid_rank
  try validate_hand(bad_rank) catch {
    InvalidTile(_) => ()
    _ => fail("expected InvalidTile")
  } noraise {
    _ => fail("expected validation to fail")
  }
  try Tile::numbered(Man, 4, red=true) catch {
    InvalidTile(_) => ()
    _ => fail("expected InvalidTile")
  } noraise {
    _ => fail("expected red-four construction to fail")
  }
  let five_copies = input(
    [
      m(1),
      m(1),
      m(1),
      m(1),
      m(2),
      m(3),
      m(4),
      m(5),
      m(6),
      m(7),
      m(8),
      m(9),
      h(East),
    ],
    m(1),
  )
  try validate_hand(five_copies) catch {
    TooManyCopies(Numbered(Man, 1), 5) => ()
    _ => fail("expected TooManyCopies")
  } noraise {
    _ => fail("expected validation to fail")
  }
}

///|
test "reject malformed melds, sizes, and contexts" {
  let bad_chi : Meld = { kind: Chi, tiles: [m(1), m(2), m(4)] }
  let malformed = input(
    [p(4), p(5), p(6), s(7), s(8), s(9), h(White), h(White), h(White), h(East)],
    h(East),
    melds=[bad_chi],
  )
  try validate_hand(malformed) catch {
    InvalidMeld(_) => ()
    _ => fail("expected InvalidMeld")
  } noraise {
    _ => fail("expected validation to fail")
  }
  let wrong_size = input([m(1), m(2), m(3)], m(4))
  try validate_hand(wrong_size) catch {
    InvalidHandSize(4) => ()
    _ => fail("expected InvalidHandSize")
  } noraise {
    _ => fail("expected validation to fail")
  }
  let chi : Meld = { kind: Chi, tiles: [m(1), m(2), m(3)] }
  let open_riichi = input(
    [p(4), p(5), p(6), s(7), s(8), s(9), h(White), h(White), h(White), h(East)],
    h(East),
    melds=[chi],
    win_context=context(Ron, riichi=Riichi),
  )
  try validate_hand(open_riichi) catch {
    ContradictoryContext(_) => ()
    _ => fail("expected ContradictoryContext")
  } noraise {
    _ => fail("expected validation to fail")
  }
}

///|
test "an incomplete hand is not a winning hand" {
  let incomplete = input(
    [
      m(1),
      m(1),
      m(2),
      m(4),
      m(5),
      m(7),
      p(2),
      p(3),
      p(5),
      s(1),
      s(4),
      s(8),
      h(East),
    ],
    h(South),
  )
  assert_false(is_winning_hand(incomplete))
  try decompose(incomplete) catch {
    NotWinningHand => ()
    _ => fail("expected NotWinningHand")
  } noraise {
    _ => fail("expected decomposition to fail")
  }
}
