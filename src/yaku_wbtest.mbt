///|
fn yt_m(rank : Int) -> Tile {
  try! Tile::numbered(Man, rank)
}

///|
fn yt_p(rank : Int) -> Tile {
  try! Tile::numbered(Pin, rank)
}

///|
fn yt_s(rank : Int) -> Tile {
  try! Tile::numbered(Sou, rank)
}

///|
fn yt_h(honor : Honor) -> Tile {
  Tile::honor(honor)
}

///|
fn yt_context(
  win_method : WinMethod,
  seat? : Wind = South,
  round? : Wind = East,
  riichi? : RiichiState = NoRiichi,
  ippatsu? : Bool = false,
  rinshan? : Bool = false,
  chankan? : Bool = false,
  haitei? : Bool = false,
  houtei? : Bool = false,
  tenhou? : Bool = false,
  chiihou? : Bool = false,
) -> WinContext {
  {
    win_method,
    seat_wind: seat,
    round_wind: round,
    riichi,
    ippatsu,
    rinshan,
    chankan,
    haitei,
    houtei,
    tenhou,
    chiihou,
    honba: 0,
    riichi_sticks: 0,
  }
}

///|
fn yt_input(
  concealed : Array[Tile],
  winning : Tile,
  melds? : Array[Meld] = [],
  context? : WinContext = yt_context(Ron),
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
fn yt_meld(kind : MeldKind, tiles : Array[Tile]) -> Meld {
  { kind, tiles }
}

///|
fn yt_values(
  hand : HandInput,
  rules? : RuleSet = RuleSet::standard(),
) -> Array[YakuValue] {
  let values : Array[YakuValue] = []
  let shapes = try! decompose(hand)
  for shape in shapes {
    let shape_values = try! detect_yaku(hand, shape, rules)
    for value in shape_values {
      values.push(value)
    }
  }
  values
}

///|
fn yt_has(
  hand : HandInput,
  yaku : Yaku,
  rules? : RuleSet = RuleSet::standard(),
) -> Bool {
  yt_values(hand, rules~).any(value => value.yaku == yaku)
}

///|
fn yt_max_han(hand : HandInput, yaku : Yaku) -> Int {
  let mut maximum = 0
  for value in yt_values(hand) {
    if value.yaku == yaku && value.han > maximum {
      maximum = value.han
    }
  }
  maximum
}

///|
fn yt_max_yakuman(
  hand : HandInput,
  yaku : Yaku,
  rules? : RuleSet = RuleSet::standard(),
) -> Int {
  let mut maximum = 0
  for value in yt_values(hand, rules~) {
    if value.yaku == yaku && value.yakuman_multiplier > maximum {
      maximum = value.yakuman_multiplier
    }
  }
  maximum
}

///|
fn yt_basic_hand(context : WinContext) -> HandInput {
  yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_s(7),
      yt_s(8),
      yt_s(9),
      yt_p(5),
      yt_p(5),
    ],
    yt_m(6),
    context~,
  )
}

///|
test "detect situational yaku and keep them mutually exclusive" {
  let riichi_tsumo = yt_basic_hand(
    yt_context(Tsumo, riichi=Riichi, ippatsu=true),
  )
  assert_true(yt_has(riichi_tsumo, Riichi))
  assert_true(yt_has(riichi_tsumo, Ippatsu))
  assert_true(yt_has(riichi_tsumo, MenzenTsumo))
  assert_true(yt_has(riichi_tsumo, Pinfu))
  assert_false(yt_has(riichi_tsumo, DoubleRiichi))
  let double_riichi = yt_basic_hand(yt_context(Ron, riichi=DoubleRiichi))
  assert_eq(yt_max_han(double_riichi, DoubleRiichi), 2)
  assert_false(yt_has(double_riichi, Riichi))
  assert_true(
    yt_has(yt_basic_hand(yt_context(Tsumo, rinshan=true)), RinshanKaihou),
  )
  assert_true(yt_has(yt_basic_hand(yt_context(Ron, chankan=true)), Chankan))
  assert_true(
    yt_has(yt_basic_hand(yt_context(Tsumo, haitei=true)), HaiteiRaoyue),
  )
  assert_true(yt_has(yt_basic_hand(yt_context(Ron, houtei=true)), HouteiRaoyui))
  let chiihou = yt_basic_hand(yt_context(Tsumo, chiihou=true))
  assert_true(yt_has(chiihou, Chiihou))
  assert_false(yt_has(chiihou, MenzenTsumo))
}

