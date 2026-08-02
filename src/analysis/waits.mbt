///|
/// Return all structural winning tile kinds in canonical 34-kind order. The
/// input must contain thirteen structural tiles.
pub fn waiting_tiles(
  input : AnalysisInput,
) -> Array[@mahjong.TileKind] raise AnalysisError {
  let validated = validate_input(input)
  require_tenpai_size(validated)
  let waits : Array[@mahjong.TileKind] = []
  for index in 0..<34 {
    if validated.total_counts[index] < 4 {
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
