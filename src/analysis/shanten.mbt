///|
let orphan_indices : Array[Int] = [
  0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33,
]

///|
fn first_present(counts : Array[Int]) -> Int {
  for index in 0..<34 {
    if counts[index] > 0 {
      return index
    }
  }
  -1
}

///|
fn record_standard_shanten(
  melds : Int,
  taatsu : Int,
  has_pair : Bool,
  best : Ref[Int],
) -> Unit {
  let usable_taatsu = taatsu.min(4 - melds)
  let value = 8 - melds * 2 - usable_taatsu - (if has_pair { 1 } else { 0 })
  if value < best.val {
    best.val = value
  }
}

///|
fn search_standard(
  counts : Array[Int],
  melds : Int,
  taatsu : Int,
  has_pair : Bool,
  best : Ref[Int],
) -> Unit {
  let index = first_present(counts)
  if index == -1 {
    record_standard_shanten(melds, taatsu, has_pair, best)
    return
  }
  let rank = index % 9
  if melds < 4 && counts[index] >= 3 {
    counts[index] -= 3
    search_standard(counts, melds + 1, taatsu, has_pair, best)
    counts[index] += 3
  }
  if melds < 4 &&
    index < 27 &&
    rank <= 6 &&
    counts[index + 1] > 0 &&
    counts[index + 2] > 0 {
    counts[index] -= 1
    counts[index + 1] -= 1
    counts[index + 2] -= 1
    search_standard(counts, melds + 1, taatsu, has_pair, best)
    counts[index] += 1
    counts[index + 1] += 1
    counts[index + 2] += 1
  }
  if !has_pair && counts[index] >= 2 {
    counts[index] -= 2
    search_standard(counts, melds, taatsu, true, best)
    counts[index] += 2
  }
  if counts[index] >= 2 {
    counts[index] -= 2
    search_standard(counts, melds, taatsu + 1, has_pair, best)
    counts[index] += 2
  }
  if index < 27 && rank <= 7 && counts[index + 1] > 0 {
    counts[index] -= 1
    counts[index + 1] -= 1
    search_standard(counts, melds, taatsu + 1, has_pair, best)
    counts[index] += 1
    counts[index + 1] += 1
  }
  if index < 27 && rank <= 6 && counts[index + 2] > 0 {
    counts[index] -= 1
    counts[index + 2] -= 1
    search_standard(counts, melds, taatsu + 1, has_pair, best)
    counts[index] += 1
    counts[index + 2] += 1
  }
  counts[index] -= 1
  search_standard(counts, melds, taatsu, has_pair, best)
  counts[index] += 1
}

///|
fn standard_shanten(counts : Array[Int], fixed_melds : Int) -> Int {
  let best = Ref(8)
  search_standard(counts, fixed_melds, 0, false, best)
  best.val
}

///|
fn seven_pairs_shanten(counts : Array[Int]) -> Int {
  let mut pairs = 0
  let mut distinct = 0
  for count in counts {
    if count >= 2 {
      pairs += 1
    }
    if count > 0 {
      distinct += 1
    }
  }
  6 - pairs + (7 - distinct).max(0)
}

///|
fn thirteen_orphans_shanten(counts : Array[Int]) -> Int {
  let mut distinct = 0
  let mut has_pair = false
  for index in orphan_indices {
    if counts[index] > 0 {
      distinct += 1
    }
    if counts[index] >= 2 {
      has_pair = true
    }
  }
  13 - distinct - (if has_pair { 1 } else { 0 })
}

///|
fn shanten_from_counts(counts : Array[Int], meld_count : Int) -> ShantenResult {
  let standard = standard_shanten(counts, meld_count)
  let seven_pairs = if meld_count == 0 {
    Some(seven_pairs_shanten(counts))
  } else {
    None
  }
  let thirteen_orphans = if meld_count == 0 {
    Some(thirteen_orphans_shanten(counts))
  } else {
    None
  }
  let minimum = standard
    .min(seven_pairs.unwrap_or(standard))
    .min(thirteen_orphans.unwrap_or(standard))
  { minimum, standard, seven_pairs, thirteen_orphans }
}

///|
/// Calculate standard, seven-pairs, and thirteen-orphans shanten counts. The
/// input must contain thirteen or fourteen structural tiles.
pub fn calculate_shanten(
  input : AnalysisInput,
) -> ShantenResult raise AnalysisError {
  let validated = validate_input(input)
  shanten_from_counts(validated.concealed_counts, input.melds.length())
}