///|
test "detect closed sequence yaku and their exclusions" {
  let iipeikou = yt_input(
    [
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_p(4),
      yt_p(5),
      yt_p(6),
      yt_s(6),
      yt_s(7),
      yt_p(5),
      yt_p(5),
    ],
    yt_s(8),
  )
  assert_true(yt_has(iipeikou, Tanyao))
  assert_true(yt_has(iipeikou, Pinfu))
  assert_true(yt_has(iipeikou, Iipeikou))
  assert_false(yt_has(iipeikou, Ryanpeikou))
  let ryanpeikou = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_p(4),
      yt_p(5),
      yt_p(6),
      yt_p(4),
      yt_p(5),
      yt_p(6),
      yt_s(7),
    ],
    yt_s(7),
  )
  assert_true(yt_has(ryanpeikou, Ryanpeikou))
  assert_false(
    yt_values(ryanpeikou).any(value => value.yaku == Iipeikou && value.han == 1),
  )
  assert_true(yt_has(ryanpeikou, Chiitoitsu))
}

///|
test "detect yakuhai and shousangen independently" {
  let hand = yt_input(
    [
      yt_h(White),
      yt_h(White),
      yt_h(White),
      yt_h(Green),
      yt_h(Green),
      yt_h(Green),
      yt_h(Red),
      yt_h(East),
      yt_h(East),
      yt_h(East),
      yt_m(1),
      yt_m(2),
      yt_m(3),
    ],
    yt_h(Red),
    context=yt_context(Ron, seat=East, round=East),
  )
  assert_true(yt_has(hand, WhiteDragon))
  assert_true(yt_has(hand, GreenDragon))
  assert_true(yt_has(hand, SeatWind))
  assert_true(yt_has(hand, RoundWind))
  assert_true(yt_has(hand, Shousangen))
  let red_dragon = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_p(7),
      yt_p(8),
      yt_p(9),
      yt_h(Red),
      yt_h(Red),
      yt_h(Red),
      yt_h(West),
    ],
    yt_h(West),
  )
  assert_true(yt_has(red_dragon, RedDragon))
}

///|
test "detect sequence families and outside-hand exclusions" {
  let chanta = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_s(1),
      yt_s(2),
      yt_s(3),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_h(East),
    ],
    yt_h(East),
  )
  assert_true(yt_has(chanta, SanshokuDoujun))
  assert_true(yt_has(chanta, Chanta))
  assert_false(yt_has(chanta, Junchan))
  let junchan = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_s(1),
      yt_s(2),
      yt_s(3),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_p(9),
    ],
    yt_p(9),
  )
  assert_eq(yt_max_han(junchan, Junchan), 3)
  assert_false(yt_has(junchan, Chanta))
  let ittsu = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_h(West),
    ],
    yt_h(West),
  )
  assert_eq(yt_max_han(ittsu, Ittsu), 2)
}

///|
test "detect triplet, quad, and terminal yaku" {
  let open_pon = yt_meld(Pon, [yt_m(2), yt_m(2), yt_m(2)])
  let triplets = yt_input(
    [
      yt_p(2),
      yt_p(2),
      yt_p(2),
      yt_s(2),
      yt_s(2),
      yt_s(2),
      yt_h(White),
      yt_h(White),
      yt_h(White),
      yt_h(East),
    ],
    yt_h(East),
    melds=[open_pon],
  )
  assert_true(yt_has(triplets, Toitoi))
  assert_true(yt_has(triplets, Sanankou))
  assert_true(yt_has(triplets, SanshokuDoukou))
  let shanpon_ron = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_m(2),
      yt_m(2),
      yt_m(2),
      yt_p(3),
      yt_p(3),
      yt_s(4),
      yt_s(5),
      yt_s(6),
      yt_h(East),
      yt_h(East),
    ],
    yt_p(3),
  )
  assert_false(yt_has(shanpon_ron, Sanankou))
  let shanpon_tsumo : HandInput = { ..shanpon_ron, context: yt_context(Tsumo) }
  assert_true(yt_has(shanpon_tsumo, Sanankou))
  let kans = [
    yt_meld(OpenKan, [yt_m(1), yt_m(1), yt_m(1), yt_m(1)]),
    yt_meld(OpenKan, [yt_p(1), yt_p(1), yt_p(1), yt_p(1)]),
    yt_meld(ClosedKan, [yt_s(1), yt_s(1), yt_s(1), yt_s(1)]),
  ]
  let three_kans = yt_input(
    [yt_h(White), yt_h(White), yt_h(White), yt_h(East)],
    yt_h(East),
    melds=kans,
  )
  assert_true(yt_has(three_kans, Sankantsu))
  let seven_outside = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(9),
      yt_m(9),
      yt_p(1),
      yt_p(1),
      yt_p(9),
      yt_p(9),
      yt_s(1),
      yt_s(1),
      yt_s(9),
      yt_s(9),
      yt_h(East),
    ],
    yt_h(East),
  )
  assert_true(yt_has(seven_outside, Chiitoitsu))
  assert_true(yt_has(seven_outside, Honroutou))
}

