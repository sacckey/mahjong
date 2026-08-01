///|
fn ft_m(rank : Int) -> Tile {
  try! Tile::numbered(Man, rank)
}

///|
fn ft_p(rank : Int) -> Tile {
  try! Tile::numbered(Pin, rank)
}

///|
fn ft_s(rank : Int) -> Tile {
  try! Tile::numbered(Sou, rank)
}

///|
fn ft_h(honor : Honor) -> Tile {
  Tile::honor(honor)
}

///|
fn ft_context(
  win_method : WinMethod,
  seat? : Wind = South,
  round? : Wind = East,
) -> WinContext {
  {
    win_method,
    seat_wind: seat,
    round_wind: round,
    riichi: NoRiichi,
    ippatsu: false,
    rinshan: false,
    chankan: false,
    haitei: false,
    houtei: false,
    tenhou: false,
    chiihou: false,
    honba: 0,
    riichi_sticks: 0,
  }
}

///|
fn ft_input(
  concealed : Array[Tile],
  winning : Tile,
  melds? : Array[Meld] = [],
  context? : WinContext = ft_context(Ron),
) -> HandInput {
  {
    concealed_tiles: concealed,
    winning_tile: winning,
    melds,
    dora_indicators: [],
    ura_dora_indicators: [],
    context,
  }
}

///|
fn ft_meld(kind : MeldKind, tiles : Array[Tile]) -> Meld {
  { kind, tiles }
}

///|
fn ft_shape_with_wait(hand : HandInput, wanted : WaitKind) -> HandShape {
  let shapes = try! decompose(hand)
  for shape in shapes {
    match shape {
      Standard(wait~, ..) if wait == wanted => return shape
      _ => ()
    }
  }
  abort("expected a standard shape with the requested wait")
}

///|
fn ft_seven_pairs_shape(hand : HandInput) -> HandShape {
  let shapes = try! decompose(hand)
  for shape in shapes {
    if shape is SevenPairs(_) {
      return shape
    }
  }
  abort("expected a seven-pairs shape")
}

///|
fn ft_orphans_shape(hand : HandInput) -> HandShape {
  let shapes = try! decompose(hand)
  for shape in shapes {
    if shape is ThirteenOrphans(_) {
      return shape
    }
  }
  abort("expected a thirteen-orphans shape")
}

///|
fn ft_calculate(
  hand : HandInput,
  shape : HandShape,
  rules? : RuleSet = RuleSet::standard(),
) -> (Int, Array[FuItem]) {
  let yaku = try! detect_yaku(hand, shape, rules)
  try! calculate_fu(hand, shape, yaku, rules)
}

///|
fn ft_pinfu_hand(win_method : WinMethod) -> HandInput {
  ft_input(
    [
      ft_m(1),
      ft_m(2),
      ft_m(3),
      ft_m(4),
      ft_m(5),
      ft_m(6),
      ft_p(1),
      ft_p(2),
      ft_p(3),
      ft_s(7),
      ft_s(8),
      ft_p(5),
      ft_p(5),
    ],
    ft_s(9),
    context=ft_context(win_method),
  )
}

///|
test "pinfu tsumo is fixed at 20 fu and pinfu ron is 30 fu" {
  let tsumo = ft_pinfu_hand(Tsumo)
  let tsumo_shape = ft_shape_with_wait(tsumo, Ryanmen)
  assert_eq(ft_calculate(tsumo, tsumo_shape), (20, [{ reason: Base, fu: 20 }]))
  let ron = ft_pinfu_hand(Ron)
  let ron_shape = ft_shape_with_wait(ron, Ryanmen)
  assert_eq(
    ft_calculate(ron, ron_shape),
    (30, [{ reason: Base, fu: 20 }, { reason: MenzenRon, fu: 10 }]),
  )
}

