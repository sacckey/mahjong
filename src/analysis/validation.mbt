///|
fn tile_index(tile : @mahjong.Tile) -> Int raise AnalysisError {
  let index = match tile.kind {
    Numbered(Man, rank) if rank >= 1 && rank <= 9 => rank - 1
    Numbered(Pin, rank) if rank >= 1 && rank <= 9 => 9 + rank - 1
    Numbered(Sou, rank) if rank >= 1 && rank <= 9 => 18 + rank - 1
    Numbered(_, _) =>
      raise InvalidTile("numbered tile rank must be between 1 and 9")
    HonorTile(East) => 27
    HonorTile(South) => 28
    HonorTile(West) => 29
    HonorTile(North) => 30
    HonorTile(White) => 31
    HonorTile(Green) => 32
    HonorTile(Red) => 33
  }
  if tile.is_red {
    match tile.kind {
      Numbered(_, 5) => ()
      _ => raise InvalidTile("a red tile must be a numbered five")
    }
  }
  index
}

///|
fn tile_kind_from_index(index : Int) -> @mahjong.TileKind {
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
fn validate_meld(meld : @mahjong.Meld) -> Array[Int] raise AnalysisError {
  let expected_length = match meld.kind {
    Chi | Pon => 3
    OpenKan | ClosedKan | AddedKan => 4
  }
  if meld.tiles.length() != expected_length {
    raise InvalidMeld("meld has an invalid number of tiles")
  }
  let indices : Array[Int] = []
  for tile in meld.tiles {
    indices.push(tile_index(tile))
  }
  indices.sort()
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
  indices
}

///|
priv struct ValidatedInput {
  concealed_counts : Array[Int]
  total_counts : Array[Int]
  structural_size : Int
}

///|
fn add_count(
  counts : Array[Int],
  index : Int,
  kind : @mahjong.TileKind,
) -> Unit raise AnalysisError {
  counts[index] += 1
  if counts[index] > 4 {
    raise TooManyCopies(kind, counts[index])
  }
}

///|
fn validate_input(input : AnalysisInput) -> ValidatedInput raise AnalysisError {
  let concealed_counts = Array::make(34, 0)
  let total_counts = Array::make(34, 0)
  for tile in input.concealed_tiles {
    let index = tile_index(tile)
    add_count(concealed_counts, index, tile.kind)
    add_count(total_counts, index, tile.kind)
  }
  for meld in input.melds {
    let indices = validate_meld(meld)
    for index in indices {
      add_count(total_counts, index, tile_kind_from_index(index))
    }
  }
  let structural_size = input.concealed_tiles.length() +
    input.melds.length() * 3
  if structural_size != 13 && structural_size != 14 {
    raise InvalidHandSize(structural_size)
  }
  { concealed_counts, total_counts, structural_size }
}

///|
fn require_tenpai_size(validated : ValidatedInput) -> Unit raise AnalysisError {
  if validated.structural_size != 13 {
    raise InvalidHandSize(validated.structural_size)
  }
}
