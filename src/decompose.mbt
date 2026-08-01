///|
fn concealed_winning_counts(input : HandInput) -> Array[Int] {
  let counts = Array::make(34, 0)
  for tile in input.concealed_tiles {
    counts[tile_kind_index_unchecked(tile.kind)] += 1
  }
  counts[tile_kind_index_unchecked(input.winning_tile.kind)] += 1
  counts
}

///|
fn first_present_tile(counts : Array[Int]) -> Int {
  let mut found = -1
  for index in 0..<34 {
    if found == -1 && counts[index] > 0 {
      found = index
    }
  }
  found
}

///|
fn collect_closed_groups(
  counts : Array[Int],
  groups_left : Int,
  groups : Array[Group],
  results : Array[Array[Group]],
) -> Unit {
  let index = first_present_tile(counts)
  if groups_left == 0 {
    if index == -1 {
      results.push(groups.copy())
    }
    return
  }
  if index == -1 {
    return
  }
  if counts[index] >= 3 {
    counts[index] -= 3
    groups.push(Triplet(tile_kind_from_index(index), is_open=false))
    collect_closed_groups(counts, groups_left - 1, groups, results)
    ignore(groups.pop())
    counts[index] += 3
  }
  if index < 27 &&
    index % 9 <= 6 &&
    counts[index + 1] > 0 &&
    counts[index + 2] > 0 {
    counts[index] -= 1
    counts[index + 1] -= 1
    counts[index + 2] -= 1
    groups.push(Sequence(tile_kind_from_index(index), is_open=false))
    collect_closed_groups(counts, groups_left - 1, groups, results)
    ignore(groups.pop())
    counts[index] += 1
    counts[index + 1] += 1
    counts[index + 2] += 1
  }
}

///|
fn meld_to_group(meld : Meld) -> Group {
  let index = tile_kind_index_unchecked(meld.tiles[0].kind)
  match meld.kind {
    Chi => {
      let mut first = index
      for tile in meld.tiles {
        let tile_index = tile_kind_index_unchecked(tile.kind)
        if tile_index < first {
          first = tile_index
        }
      }
      Sequence(tile_kind_from_index(first), is_open=true)
    }
    Pon => Triplet(tile_kind_from_index(index), is_open=true)
    OpenKan | AddedKan => Quad(tile_kind_from_index(index), is_open=true)
    ClosedKan => Quad(tile_kind_from_index(index), is_open=false)
  }
}

///|
fn group_sort_key(group : Group) -> Int {
  match group {
    Sequence(kind, is_open~) =>
      tile_kind_index_unchecked(kind) * 10 + (if is_open { 1 } else { 0 })
    Triplet(kind, is_open~) =>
      tile_kind_index_unchecked(kind) * 10 + 2 + (if is_open { 1 } else { 0 })
    Quad(kind, is_open~) =>
      tile_kind_index_unchecked(kind) * 10 + 4 + (if is_open { 1 } else { 0 })
  }
}

///|
fn sorted_complete_groups(
  closed_groups : Array[Group],
  input : HandInput,
) -> Array[Group] {
  let groups = closed_groups.copy()
  for meld in input.melds {
    groups.push(meld_to_group(meld))
  }
  groups.sort_by((left, right) => group_sort_key(left) - group_sort_key(right))
  groups
}

///|
fn wait_for_sequence(start : Int, winning : Int) -> WaitKind {
  let start_rank = start % 9 + 1
  let offset = winning - start
  if offset == 1 {
    Kanchan
  } else if (start_rank == 1 && offset == 2) || (start_rank == 7 && offset == 0) {
    Penchan
  } else {
    Ryanmen
  }
}