///|
test "apply flush and open tanyao rules" {
  let honitsu = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_h(White),
      yt_h(White),
      yt_h(White),
      yt_h(East),
    ],
    yt_h(East),
  )
  assert_eq(yt_max_han(honitsu, Honitsu), 3)
  let chinitsu = yt_input(
    [
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_m(2),
      yt_m(2),
      yt_m(2),
      yt_m(5),
    ],
    yt_m(5),
  )
  assert_eq(yt_max_han(chinitsu, Chinitsu), 6)
  assert_false(yt_has(chinitsu, Honitsu))
  let open_tanyao = yt_input(
    [
      yt_p(3),
      yt_p(4),
      yt_p(5),
      yt_s(4),
      yt_s(5),
      yt_s(6),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_p(5),
    ],
    yt_p(5),
    melds=[yt_meld(Chi, [yt_m(2), yt_m(3), yt_m(4)])],
  )
  assert_true(yt_has(open_tanyao, Tanyao))
  let no_open_tanyao : RuleSet = { ..RuleSet::standard(), open_tanyao: false }
  assert_false(yt_has(open_tanyao, Tanyao, rules=no_open_tanyao))
  assert_true(yt_values(open_tanyao, rules=no_open_tanyao).is_empty())
}

///|
test "apply open-hand reductions to sequence and flush yaku" {
  let open_chanta = yt_input(
    [
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_s(1),
      yt_s(2),
      yt_s(3),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_h(East),
    ],
    yt_h(East),
    melds=[yt_meld(Chi, [yt_m(1), yt_m(2), yt_m(3)])],
  )
  assert_eq(yt_max_han(open_chanta, SanshokuDoujun), 1)
  assert_eq(yt_max_han(open_chanta, Chanta), 1)
  let open_ittsu = yt_input(
    [
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_h(West),
    ],
    yt_h(West),
    melds=[yt_meld(Chi, [yt_m(1), yt_m(2), yt_m(3)])],
  )
  assert_eq(yt_max_han(open_ittsu, Ittsu), 1)
  let open_junchan = yt_input(
    [
      yt_p(1),
      yt_p(2),
      yt_p(3),
      yt_s(1),
      yt_s(2),
      yt_s(3),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_p(9),
    ],
    yt_p(9),
    melds=[yt_meld(Chi, [yt_m(1), yt_m(2), yt_m(3)])],
  )
  assert_eq(yt_max_han(open_junchan, Junchan), 2)
  let open_honitsu = yt_input(
    [
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_h(White),
      yt_h(White),
      yt_h(White),
      yt_h(East),
    ],
    yt_h(East),
    melds=[yt_meld(Chi, [yt_m(1), yt_m(2), yt_m(3)])],
  )
  assert_eq(yt_max_han(open_honitsu, Honitsu), 2)
  let open_chinitsu = yt_input(
    [
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_m(2),
      yt_m(2),
      yt_m(2),
      yt_m(5),
    ],
    yt_m(5),
    melds=[yt_meld(Chi, [yt_m(1), yt_m(2), yt_m(3)])],
  )
  assert_eq(yt_max_han(open_chinitsu, Chinitsu), 5)
}

///|
test "detect tile-composition yakuman and compound yakuman" {
  let honors = yt_input(
    [
      yt_h(White),
      yt_h(White),
      yt_h(White),
      yt_h(Green),
      yt_h(Green),
      yt_h(Green),
      yt_h(Red),
      yt_h(Red),
      yt_h(Red),
      yt_h(East),
      yt_h(East),
      yt_h(East),
      yt_h(South),
    ],
    yt_h(South),
  )
  assert_true(yt_has(honors, Daisangen))
  assert_true(yt_has(honors, Tsuuiisou))
  assert_false(yt_has(honors, Toitoi))
  let green = yt_input(
    [
      yt_s(2),
      yt_s(2),
      yt_s(2),
      yt_s(3),
      yt_s(3),
      yt_s(3),
      yt_s(4),
      yt_s(4),
      yt_s(4),
      yt_s(6),
      yt_s(6),
      yt_s(6),
      yt_h(Green),
    ],
    yt_h(Green),
  )
  assert_true(yt_has(green, Ryuuiisou))
  let terminals = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_m(9),
      yt_m(9),
      yt_m(9),
      yt_p(1),
      yt_p(1),
      yt_p(1),
      yt_p(9),
      yt_p(9),
      yt_p(9),
      yt_s(1),
    ],
    yt_s(1),
  )
  assert_true(yt_has(terminals, Chinroutou))
}

