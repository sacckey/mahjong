///|
fn first_present_for_riichi_kan(counts : Array[Int32]) -> Int32 {
  for index in 0..<34 {
    if counts[index] > 0 {
      return index
    }
  }
  -1
}

///|
fn search_riichi_kan_groups(
  counts : Array[Int32],
  groups_left : Int32,
  kan_tile : Int32,
  used_required_triplet : Bool,
  found_completion : Ref[Bool],
) -> Bool {
  let index = first_present_for_riichi_kan(counts)
  if groups_left == 0 {
    if index != -1 {
      return false
    }
    if used_required_triplet {
      found_completion.val = true
      return false
    }
    return true
  }
  if index == -1 {
    return false
  }
  if counts[index] >= 3 && index != kan_tile {
    counts[index] -= 3
    let found_forbidden = search_riichi_kan_groups(
      counts,
      groups_left - 1,
      kan_tile,
      used_required_triplet,
      found_completion,
    )
    counts[index] += 3
    if found_forbidden {
      return true
    }
  }
  if index < 27 &&
    index % 9 <= 6 &&
    counts[index + 1] > 0 &&
    counts[index + 2] > 0 {
    counts[index] -= 1
    counts[index + 1] -= 1
    counts[index + 2] -= 1
    let found_forbidden = search_riichi_kan_groups(
      counts,
      groups_left - 1,
      kan_tile,
      used_required_triplet,
      found_completion,
    )
    counts[index] += 1
    counts[index + 1] += 1
    counts[index + 2] += 1
    if found_forbidden {
      return true
    }
  }
  if counts[index] >= 3 && index == kan_tile {
    counts[index] -= 3
    let found_forbidden = search_riichi_kan_groups(
      counts,
      groups_left - 1,
      kan_tile,
      true,
      found_completion,
    )
    counts[index] += 3
    if found_forbidden {
      return true
    }
  }
  false
}

///|
fn search_riichi_kan_completion(
  counts : Array[Int32],
  groups_needed : Int32,
  kan_tile : Int32,
  found_completion : Ref[Bool],
) -> Bool {
  for pair in 0..<34 {
    if counts[pair] >= 2 {
      counts[pair] -= 2
      let found_forbidden = search_riichi_kan_groups(
        counts, groups_needed, kan_tile, false, found_completion,
      )
      counts[pair] += 2
      if found_forbidden {
        return true
      }
    }
  }
  false
}

///|
/// Return whether `drawn_tile` may be declared as a closed kan after riichi
/// without changing the locked hand's group composition.
///
/// `input` is the thirteen-structural-tile hand locked by riichi, before the
/// draw. The drawn tile must be the fourth concealed copy of its kind. Every
/// winning interpretation of the locked hand must use the original three
/// copies as one concealed triplet. Yaku and visible remaining tiles are not
/// considered.
pub fn can_closed_kan_after_riichi(
  input : AnalysisInput,
  drawn_tile : @mahjong.Tile,
) -> Bool raise AnalysisError {
  let validated = validate_input(input)
  require_tenpai_size(validated)
  let kan_tile = tile_index(drawn_tile)
  if validated.total_counts[kan_tile] >= 4 {
    raise TooManyCopies(
      tile_kind_from_index(kan_tile),
      validated.total_counts[kan_tile] + 1,
    )
  }
  if input.melds.any(meld => !(meld.kind is ClosedKan)) ||
    validated.concealed_counts[kan_tile] != 3 {
    return false
  }
  let found_completion = Ref(false)
  let groups_needed = 4 - input.melds.length()
  for winning_tile in 0..<34 {
    if validated.total_counts[winning_tile] < 4 {
      validated.concealed_counts[winning_tile] += 1
      let found_forbidden = search_riichi_kan_completion(
        validated.concealed_counts,
        groups_needed,
        kan_tile,
        found_completion,
      )
      validated.concealed_counts[winning_tile] -= 1
      if found_forbidden {
        return false
      }
    }
  }
  found_completion.val
}