///|
test "seven pairs is fixed at 25 fu and thirteen orphans has no fu" {
  let seven_pairs = ft_input(
    [
      ft_m(1),
      ft_m(1),
      ft_m(2),
      ft_m(2),
      ft_p(3),
      ft_p(3),
      ft_p(4),
      ft_p(4),
      ft_s(5),
      ft_s(5),
      ft_s(6),
      ft_s(6),
      ft_h(East),
    ],
    ft_h(East),
  )
  let seven_shape = ft_seven_pairs_shape(seven_pairs)
  assert_eq(
    ft_calculate(seven_pairs, seven_shape),
    (25, [{ reason: SevenPairsFixed, fu: 25 }]),
  )
  let orphans = ft_input(
    [
      ft_m(1),
      ft_m(9),
      ft_p(1),
      ft_p(9),
      ft_s(1),
      ft_s(9),
      ft_h(East),
      ft_h(South),
      ft_h(West),
      ft_h(North),
      ft_h(White),
      ft_h(Green),
      ft_h(Red),
    ],
    ft_m(1),
  )
  let orphan_shape = ft_orphans_shape(orphans)
  assert_eq(ft_calculate(orphans, orphan_shape), (0, []))
}

///|
test "open pinfu-shaped ron receives the 30-fu minimum" {
  let hand = ft_input(
    [
      ft_m(3),
      ft_m(4),
      ft_m(5),
      ft_p(4),
      ft_p(5),
      ft_s(7),
      ft_s(8),
      ft_s(9),
      ft_p(5),
      ft_p(5),
    ],
    ft_p(6),
    melds=[ft_meld(Chi, [ft_m(1), ft_m(2), ft_m(3)])],
  )
  let shape = ft_shape_with_wait(hand, Ryanmen)
  assert_eq(
    ft_calculate(hand, shape),
    (30, [{ reason: Base, fu: 20 }, { reason: OpenPinfuShape, fu: 10 }]),
  )
}

///|
test "value pair and tanki wait fu are itemized before rounding" {
  let hand = ft_input(
    [
      ft_m(1),
      ft_m(2),
      ft_m(3),
      ft_m(4),
      ft_m(5),
      ft_m(6),
      ft_p(7),
      ft_p(8),
      ft_p(9),
      ft_h(White),
      ft_h(White),
      ft_h(White),
      ft_h(East),
    ],
    ft_h(East),
    context=ft_context(Ron, seat=East, round=East),
  )
  let shape = ft_shape_with_wait(hand, Tanki)
  assert_eq(
    ft_calculate(hand, shape),
    (
      50,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: ValuePair, fu: 4 },
        { reason: Wait, fu: 2 },
        { reason: ClosedTriplet, fu: 8 },
      ],
    ),
  )
  let two_fu_double_wind : RuleSet = {
    ..RuleSet::standard(),
    double_wind_pair_fu: 2,
  }
  assert_eq(
    ft_calculate(hand, shape, rules=two_fu_double_wind),
    (
      50,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: ValuePair, fu: 2 },
        { reason: Wait, fu: 2 },
        { reason: ClosedTriplet, fu: 8 },
      ],
    ),
  )
  let dragon_pair = ft_input(
    [
      ft_m(1),
      ft_m(2),
      ft_m(3),
      ft_m(4),
      ft_m(5),
      ft_m(6),
      ft_p(7),
      ft_p(8),
      ft_p(9),
      ft_h(East),
      ft_h(East),
      ft_h(East),
      ft_h(White),
    ],
    ft_h(White),
  )
  let dragon_shape = ft_shape_with_wait(dragon_pair, Tanki)
  assert_eq(
    ft_calculate(dragon_pair, dragon_shape),
    (
      50,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: ValuePair, fu: 2 },
        { reason: Wait, fu: 2 },
        { reason: ClosedTriplet, fu: 8 },
      ],
    ),
  )
}

///|
test "triplet and quad fu distinguish open, closed, simple, and outside groups" {
  let hand = ft_input([ft_p(5), ft_p(5), ft_p(5), ft_h(East)], ft_h(East), melds=[
    ft_meld(Pon, [ft_m(2), ft_m(2), ft_m(2)]),
    ft_meld(OpenKan, [ft_p(1), ft_p(1), ft_p(1), ft_p(1)]),
    ft_meld(ClosedKan, [ft_s(9), ft_s(9), ft_s(9), ft_s(9)]),
  ])
  let shape = ft_shape_with_wait(hand, Tanki)
  assert_eq(
    ft_calculate(hand, shape),
    (
      80,
      [
        { reason: Base, fu: 20 },
        { reason: ValuePair, fu: 2 },
        { reason: Wait, fu: 2 },
        { reason: OpenTriplet, fu: 2 },
        { reason: OpenQuad, fu: 16 },
        { reason: ClosedTriplet, fu: 4 },
        { reason: ClosedQuad, fu: 32 },
      ],
    ),
  )
}