///|
test "detect double yakuman waits and honor yakuman variants" {
  let suuankou = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_m(2),
      yt_m(2),
      yt_m(2),
      yt_p(3),
      yt_p(3),
      yt_p(3),
      yt_s(4),
      yt_s(4),
      yt_s(4),
      yt_h(East),
    ],
    yt_h(East),
  )
  assert_eq(yt_max_yakuman(suuankou, Suuankou), 2)
  let suuankou_tsumo = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_m(2),
      yt_m(2),
      yt_m(2),
      yt_p(3),
      yt_p(3),
      yt_p(3),
      yt_s(4),
      yt_s(4),
      yt_h(East),
      yt_h(East),
    ],
    yt_s(4),
    context=yt_context(Tsumo),
  )
  assert_eq(yt_max_yakuman(suuankou_tsumo, Suuankou), 1)
  let daisuushi = yt_input(
    [
      yt_h(East),
      yt_h(East),
      yt_h(East),
      yt_h(South),
      yt_h(South),
      yt_h(South),
      yt_h(West),
      yt_h(West),
      yt_h(West),
      yt_h(North),
      yt_h(North),
      yt_h(North),
      yt_h(White),
    ],
    yt_h(White),
  )
  assert_eq(yt_max_yakuman(daisuushi, Daisuushi), 2)
  assert_false(yt_has(daisuushi, Shousuushi))
  let shousuushi = yt_input(
    [
      yt_h(East),
      yt_h(East),
      yt_h(East),
      yt_h(South),
      yt_h(South),
      yt_h(South),
      yt_h(West),
      yt_h(West),
      yt_h(West),
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_h(North),
    ],
    yt_h(North),
  )
  assert_true(yt_has(shousuushi, Shousuushi))
}

///|
test "detect kokushi, chuuren, suukantsu, and tenhou" {
  let kokushi = yt_input(
    [
      yt_m(1),
      yt_m(9),
      yt_p(1),
      yt_p(9),
      yt_s(1),
      yt_s(9),
      yt_h(East),
      yt_h(South),
      yt_h(West),
      yt_h(North),
      yt_h(White),
      yt_h(Green),
      yt_h(Red),
    ],
    yt_m(1),
  )
  assert_eq(yt_max_yakuman(kokushi, KokushiMusou), 2)
  let kokushi_single = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(9),
      yt_p(1),
      yt_p(9),
      yt_s(1),
      yt_s(9),
      yt_h(East),
      yt_h(South),
      yt_h(West),
      yt_h(North),
      yt_h(White),
      yt_h(Green),
    ],
    yt_h(Red),
  )
  assert_eq(yt_max_yakuman(kokushi_single, KokushiMusou), 1)
  let chuuren = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_m(9),
      yt_m(9),
    ],
    yt_m(5),
  )
  assert_eq(yt_max_yakuman(chuuren, ChuurenPoutou), 2)
  let chuuren_single = yt_input(
    [
      yt_m(1),
      yt_m(1),
      yt_m(2),
      yt_m(3),
      yt_m(4),
      yt_m(5),
      yt_m(5),
      yt_m(6),
      yt_m(7),
      yt_m(8),
      yt_m(9),
      yt_m(9),
      yt_m(9),
    ],
    yt_m(1),
  )
  assert_eq(yt_max_yakuman(chuuren_single, ChuurenPoutou), 1)
  let four_kans = yt_input([yt_h(White)], yt_h(White), melds=[
    yt_meld(OpenKan, [yt_m(1), yt_m(1), yt_m(1), yt_m(1)]),
    yt_meld(OpenKan, [yt_p(1), yt_p(1), yt_p(1), yt_p(1)]),
    yt_meld(OpenKan, [yt_s(1), yt_s(1), yt_s(1), yt_s(1)]),
    yt_meld(OpenKan, [yt_h(East), yt_h(East), yt_h(East), yt_h(East)]),
  ])
  assert_true(yt_has(four_kans, Suukantsu))
  let tenhou = yt_basic_hand(yt_context(Tsumo, seat=East, tenhou=true))
  assert_true(yt_has(tenhou, Tenhou))
  assert_false(yt_has(tenhou, MenzenTsumo))
  let singles : RuleSet = { ..RuleSet::standard(), double_yakuman: false }
  assert_eq(yt_max_yakuman(kokushi, KokushiMusou, rules=singles), 1)
  assert_eq(yt_max_yakuman(chuuren, ChuurenPoutou, rules=singles), 1)
}

///|
test "reject a shape that did not come from the hand" {
  let hand = yt_basic_hand(yt_context(Ron))
  let fake : HandShape = SevenPairs([
    Numbered(Man, 1),
    Numbered(Man, 2),
    Numbered(Man, 3),
    Numbered(Man, 4),
    Numbered(Man, 5),
    Numbered(Man, 6),
    Numbered(Man, 7),
  ])
  try detect_yaku(hand, fake, RuleSet::standard()) catch {
    InvalidHandShape => ()
    _ => fail("expected InvalidHandShape")
  } noraise {
    _ => fail("expected detect_yaku to raise")
  }
}
