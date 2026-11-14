///|
fn fu_item(reason : FuReason, fu : Int32) -> FuItem {
  { reason, fu, }
}

///|
fn round_fu(raw_fu : Int32) -> Int32 {
  (raw_fu + 9) / 10 * 10
}

///|
fn has_yaku(yaku : Array[YakuValue], wanted : Yaku) -> Bool {
  yaku.any(value => value.yaku == wanted)
}

///|
fn pair_fu(pair : TileKind, context : WinContext, rules : RuleSet) -> Int32 {
  let index = tile_kind_index_unchecked(pair)
  if index >= 31 {
    2
  } else if index >= 27 {
    let seat_value = index == wind_index(context.seat_wind)
    let round_value = index == wind_index(context.round_wind)
    if seat_value && round_value {
      rules.double_wind_pair_fu
    } else if seat_value || round_value {
      2
    } else {
      0
    }
  } else {
    0
  }
}

///|
fn wait_fu(wait : WaitKind) -> Int32 {
  match wait {
    Kanchan | Penchan | Tanki => 2
    Ryanmen | Shanpon | KokushiSingle | KokushiThirteenSided => 0
  }
}

///|
/// `completed_by_ron` marks the triplet found by `ron_completed_triplet`.
fn group_fu(group : Group, completed_by_ron : Bool) -> FuItem? {
  match group {
    Sequence(_, ..) => None
    Triplet(kind, is_open~) => {
      let terminal_or_honor = is_terminal_or_honor(
        tile_kind_index_unchecked(kind),
      )
      let effectively_open = is_open || completed_by_ron
      let base = if effectively_open { 2 } else { 4 }
      let fu = if terminal_or_honor { base * 2 } else { base }
      Some(
        fu_item(if effectively_open { OpenTriplet } else { ClosedTriplet }, fu),
      )
    }
    Quad(kind, is_open~) => {
      let terminal_or_honor = is_terminal_or_honor(
        tile_kind_index_unchecked(kind),
      )
      let base = if is_open { 8 } else { 16 }
      let fu = if terminal_or_honor { base * 2 } else { base }
      Some(fu_item(if is_open { OpenQuad } else { ClosedQuad }, fu))
    }
  }
}

///|
fn calculate_standard_fu(
  input : HandInput,
  pair : TileKind,
  groups : Array[Group],
  wait : WaitKind,
  yaku : Array[YakuValue],
  rules : RuleSet,
) -> (Int32, Array[FuItem]) {
  if input.context.win_method is Tsumo && has_yaku(yaku, Pinfu) {
    return (20, [fu_item(Base, 20)])
  }
  let items : Array[FuItem] = [fu_item(Base, 20)]
  let mut raw_fu = 20
  let closed = groups.all(group => !group_is_open(group))
  if closed && input.context.win_method is Ron {
    items.push(fu_item(MenzenRon, 10))
    raw_fu += 10
  }
  if input.context.win_method is Tsumo {
    items.push(fu_item(Tsumo, 2))
    raw_fu += 2
  }
  let pair_value = pair_fu(pair, input.context, rules)
  if pair_value > 0 {
    items.push(fu_item(ValuePair, pair_value))
    raw_fu += pair_value
  }
  let wait_value = wait_fu(wait)
  if wait_value > 0 {
    items.push(fu_item(Wait, wait_value))
    raw_fu += wait_value
  }
  let ron_completed = ron_completed_triplet(input, groups, wait)
  for index, group in groups {
    if group_fu(group, ron_completed == Some(index)) is Some(item) {
      items.push(item)
      raw_fu += item.fu
    }
  }
  if raw_fu == 20 {
    items.push(fu_item(OpenPinfuShape, 10))
    raw_fu += 10
  }
  (round_fu(raw_fu), items)
}

///|
/// Calculate fu and its explanation for one interpretation of a validated
/// hand. `shape` must come from `decompose` and `yaku` from `detect_yaku` for
/// the same input, and `rules` must already be validated.
///
/// Seven pairs are fixed at 25 fu. Thirteen orphans have no applicable fu and
/// return zero with an empty explanation.
fn calculate_fu(
  input : HandInput,
  shape : HandShape,
  yaku : Array[YakuValue],
  rules : RuleSet,
) -> (Int32, Array[FuItem]) {
  match shape {
    Standard(pair~, groups~, wait~) =>
      calculate_standard_fu(input, pair, groups, wait, yaku, rules)
    SevenPairs(_) => (25, [fu_item(SevenPairsFixed, 25)])
    ThirteenOrphans(_) => (0, [])
  }
}
