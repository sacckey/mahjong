///|
/// Errors from the standalone point and payment calculation.
#derive(Debug, Eq)
pub(all) suberror PointCalculationError {
  InvalidHan(Int32)
  InvalidFu(Int32)
  InvalidHonba(Int32)
  InvalidRiichiSticks(Int32)
}

///|
fn round_up_100(value : Int32) -> Int32 {
  (value + 99) / 100 * 100
}

///|
fn raw_base_points(han : Int32, fu : Int32) -> Int32 {
  fu * (1 << (han + 2))
}

///|
fn base_points_and_limit(
  han : Int32,
  fu : Int32,
  kiriage_mangan : Bool,
  counted_yakuman : Bool,
) -> (Int32, Limit) {
  if han >= 13 {
    if counted_yakuman {
      (8000, Yakuman(1))
    } else {
      (6000, Sanbaiman)
    }
  } else if han >= 11 {
    (6000, Sanbaiman)
  } else if han >= 8 {
    (4000, Baiman)
  } else if han >= 6 {
    (3000, Haneman)
  } else if han >= 5 {
    (2000, Mangan)
  } else {
    let base = raw_base_points(han, fu)
    if base >= 2000 ||
      (kiriage_mangan && ((han == 4 && fu == 30) || (han == 3 && fu == 60))) {
      (2000, Mangan)
    } else {
      (base, BelowMangan)
    }
  }
}

///|
fn valid_fu(fu : Int32) -> Bool {
  fu == 20 || fu == 25 || (fu >= 30 && fu % 10 == 0)
}

///|
fn payment_total(payment : WinPayment) -> Int32 {
  match payment {
    RonPayment(discarder~) => discarder
    DealerTsumoPayment(each~) => each * 3
    NonDealerTsumoPayment(dealer~, non_dealer_each~) =>
      dealer + non_dealer_each * 2
  }
}

///|
fn point_result_from_base(
  han : Int32,
  fu : Int32,
  base_points : Int32,
  limit : Limit,
  dealer : Bool,
  win_method : WinMethod,
  honba : Int32,
  riichi_sticks : Int32,
) -> PointResult {
  let payment = match (dealer, win_method) {
    (true, Ron) =>
      RonPayment(discarder=round_up_100(base_points * 6) + honba * 300)
    (false, Ron) =>
      RonPayment(discarder=round_up_100(base_points * 4) + honba * 300)
    (true, Tsumo) =>
      DealerTsumoPayment(each=round_up_100(base_points * 2) + honba * 100)
    (false, Tsumo) =>
      NonDealerTsumoPayment(
        dealer=round_up_100(base_points * 2) + honba * 100,
        non_dealer_each=round_up_100(base_points) + honba * 100,
      )
  }
  let riichi_bonus = riichi_sticks * 1000
  {
    han,
    fu,
    limit,
    base_points,
    payment,
    riichi_bonus,
    winner_gain: payment_total(payment) + riichi_bonus,
  }
}

///|
fn calculate_valid_points(
  han : Int32,
  fu : Int32,
  dealer : Bool,
  win_method : WinMethod,
  honba : Int32,
  riichi_sticks : Int32,
  kiriage_mangan : Bool,
  counted_yakuman : Bool,
) -> PointResult {
  let (base_points, limit) = base_points_and_limit(
    han, fu, kiriage_mangan, counted_yakuman,
  )
  point_result_from_base(
    han, fu, base_points, limit, dealer, win_method, honba, riichi_sticks,
  )
}

///|
fn calculate_yakuman_points(
  multiplier : Int32,
  dealer : Bool,
  win_method : WinMethod,
  honba : Int32,
  riichi_sticks : Int32,
) -> PointResult {
  point_result_from_base(
    0,
    0,
    8000 * multiplier,
    Yakuman(multiplier),
    dealer,
    win_method,
    honba,
    riichi_sticks,
  )
}

///|
/// Calculate standard capped riichi-mahjong payments from already determined
/// han and fu. This function does not decide whether the hand has a yaku. When
/// `counted_yakuman` is false, hands with at least 13 han are capped at
/// sanbaiman.
pub fn calculate_points(
  han : Int32,
  fu : Int32,
  dealer~ : Bool,
  win_method~ : WinMethod,
  honba~ : Int32 = 0,
  riichi_sticks~ : Int32 = 0,
  kiriage_mangan~ : Bool = false,
  counted_yakuman~ : Bool = true,
) -> PointResult raise PointCalculationError {
  if han < 1 {
    raise InvalidHan(han)
  }
  if !valid_fu(fu) {
    raise InvalidFu(fu)
  }
  if honba < 0 {
    raise InvalidHonba(honba)
  }
  if riichi_sticks < 0 {
    raise InvalidRiichiSticks(riichi_sticks)
  }
  calculate_valid_points(
    han, fu, dealer, win_method, honba, riichi_sticks, kiriage_mangan, counted_yakuman,
  )
}
