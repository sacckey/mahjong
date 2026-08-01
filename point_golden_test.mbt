///|
struct RonGoldenCase {
  name : String
  han : Int
  fu : Int
  dealer : Bool
  expected_base : Int
  expected_limit : @mahjong.Limit
  expected_payment : Int
}

///|
test "golden ron point table" {
  let cases : Array[RonGoldenCase] = [
    {
      name: "child 1 han 30 fu",
      han: 1,
      fu: 30,
      dealer: false,
      expected_base: 240,
      expected_limit: BelowMangan,
      expected_payment: 1000,
    },
    {
      name: "dealer 1 han 30 fu",
      han: 1,
      fu: 30,
      dealer: true,
      expected_base: 240,
      expected_limit: BelowMangan,
      expected_payment: 1500,
    },
    {
      name: "child seven pairs 2 han 25 fu",
      han: 2,
      fu: 25,
      dealer: false,
      expected_base: 400,
      expected_limit: BelowMangan,
      expected_payment: 1600,
    },
    {
      name: "child 3 han 40 fu",
      han: 3,
      fu: 40,
      dealer: false,
      expected_base: 1280,
      expected_limit: BelowMangan,
      expected_payment: 5200,
    },
    {
      name: "dealer 3 han 40 fu",
      han: 3,
      fu: 40,
      dealer: true,
      expected_base: 1280,
      expected_limit: BelowMangan,
      expected_payment: 7700,
    },
    {
      name: "child 4 han 30 fu without kiriage",
      han: 4,
      fu: 30,
      dealer: false,
      expected_base: 1920,
      expected_limit: BelowMangan,
      expected_payment: 7700,
    },
    {
      name: "child 3 han 60 fu without kiriage",
      han: 3,
      fu: 60,
      dealer: false,
      expected_base: 1920,
      expected_limit: BelowMangan,
      expected_payment: 7700,
    },
    {
      name: "child 4 han 40 fu mangan",
      han: 4,
      fu: 40,
      dealer: false,
      expected_base: 2000,
      expected_limit: Mangan,
      expected_payment: 8000,
    },
    {
      name: "child 3 han 70 fu mangan",
      han: 3,
      fu: 70,
      dealer: false,
      expected_base: 2000,
      expected_limit: Mangan,
      expected_payment: 8000,
    },
    {
      name: "child 6 han haneman",
      han: 6,
      fu: 30,
      dealer: false,
      expected_base: 3000,
      expected_limit: Haneman,
      expected_payment: 12000,
    },
    {
      name: "child 8 han baiman",
      han: 8,
      fu: 30,
      dealer: false,
      expected_base: 4000,
      expected_limit: Baiman,
      expected_payment: 16000,
    },
    {
      name: "child 11 han sanbaiman",
      han: 11,
      fu: 30,
      dealer: false,
      expected_base: 6000,
      expected_limit: Sanbaiman,
      expected_payment: 24000,
    },
    {
      name: "child 13 han counted yakuman",
      han: 13,
      fu: 30,
      dealer: false,
      expected_base: 8000,
      expected_limit: Yakuman(1),
      expected_payment: 32000,
    },
  ]
  for case in cases {
    let result = @mahjong.calculate_points(
      case.han,
      case.fu,
      dealer=case.dealer,
      win_method=Ron,
    )
    assert_eq(result.base_points, case.expected_base, msg=case.name)
    assert_eq(result.limit, case.expected_limit, msg=case.name)
    assert_eq(
      result.payment,
      RonPayment(discarder=case.expected_payment),
      msg=case.name,
    )
    assert_eq(result.winner_gain, case.expected_payment, msg=case.name)
  }
}

///|
test "golden tsumo payments" {
  let child = @mahjong.calculate_points(1, 30, dealer=false, win_method=Tsumo)
  assert_eq(
    child.payment,
    NonDealerTsumoPayment(dealer=500, non_dealer_each=300),
  )
  assert_eq(child.winner_gain, 1100)
  let dealer = @mahjong.calculate_points(1, 30, dealer=true, win_method=Tsumo)
  assert_eq(dealer.payment, DealerTsumoPayment(each=500))
  assert_eq(dealer.winner_gain, 1500)
  let pinfu = @mahjong.calculate_points(2, 20, dealer=false, win_method=Tsumo)
  assert_eq(
    pinfu.payment,
    NonDealerTsumoPayment(dealer=700, non_dealer_each=400),
  )
  assert_eq(pinfu.winner_gain, 1500)
  let mangan = @mahjong.calculate_points(5, 30, dealer=false, win_method=Tsumo)
  assert_eq(
    mangan.payment,
    NonDealerTsumoPayment(dealer=4000, non_dealer_each=2000),
  )
  assert_eq(mangan.winner_gain, 8000)
}

