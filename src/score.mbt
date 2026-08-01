///|
fn yaku_han_total(yaku : Array[YakuValue]) -> Int {
  yaku.fold(init=0, (total, value) => total + value.han)
}

///|
fn yakuman_multiplier_total(yaku : Array[YakuValue]) -> Int {
  yaku.fold(init=0, (total, value) => total + value.yakuman_multiplier)
}

///|
fn bonus_han_total(bonus : BonusHan) -> Int {
  bonus.dora + bonus.ura_dora + bonus.aka_dora
}

///|
fn no_bonus_han() -> BonusHan {
  { dora: 0, ura_dora: 0, aka_dora: 0 }
}

///|
fn score_result_from_points(
  shape : HandShape,
  yaku : Array[YakuValue],
  bonus_han : BonusHan,
  fu_items : Array[FuItem],
  points : PointResult,
) -> ScoreResult {
  {
    shape,
    yaku,
    bonus_han,
    han: points.han,
    fu: points.fu,
    fu_items,
    limit: points.limit,
    base_points: points.base_points,
    payment: points.payment,
    riichi_bonus: points.riichi_bonus,
    winner_gain: points.winner_gain,
  }
}

///|
fn score_shape(
  input : HandInput,
  shape : HandShape,
  bonus : BonusHan,
  rules : RuleSet,
) -> ScoreResult? raise ScoreError {
  let yaku = detect_yaku(input, shape, rules)
  if yaku.is_empty() {
    return None
  }
  let dealer = input.context.seat_wind is East
  let yakuman_multiplier = yakuman_multiplier_total(yaku)
  if yakuman_multiplier > 0 {
    let points = calculate_yakuman_points(
      yakuman_multiplier,
      dealer,
      input.context.win_method,
      input.context.honba,
      input.context.riichi_sticks,
    )
    return Some(
      score_result_from_points(shape, yaku, no_bonus_han(), [], points),
    )
  }
  let han = yaku_han_total(yaku) + bonus_han_total(bonus)
  let (fu, fu_items) = calculate_fu(input, shape, yaku, rules)
  let points = calculate_valid_points(
    han,
    fu,
    dealer,
    input.context.win_method,
    input.context.honba,
    input.context.riichi_sticks,
    rules.kiriage_mangan,
    rules.counted_yakuman,
  )
  Some(score_result_from_points(shape, yaku, bonus, fu_items, points))
}

///|
fn is_better_score(candidate : ScoreResult, current : ScoreResult) -> Bool {
  if candidate.winner_gain != current.winner_gain {
    candidate.winner_gain > current.winner_gain
  } else if candidate.han != current.han {
    candidate.han > current.han
  } else {
    candidate.fu > current.fu
  }
}

///|
/// Validate and score a winning hand, selecting the highest-paying structural
/// interpretation. Ties are resolved by han, then fu, then the deterministic
/// order produced by `decompose`.
pub fn score(
  input : HandInput,
  rules : RuleSet,
) -> ScoreResult raise ScoreError {
  validate_rules(rules)
  let shapes = decompose(input)
  let bonus = calculate_bonus_han(input)
  let mut best : ScoreResult? = None
  for shape in shapes {
    if score_shape(input, shape, bonus, rules) is Some(candidate) {
      match best {
        None => best = Some(candidate)
        Some(current) =>
          if is_better_score(candidate, current) {
            best = Some(candidate)
          }
      }
    }
  }
  match best {
    Some(result) => result
    None => raise NoYaku
  }
}

///|
/// Score a hand using `RuleSet::standard()`.
pub fn score_standard(input : HandInput) -> ScoreResult raise ScoreError {
  score(input, RuleSet::standard())
}
