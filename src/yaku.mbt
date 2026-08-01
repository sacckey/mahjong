///|
fn yaku_value(yaku : Yaku, han : Int) -> YakuValue {
  { yaku, han, yakuman_multiplier: 0 }
}

///|
fn yakuman_value(yaku : Yaku, multiplier : Int) -> YakuValue {
  { yaku, han: 0, yakuman_multiplier: multiplier }
}

///|
fn double_if_enabled(rules : RuleSet) -> Int {
  if rules.double_yakuman {
    2
  } else {
    1
  }
}

///|
fn is_honor(index : Int) -> Bool {
  index >= 27
}

///|
fn is_terminal(index : Int) -> Bool {
  index < 27 && (index % 9 == 0 || index % 9 == 8)
}

///|
fn is_terminal_or_honor(index : Int) -> Bool {
  is_terminal(index) || is_honor(index)
}

///|
fn wind_index(wind : Wind) -> Int {
  match wind {
    East => 27
    South => 28
    West => 29
    North => 30
  }
}

///|
fn group_is_open(group : Group) -> Bool {
  match group {
    Sequence(_, is_open~) | Triplet(_, is_open~) | Quad(_, is_open~) => is_open
  }
}

///|
fn shape_is_closed(shape : HandShape) -> Bool {
  match shape {
    Standard(groups~, ..) => groups.all(group => !group_is_open(group))
    SevenPairs(_) | ThirteenOrphans(_) => true
  }
}

///|
fn group_kind_index(group : Group) -> Int {
  match group {
    Sequence(kind, ..) | Triplet(kind, ..) | Quad(kind, ..) =>
      tile_kind_index_unchecked(kind)
  }
}

///|
fn group_is_triplet_or_quad(group : Group) -> Bool {
  group is Triplet(_, ..) || group is Quad(_, ..)
}

///|
fn count_triplets(groups : Array[Group], first : Int, last : Int) -> Int {
  let mut count = 0
  for group in groups {
    if group_is_triplet_or_quad(group) {
      let index = group_kind_index(group)
      if index >= first && index <= last {
        count += 1
      }
    }
  }
  count
}

///|
fn all_tiles_match(counts : Array[Int], predicate : (Int) -> Bool) -> Bool {
  for index, count in counts {
    if count > 0 && !predicate(index) {
      return false
    }
  }
  true
}

///|
fn numbered_suit_mask(counts : Array[Int]) -> Int {
  let mut mask = 0
  for index in 0..<27 {
    if counts[index] > 0 {
      mask = mask | (1 << (index / 9))
    }
  }
  mask
}

///|
fn has_honor_tiles(counts : Array[Int]) -> Bool {
  for index in 27..<34 {
    if counts[index] > 0 {
      return true
    }
  }
  false
}

///|
fn is_tanyao(counts : Array[Int]) -> Bool {
  all_tiles_match(counts, index => index < 27 && !is_terminal(index))
}

///|
fn group_contains_terminal_or_honor(group : Group) -> Bool {
  match group {
    Sequence(kind, ..) => {
      let rank = tile_kind_index_unchecked(kind) % 9 + 1
      rank == 1 || rank == 7
    }
    Triplet(kind, ..) | Quad(kind, ..) =>
      is_terminal_or_honor(tile_kind_index_unchecked(kind))
  }
}

///|
fn group_contains_terminal(group : Group) -> Bool {
  match group {
    Sequence(kind, ..) => {
      let rank = tile_kind_index_unchecked(kind) % 9 + 1
      rank == 1 || rank == 7
    }
    Triplet(kind, ..) | Quad(kind, ..) =>
      is_terminal(tile_kind_index_unchecked(kind))
  }
}

///|
fn has_sequence(groups : Array[Group]) -> Bool {
  groups.any(group => group is Sequence(_, ..))
}

///|
fn sequence_count(groups : Array[Group], start : Int) -> Int {
  let mut count = 0
  for group in groups {
    match group {
      Sequence(kind, ..) if tile_kind_index_unchecked(kind) == start =>
        count += 1
      _ => ()
    }
  }
  count
}