///|
fn ft_shanpon_hand(win_method : WinMethod) -> HandInput {
  ft_input(
    [
      ft_m(1),
      ft_m(1),
      ft_m(1),
      ft_m(2),
      ft_m(2),
      ft_m(2),
      ft_p(3),
      ft_p(3),
      ft_s(4),
      ft_s(5),
      ft_s(6),
      ft_h(East),
      ft_h(East),
    ],
    ft_p(3),
    context=ft_context(win_method, seat=West, round=South),
  )
}

///|
test "a triplet completed by ron is open for fu but stays closed on tsumo" {
  let ron = ft_shanpon_hand(Ron)
  let ron_shape = ft_shape_with_wait(ron, Shanpon)
  assert_eq(
    ft_calculate(ron, ron_shape),
    (
      50,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: ClosedTriplet, fu: 8 },
        { reason: ClosedTriplet, fu: 4 },
        { reason: OpenTriplet, fu: 2 },
      ],
    ),
  )
  let tsumo = ft_shanpon_hand(Tsumo)
  let tsumo_shape = ft_shape_with_wait(tsumo, Shanpon)
  assert_eq(
    ft_calculate(tsumo, tsumo_shape),
    (
      40,
      [
        { reason: Base, fu: 20 },
        { reason: Tsumo, fu: 2 },
        { reason: ClosedTriplet, fu: 8 },
        { reason: ClosedTriplet, fu: 4 },
        { reason: ClosedTriplet, fu: 4 },
      ],
    ),
  )
}

///|
test "kanchan and penchan waits each add two fu" {
  let kanchan = ft_input(
    [
      ft_m(3),
      ft_m(5),
      ft_p(1),
      ft_p(2),
      ft_p(3),
      ft_s(1),
      ft_s(2),
      ft_s(3),
      ft_s(7),
      ft_s(8),
      ft_s(9),
      ft_h(East),
      ft_h(East),
    ],
    ft_m(4),
    context=ft_context(Ron, seat=West, round=South),
  )
  let kanchan_shape = ft_shape_with_wait(kanchan, Kanchan)
  assert_eq(
    ft_calculate(kanchan, kanchan_shape),
    (
      40,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: Wait, fu: 2 },
      ],
    ),
  )
  let penchan = ft_input(
    [
      ft_m(1),
      ft_m(2),
      ft_p(1),
      ft_p(2),
      ft_p(3),
      ft_s(1),
      ft_s(2),
      ft_s(3),
      ft_s(7),
      ft_s(8),
      ft_s(9),
      ft_h(East),
      ft_h(East),
    ],
    ft_m(3),
    context=ft_context(Ron, seat=West, round=South),
  )
  let penchan_shape = ft_shape_with_wait(penchan, Penchan)
  assert_eq(
    ft_calculate(penchan, penchan_shape),
    (
      40,
      [
        { reason: Base, fu: 20 },
        { reason: MenzenRon, fu: 10 },
        { reason: Wait, fu: 2 },
      ],
    ),
  )
}

///|
test "calculate_fu rejects invalid shapes and rule settings" {
  let hand = ft_pinfu_hand(Ron)
  let shape = ft_shape_with_wait(hand, Ryanmen)
  let yaku = try! detect_yaku(hand, shape, RuleSet::standard())
  let invalid_rules : RuleSet = {
    ..RuleSet::standard(),
    double_wind_pair_fu: 3,
  }
  try calculate_fu(hand, shape, yaku, invalid_rules) catch {
    InvalidRule(_) => ()
    _ => fail("expected InvalidRule")
  } noraise {
    _ => fail("expected calculate_fu to raise")
  }
  let fake : HandShape = SevenPairs([
    Numbered(Man, 1),
    Numbered(Man, 2),
    Numbered(Man, 3),
    Numbered(Man, 4),
    Numbered(Man, 5),
    Numbered(Man, 6),
    Numbered(Man, 7),
  ])
  try calculate_fu(hand, fake, [], RuleSet::standard()) catch {
    InvalidHandShape => ()
    _ => fail("expected InvalidHandShape")
  } noraise {
    _ => fail("expected calculate_fu to raise")
  }
}
