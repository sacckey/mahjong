///|
fn dora_kind(indicator : TileKind) -> TileKind {
  match indicator {
    Numbered(suit, 9) => Numbered(suit, 1)
    Numbered(suit, rank) => Numbered(suit, rank + 1)
    HonorTile(East) => HonorTile(South)
    HonorTile(South) => HonorTile(West)
    HonorTile(West) => HonorTile(North)
    HonorTile(North) => HonorTile(East)
    HonorTile(White) => HonorTile(Green)
    HonorTile(Green) => HonorTile(Red)
    HonorTile(Red) => HonorTile(White)
  }
}

///|
fn count_indicator_dora(counts : Array[Int], indicators : Array[Tile]) -> Int {
  let mut total = 0
  for indicator in indicators {
    let kind = dora_kind(indicator.kind)
    total += counts[tile_kind_index_unchecked(kind)]
  }
  total
}

///|
fn count_red_tiles(input : HandInput) -> Int {
  let mut total = 0
  for tile in input.concealed_tiles {
    if tile.is_red {
      total += 1
    }
  }
  if input.winning_tile.is_red {
    total += 1
  }
  for meld in input.melds {
    for tile in meld.tiles {
      if tile.is_red {
        total += 1
      }
    }
  }
  total
}

///|
/// Count dora, ura-dora, and red dora in a validated hand.
///
/// Every supplied indicator is counted, including duplicates. Ura-dora are
/// counted only after riichi or double riichi. Indicator tiles themselves are
/// never included in red-dora totals.
fn calculate_bonus_han(input : HandInput) -> BonusHan raise ScoreError {
  let counts = hand_tile_counts(input)
  let dora = count_indicator_dora(counts, input.dora_indicators)
  let ura_dora = match input.context.riichi {
    Riichi | DoubleRiichi =>
      count_indicator_dora(counts, input.ura_dora_indicators)
    NoRiichi => 0
  }
  { dora, ura_dora, aka_dora: count_red_tiles(input) }
}
