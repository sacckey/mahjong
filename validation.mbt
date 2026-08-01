///|
fn tile_kind_index_unchecked(kind : TileKind) -> Int {
  match kind {
    Numbered(Man, rank) => rank - 1
    Numbered(Pin, rank) => 9 + rank - 1
    Numbered(Sou, rank) => 18 + rank - 1
    HonorTile(East) => 27
    HonorTile(South) => 28
    HonorTile(West) => 29
    HonorTile(North) => 30
    HonorTile(White) => 31
    HonorTile(Green) => 32
    HonorTile(Red) => 33
  }
}

///|
fn tile_kind_from_index(index : Int) -> TileKind {
  if index < 9 {
    Numbered(Man, index + 1)
  } else if index < 18 {
    Numbered(Pin, index - 8)
  } else if index < 27 {
    Numbered(Sou, index - 17)
  } else {
    match index {
      27 => HonorTile(East)
      28 => HonorTile(South)
      29 => HonorTile(West)
      30 => HonorTile(North)
      31 => HonorTile(White)
      32 => HonorTile(Green)
      _ => HonorTile(Red)
    }
  }
}

///|
/// Return the canonical 0-based index of a tile kind.
pub fn TileKind::index(self : TileKind) -> Int raise ScoreError {
  match self {
    Numbered(_, rank) if rank < 1 || rank > 9 =>
      raise InvalidTile("numbered tile rank must be between 1 and 9")
    _ => tile_kind_index_unchecked(self)
  }
}

///|
fn validate_tile(tile : Tile) -> Unit raise ScoreError {
  let _ = tile.kind.index()
  if tile.is_red {
    match tile.kind {
      Numbered(_, 5) => ()
      _ => raise InvalidTile("a red tile must be a numbered five")
    }
  }
}

///|
/// Construct a validated numbered tile.
pub fn Tile::numbered(
  suit : Suit,
  rank : Int,
  red? : Bool = false,
) -> Tile raise ScoreError {
  let tile = { kind: Numbered(suit, rank), is_red: red }
  validate_tile(tile)
  tile
}

///|
/// Construct an honor tile.
pub fn Tile::honor(honor : Honor) -> Tile {
  { kind: HonorTile(honor), is_red: false }
}

///|
fn add_hand_tile(counts : Array[Int], tile : Tile) -> Unit raise ScoreError {
  validate_tile(tile)
  let index = tile.kind.index()
  counts[index] += 1
  if counts[index] > 4 {
    raise TooManyCopies(tile.kind, counts[index])
  }
}

///|
fn validate_meld(meld : Meld) -> Unit raise ScoreError {
  let expected_length = match meld.kind {
    Chi | Pon => 3
    OpenKan | ClosedKan | AddedKan => 4
  }
  if meld.tiles.length() != expected_length {
    raise InvalidMeld("meld has an invalid number of tiles")
  }
  let indices : Array[Int] = []
  for tile in meld.tiles {
    validate_tile(tile)
    indices.push(tile.kind.index())
  }
  indices.sort_by((left, right) => left - right)
  match meld.kind {
    Chi =>
      if indices[0] >= 27 ||
        indices[0] / 9 != indices[2] / 9 ||
        indices[1] != indices[0] + 1 ||
        indices[2] != indices[0] + 2 {
        raise InvalidMeld(
          "chi must contain three consecutive tiles in one suit",
        )
      }
    Pon | OpenKan | ClosedKan | AddedKan =>
      if indices.any(index => index != indices[0]) {
        raise InvalidMeld("pon and kan must contain one tile kind")
      }
  }
}

///|
fn is_closed_hand(input : HandInput) -> Bool {
  input.melds.all(meld => meld.kind is ClosedKan)
}

///|
fn validate_context(input : HandInput) -> Unit raise ScoreError {
  let context = input.context
  if context.honba < 0 {
    raise ContradictoryContext("honba must not be negative")
  }
  if context.riichi_sticks < 0 {
    raise ContradictoryContext("riichi sticks must not be negative")
  }
  if context.riichi != NoRiichi && !is_closed_hand(input) {
    raise ContradictoryContext("an open hand cannot declare riichi")
  }
  if context.ippatsu && context.riichi is NoRiichi {
    raise ContradictoryContext("ippatsu requires riichi")
  }
  if context.rinshan && context.win_method is Ron {
    raise ContradictoryContext("rinshan kaihou requires tsumo")
  }
  if context.chankan && context.win_method is Tsumo {
    raise ContradictoryContext("chankan requires ron")
  }
  if context.haitei && context.win_method is Ron {
    raise ContradictoryContext("haitei requires tsumo")
  }
  if context.houtei && context.win_method is Tsumo {
    raise ContradictoryContext("houtei requires ron")
  }
  let terminal_event_count = (if context.rinshan { 1 } else { 0 }) +
    (if context.chankan { 1 } else { 0 }) +
    (if context.haitei { 1 } else { 0 }) +
    (if context.houtei { 1 } else { 0 })
  if terminal_event_count > 1 {
    raise ContradictoryContext(
      "rinshan, chankan, haitei, and houtei are mutually exclusive",
    )
  }
  if context.tenhou && context.chiihou {
    raise ContradictoryContext("tenhou and chiihou are mutually exclusive")
  }
  if context.tenhou {
    if context.win_method is Ron || !(context.seat_wind is East) {
      raise ContradictoryContext("tenhou requires an east-seat tsumo")
    }
    if !input.melds.is_empty() || !(context.riichi is NoRiichi) {
      raise ContradictoryContext("tenhou cannot have melds or riichi")
    }
  }
  if context.chiihou {
    if context.win_method is Ron || context.seat_wind is East {
      raise ContradictoryContext("chiihou requires a non-east-seat tsumo")
    }
    if !input.melds.is_empty() || !(context.riichi is NoRiichi) {
      raise ContradictoryContext("chiihou cannot have melds or riichi")
    }
  }
}

///|
/// Validate tile representations, melds, hand size, copy counts, and context.
pub fn validate_hand(input : HandInput) -> Unit raise ScoreError {
  let counts = Array::make(34, 0)
  for tile in input.concealed_tiles {
    add_hand_tile(counts, tile)
  }
  add_hand_tile(counts, input.winning_tile)
  for meld in input.melds {
    validate_meld(meld)
    for tile in meld.tiles {
      add_hand_tile(counts, tile)
    }
  }
  for tile in input.dora_indicators {
    validate_tile(tile)
  }
  for tile in input.ura_dora_indicators {
    validate_tile(tile)
  }
  let structural_size = input.concealed_tiles.length() +
    1 +
    input.melds.length() * 3
  if structural_size != 14 {
    raise InvalidHandSize(structural_size)
  }
  validate_context(input)
}

///|
/// Return physical hand-tile counts in canonical 34-kind order. Dora indicators
/// are not part of the returned counts.
pub fn hand_tile_counts(input : HandInput) -> Array[Int] raise ScoreError {
  validate_hand(input)
  let counts = Array::make(34, 0)
  for tile in input.concealed_tiles {
    counts[tile_kind_index_unchecked(tile.kind)] += 1
  }
  counts[tile_kind_index_unchecked(input.winning_tile.kind)] += 1
  for meld in input.melds {
    for tile in meld.tiles {
      counts[tile_kind_index_unchecked(tile.kind)] += 1
    }
  }
  counts
}