///|
fn waits_for_standard_shape(
  pair : Int,
  closed_groups : Array[Group],
  winning : Int,
) -> Array[WaitKind] {
  let waits : Array[WaitKind] = []
  if pair == winning {
    waits.push(Tanki)
  }
  for group in closed_groups {
    match group {
      Triplet(kind, is_open=false) =>
        if tile_kind_index_unchecked(kind) == winning &&
          !waits.contains(Shanpon) {
          waits.push(Shanpon)
        }
      Sequence(kind, is_open=false) => {
        let start = tile_kind_index_unchecked(kind)
        if winning >= start && winning <= start + 2 {
          let wait = wait_for_sequence(start, winning)
          if !waits.contains(wait) {
            waits.push(wait)
          }
        }
      }
      _ => ()
    }
  }
  waits
}

///|
fn collect_standard_shapes(
  input : HandInput,
  shapes : Array[HandShape],
) -> Unit {
  let counts = concealed_winning_counts(input)
  let groups_needed = 4 - input.melds.length()
  let winning = tile_kind_index_unchecked(input.winning_tile.kind)
  for pair in 0..<34 {
    if counts[pair] >= 2 {
      counts[pair] -= 2
      let closed_group_sets : Array[Array[Group]] = []
      collect_closed_groups(counts, groups_needed, [], closed_group_sets)
      counts[pair] += 2
      for closed_groups in closed_group_sets {
        let waits = waits_for_standard_shape(pair, closed_groups, winning)
        let groups = sorted_complete_groups(closed_groups, input)
        for wait in waits {
          let shape = Standard(
            pair=tile_kind_from_index(pair),
            groups=groups.copy(),
            wait~,
          )
          if !shapes.contains(shape) {
            shapes.push(shape)
          }
        }
      }
    }
  }
}

///|
fn seven_pairs_shape(input : HandInput) -> HandShape? {
  if !input.melds.is_empty() {
    return None
  }
  let counts = concealed_winning_counts(input)
  let pairs : Array[TileKind] = []
  for index, count in counts {
    if count == 2 {
      pairs.push(tile_kind_from_index(index))
    } else if count != 0 {
      return None
    }
  }
  if pairs.length() == 7 {
    Some(SevenPairs(pairs))
  } else {
    None
  }
}

///|
let orphan_indices : Array[Int] = [
  0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33,
]

///|
fn is_orphan_index(index : Int) -> Bool {
  orphan_indices.contains(index)
}

///|
fn thirteen_orphans_shape(input : HandInput) -> HandShape? {
  if !input.melds.is_empty() {
    return None
  }
  let counts = concealed_winning_counts(input)
  let mut pair_count = 0
  for index, count in counts {
    if is_orphan_index(index) {
      if count == 2 {
        pair_count += 1
      } else if count != 1 {
        return None
      }
    } else if count != 0 {
      return None
    }
  }
  if pair_count != 1 {
    return None
  }
  let concealed = Array::make(34, 0)
  for tile in input.concealed_tiles {
    concealed[tile_kind_index_unchecked(tile.kind)] += 1
  }
  let thirteen_sided = orphan_indices.all(index => concealed[index] == 1)
  if thirteen_sided {
    Some(ThirteenOrphans(wait=KokushiThirteenSided))
  } else {
    Some(ThirteenOrphans(wait=KokushiSingle))
  }
}

///|
/// Enumerate every standard, seven-pairs, and thirteen-orphans interpretation
/// of a validated winning hand.
fn decompose(input : HandInput) -> Array[HandShape] raise ScoreError {
  validate_hand(input)
  let shapes : Array[HandShape] = []
  collect_standard_shapes(input, shapes)
  if seven_pairs_shape(input) is Some(shape) {
    shapes.push(shape)
  }
  if thirteen_orphans_shape(input) is Some(shape) {
    shapes.push(shape)
  }
  if shapes.is_empty() {
    raise NotWinningHand
  }
  shapes
}

///|
/// Return false for both invalid and structurally incomplete hands.
pub fn is_winning_hand(input : HandInput) -> Bool {
  try decompose(input) catch {
    _ => false
  } noraise {
    _ => true
  }
}
