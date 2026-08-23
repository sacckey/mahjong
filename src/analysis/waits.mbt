///|
/// Return all structural winning tile kinds in canonical 34-kind order. The
/// input must contain thirteen structural tiles.
pub fn waiting_tiles(
  input : AnalysisInput,
) -> Array[@mahjong.TileKind] raise AnalysisError {
  waiting_tiles_with_tile_copy_rules(input, @mahjong.TileCopyRules::standard())
}

///|
/// Return structural winning tile kinds with an explicit physical-tile copy
/// limit. With unlimited copies, a fifth identical tile may be a wait.
pub fn waiting_tiles_with_tile_copy_rules(
  input : AnalysisInput,
  tile_copy_rules : @mahjong.TileCopyRules,
) -> Array[@mahjong.TileKind] raise AnalysisError {
  let validated = validate_input_with_tile_copy_rules(input, tile_copy_rules)
  require_tenpai_size(validated)
  let waits : Array[@mahjong.TileKind] = []
  for index in 0..<34 {
    let copy_available = match tile_copy_rules.max_copies_per_kind {
      Some(limit) => validated.total_counts[index] < limit
      None => true
    }
    if copy_available {
      validated.concealed_counts[index] += 1
      let result = shanten_from_counts(
        validated.concealed_counts,
        input.melds.length(),
      )
      validated.concealed_counts[index] -= 1
      if result.minimum == -1 {
        waits.push(tile_kind_from_index(index))
      }
    }
  }
  waits
}

///|
/// Return whether a thirteen-structural-tile hand has at least one structural
/// winning tile. Yaku and furiten are intentionally not considered.
pub fn is_tenpai(input : AnalysisInput) -> Bool raise AnalysisError {
  !waiting_tiles(input).is_empty()
}

///|
/// Return whether the hand is structurally tenpai with an explicit physical-
/// tile copy limit.
pub fn is_tenpai_with_tile_copy_rules(
  input : AnalysisInput,
  tile_copy_rules : @mahjong.TileCopyRules,
) -> Bool raise AnalysisError {
  !waiting_tiles_with_tile_copy_rules(input, tile_copy_rules).is_empty()
}