///|
fn has_sanshoku_doujun(groups : Array[Group]) -> Bool {
  for rank in 0..<7 {
    if sequence_count(groups, rank) > 0 &&
      sequence_count(groups, 9 + rank) > 0 &&
      sequence_count(groups, 18 + rank) > 0 {
      return true
    }
  }
  false
}

///|
fn has_ittsu(groups : Array[Group]) -> Bool {
  for suit in 0..<3 {
    let base = suit * 9
    if sequence_count(groups, base) > 0 &&
      sequence_count(groups, base + 3) > 0 &&
      sequence_count(groups, base + 6) > 0 {
      return true
    }
  }
  false
}

///|
fn peikou_pairs(groups : Array[Group]) -> Int {
  let mut pairs = 0
  for start in 0..<27 {
    if start % 9 <= 6 {
      pairs += sequence_count(groups, start) / 2
    }
  }
  pairs
}

///|
fn has_sanshoku_doukou(groups : Array[Group]) -> Bool {
  for rank in 0..<9 {
    let mut suits = 0
    for suit in 0..<3 {
      let wanted = suit * 9 + rank
      if groups.any(group => {
          group_is_triplet_or_quad(group) && group_kind_index(group) == wanted
        }) {
        suits += 1
      }
    }
    if suits == 3 {
      return true
    }
  }
  false
}

///|
fn is_value_pair(pair : TileKind, context : WinContext) -> Bool {
  let index = tile_kind_index_unchecked(pair)
  index >= 31 ||
  index == wind_index(context.seat_wind) ||
  index == wind_index(context.round_wind)
}

///|
fn concealed_triplet_count(input : HandInput, shape : HandShape) -> Int {
  match shape {
    Standard(groups~, wait~, ..) => {
      let winning = tile_kind_index_unchecked(input.winning_tile.kind)
      let mut count = 0
      for group in groups {
        match group {
          Triplet(kind, is_open=false) | Quad(kind, is_open=false) =>
            if !(input.context.win_method is Ron &&
              wait is Shanpon &&
              tile_kind_index_unchecked(kind) == winning) {
              count += 1
            }
          _ => ()
        }
      }
      count
    }
    _ => 0
  }
}

///|
fn is_chuuren(counts : Array[Int], shape : HandShape) -> Bool {
  let suit_mask = numbered_suit_mask(counts)
  if !shape_is_closed(shape) ||
    !(suit_mask == 1 || suit_mask == 2 || suit_mask == 4) ||
    has_honor_tiles(counts) {
    return false
  }
  let suit = if suit_mask == 1 { 0 } else if suit_mask == 2 { 1 } else { 2 }
  let base = suit * 9
  let required : Array[Int] = [3, 1, 1, 1, 1, 1, 1, 1, 3]
  let mut extras = 0
  for rank, minimum in required {
    if counts[base + rank] < minimum {
      return false
    }
    extras += counts[base + rank] - minimum
  }
  extras == 1
}

///|
fn is_pure_chuuren_wait(input : HandInput) -> Bool {
  if !input.melds.is_empty() {
    return false
  }
  let counts = Array::make(34, 0)
  for tile in input.concealed_tiles {
    counts[tile_kind_index_unchecked(tile.kind)] += 1
  }
  let suit = tile_kind_index_unchecked(input.winning_tile.kind) / 9
  if suit >= 3 {
    return false
  }
  let base = suit * 9
  let required : Array[Int] = [3, 1, 1, 1, 1, 1, 1, 1, 3]
  for rank, expected in required {
    if counts[base + rank] != expected {
      return false
    }
  }
  for index in 0..<34 {
    if (index < base || index >= base + 9) && counts[index] != 0 {
      return false
    }
  }
  true
}