///|
test "kiriage mangan is opt in" {
  let ordinary = @mahjong.calculate_points(4, 30, dealer=false, win_method=Ron)
  assert_eq(ordinary.limit, BelowMangan)
  assert_eq(ordinary.payment, RonPayment(discarder=7700))
  let kiriage = @mahjong.calculate_points(
    4,
    30,
    dealer=false,
    win_method=Ron,
    kiriage_mangan=true,
  )
  assert_eq(kiriage.limit, Mangan)
  assert_eq(kiriage.payment, RonPayment(discarder=8000))
  let three_han = @mahjong.calculate_points(
    3,
    60,
    dealer=false,
    win_method=Ron,
    kiriage_mangan=true,
  )
  assert_eq(three_han.limit, Mangan)
  assert_eq(three_han.payment, RonPayment(discarder=8000))
}

///|
test "counted yakuman can be capped at sanbaiman" {
  let counted = @mahjong.calculate_points(13, 30, dealer=false, win_method=Ron)
  assert_eq(counted.limit, Yakuman(1))
  assert_eq(counted.payment, RonPayment(discarder=32000))
  let capped = @mahjong.calculate_points(
    13,
    30,
    dealer=false,
    win_method=Ron,
    counted_yakuman=false,
  )
  assert_eq(capped.han, 13)
  assert_eq(capped.limit, Sanbaiman)
  assert_eq(capped.payment, RonPayment(discarder=24000))
}

///|
test "honba and riichi sticks affect the correct amounts" {
  let ron = @mahjong.calculate_points(
    1,
    30,
    dealer=false,
    win_method=Ron,
    honba=2,
    riichi_sticks=3,
  )
  assert_eq(ron.payment, RonPayment(discarder=1600))
  assert_eq(ron.riichi_bonus, 3000)
  assert_eq(ron.winner_gain, 4600)
  let tsumo = @mahjong.calculate_points(
    1,
    30,
    dealer=false,
    win_method=Tsumo,
    honba=1,
  )
  assert_eq(
    tsumo.payment,
    NonDealerTsumoPayment(dealer=600, non_dealer_each=400),
  )
  assert_eq(tsumo.winner_gain, 1400)
}

///|
test "standard rules are explicit" {
  let rules = @mahjong.RuleSet::standard()
  assert_true(rules.open_tanyao)
  assert_false(rules.kiriage_mangan)
  assert_true(rules.double_yakuman)
  assert_true(rules.counted_yakuman)
  assert_eq(rules.double_wind_pair_fu, 4)
}

///|
test "invalid point inputs are rejected" {
  try @mahjong.calculate_points(0, 30, dealer=false, win_method=Ron) catch {
    InvalidHan(han) => assert_eq(han, 0)
    _ => fail("expected InvalidHan")
  } noraise {
    _ => fail("expected point calculation to fail")
  }
  try @mahjong.calculate_points(1, 27, dealer=false, win_method=Ron) catch {
    InvalidFu(fu) => assert_eq(fu, 27)
    _ => fail("expected InvalidFu")
  } noraise {
    _ => fail("expected point calculation to fail")
  }
  try
    @mahjong.calculate_points(1, 30, dealer=false, win_method=Ron, honba=-1)
  catch {
    InvalidHonba(honba) => assert_eq(honba, -1)
    _ => fail("expected InvalidHonba")
  } noraise {
    _ => fail("expected point calculation to fail")
  }
  try
    @mahjong.calculate_points(
      1,
      30,
      dealer=false,
      win_method=Ron,
      riichi_sticks=-1,
    )
  catch {
    InvalidRiichiSticks(sticks) => assert_eq(sticks, -1)
    _ => fail("expected InvalidRiichiSticks")
  } noraise {
    _ => fail("expected point calculation to fail")
  }
}