///|
fn detect_yakuman(
  input : HandInput,
  shape : HandShape,
  counts : Array[Int],
  rules : RuleSet,
) -> Array[YakuValue] {
  let result : Array[YakuValue] = []
  if input.context.tenhou {
    result.push(yakuman_value(Tenhou, 1))
  }
  if input.context.chiihou {
    result.push(yakuman_value(Chiihou, 1))
  }
  match shape {
    ThirteenOrphans(wait~) => {
      let multiplier = if wait is KokushiThirteenSided {
        double_if_enabled(rules)
      } else {
        1
      }
      result.push(yakuman_value(KokushiMusou, multiplier))
    }
    Standard(pair~, groups~, wait~) => {
      if concealed_triplet_count(input, shape) == 4 {
        let multiplier = if wait is Tanki {
          double_if_enabled(rules)
        } else {
          1
        }
        result.push(yakuman_value(Suuankou, multiplier))
      }
      if count_triplets(groups, 31, 33) == 3 {
        result.push(yakuman_value(Daisangen, 1))
      }
      let wind_triplets = count_triplets(groups, 27, 30)
      let pair_index = tile_kind_index_unchecked(pair)
      if wind_triplets == 3 && pair_index >= 27 && pair_index <= 30 {
        result.push(yakuman_value(Shousuushi, 1))
      }
      if wind_triplets == 4 {
        result.push(yakuman_value(Daisuushi, double_if_enabled(rules)))
      }
      if groups.filter(group => group is Quad(_, ..)).length() == 4 {
        result.push(yakuman_value(Suukantsu, 1))
      }
    }
    SevenPairs(_) => ()
  }
  if all_tiles_match(counts, is_honor) {
    result.push(yakuman_value(Tsuuiisou, 1))
  }
  let green = [19, 20, 21, 23, 25, 32]
  if all_tiles_match(counts, index => green.contains(index)) {
    result.push(yakuman_value(Ryuuiisou, 1))
  }
  if all_tiles_match(counts, is_terminal) {
    result.push(yakuman_value(Chinroutou, 1))
  }
  if is_chuuren(counts, shape) {
    let multiplier = if is_pure_chuuren_wait(input) {
      double_if_enabled(rules)
    } else {
      1
    }
    result.push(yakuman_value(ChuurenPoutou, multiplier))
  }
  result
}

///|
fn append_context_yaku(
  result : Array[YakuValue],
  input : HandInput,
  closed : Bool,
) -> Unit {
  match input.context.riichi {
    Riichi => result.push(yaku_value(Riichi, 1))
    DoubleRiichi => result.push(yaku_value(DoubleRiichi, 2))
    NoRiichi => ()
  }
  if input.context.ippatsu {
    result.push(yaku_value(Ippatsu, 1))
  }
  if closed && input.context.win_method is Tsumo {
    result.push(yaku_value(MenzenTsumo, 1))
  }
  if input.context.rinshan {
    result.push(yaku_value(RinshanKaihou, 1))
  }
  if input.context.chankan {
    result.push(yaku_value(Chankan, 1))
  }
  if input.context.haitei {
    result.push(yaku_value(HaiteiRaoyue, 1))
  }
  if input.context.houtei {
    result.push(yaku_value(HouteiRaoyui, 1))
  }
}

///|
fn append_flush_yaku(
  result : Array[YakuValue],
  counts : Array[Int],
  closed : Bool,
) -> Unit {
  let mask = numbered_suit_mask(counts)
  if mask == 1 || mask == 2 || mask == 4 {
    if has_honor_tiles(counts) {
      result.push(yaku_value(Honitsu, if closed { 3 } else { 2 }))
    } else {
      result.push(yaku_value(Chinitsu, if closed { 6 } else { 5 }))
    }
  }
}

///|
fn append_standard_yaku(
  result : Array[YakuValue],
  input : HandInput,
  shape : HandShape,
  counts : Array[Int],
  pair : TileKind,
  groups : Array[Group],
  wait : WaitKind,
  closed : Bool,
) -> Unit {
  if closed &&
    groups.all(group => group is Sequence(_, ..)) &&
    !is_value_pair(pair, input.context) &&
    wait is Ryanmen {
    result.push(yaku_value(Pinfu, 1))
  }
  if closed {
    let pairs = peikou_pairs(groups)
    if pairs >= 2 {
      result.push(yaku_value(Ryanpeikou, 3))
    } else if pairs == 1 {
      result.push(yaku_value(Iipeikou, 1))
    }
  }
  for
    item in [
      (wind_index(input.context.seat_wind), SeatWind),
      (wind_index(input.context.round_wind), RoundWind),
      (31, WhiteDragon),
      (32, GreenDragon),
      (33, RedDragon),
    ] {
    let (index, yaku) = item
    if groups.any(group => {
        group_is_triplet_or_quad(group) && group_kind_index(group) == index
      }) {
      result.push(yaku_value(yaku, 1))
    }
  }
  if has_sanshoku_doujun(groups) {
    result.push(yaku_value(SanshokuDoujun, if closed { 2 } else { 1 }))
  }
  if has_ittsu(groups) {
    result.push(yaku_value(Ittsu, if closed { 2 } else { 1 }))
  }
  let pair_index = tile_kind_index_unchecked(pair)
  let every_terminal_or_honor = is_terminal_or_honor(pair_index) &&
    groups.all(group_contains_terminal_or_honor)
  let every_terminal = is_terminal(pair_index) &&
    groups.all(group_contains_terminal)
  if every_terminal && has_sequence(groups) {
    result.push(yaku_value(Junchan, if closed { 3 } else { 2 }))
  } else if every_terminal_or_honor &&
    has_sequence(groups) &&
    has_honor_tiles(counts) {
    result.push(yaku_value(Chanta, if closed { 2 } else { 1 }))
  }
  if groups.all(group_is_triplet_or_quad) {
    result.push(yaku_value(Toitoi, 2))
  }
  if concealed_triplet_count(input, shape) >= 3 {
    result.push(yaku_value(Sanankou, 2))
  }
  if has_sanshoku_doukou(groups) {
    result.push(yaku_value(SanshokuDoukou, 2))
  }
  if groups.filter(group => group is Quad(_, ..)).length() >= 3 {
    result.push(yaku_value(Sankantsu, 2))
  }
  if count_triplets(groups, 31, 33) == 2 && pair_index >= 31 {
    result.push(yaku_value(Shousangen, 2))
  }
}

///|
fn detect_regular_yaku(
  input : HandInput,
  shape : HandShape,
  counts : Array[Int],
  rules : RuleSet,
) -> Array[YakuValue] {
  let result : Array[YakuValue] = []
  let closed = shape_is_closed(shape)
  append_context_yaku(result, input, closed)
  if is_tanyao(counts) && (closed || rules.open_tanyao) {
    result.push(yaku_value(Tanyao, 1))
  }
  match shape {
    Standard(pair~, groups~, wait~) =>
      append_standard_yaku(
        result, input, shape, counts, pair, groups, wait, closed,
      )
    SevenPairs(_) => result.push(yaku_value(Chiitoitsu, 2))
    ThirteenOrphans(_) => ()
  }
  if all_tiles_match(counts, is_terminal_or_honor) {
    result.push(yaku_value(Honroutou, 2))
  }
  append_flush_yaku(result, counts, closed)
  result
}

///|
/// Detect yaku for one interpretation returned by `decompose`.
///
/// If one or more yakuman match, only yakuman are returned. Dora are evaluated
/// separately and are not included in this result.
fn detect_yaku(
  input : HandInput,
  shape : HandShape,
  rules : RuleSet,
) -> Array[YakuValue] raise ScoreError {
  let shapes = decompose(input)
  if !shapes.contains(shape) {
    raise InvalidHandShape
  }
  let counts = hand_tile_counts(input)
  let yakuman = detect_yakuman(input, shape, counts, rules)
  if !yakuman.is_empty() {
    yakuman
  } else {
    detect_regular_yaku(input, shape, counts, rules)
  }
}
