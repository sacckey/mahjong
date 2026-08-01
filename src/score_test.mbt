///|
fn st_m(rank : Int, red? : Bool = false) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Man, rank, red~)
}

///|
fn st_p(rank : Int) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Pin, rank)
}

///|
fn st_s(rank : Int) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Sou, rank)
}

///|
fn st_h(honor : @mahjong.Honor) -> @mahjong.Tile {
  @mahjong.Tile::honor(honor)
}

///|
fn st_context(
  win_method : @mahjong.WinMethod,
  seat? : @mahjong.Wind = South,
  round? : @mahjong.Wind = East,
  riichi? : @mahjong.RiichiState = NoRiichi,
  honba? : Int = 0,
  riichi_sticks? : Int = 0,
) -> @mahjong.WinContext {
  {
    win_method,
    seat_wind: seat,
    round_wind: round,
    riichi,
    ippatsu: false,
    rinshan: false,
    chankan: false,
    haitei: false,
    houtei: false,
    tenhou: false,
    chiihou: false,
    honba,
    riichi_sticks,
  }
}

///|
fn st_input(
  concealed : Array[@mahjong.Tile],
  winning : @mahjong.Tile,
  dora? : Array[@mahjong.Tile] = [],
  ura? : Array[@mahjong.Tile] = [],
  context? : @mahjong.WinContext = st_context(Ron),
) -> @mahjong.HandInput {
  {
    concealed_tiles: concealed,
    winning_tile: winning,
    melds: [],
    dora_indicators: dora,
    ura_dora_indicators: ura,
    context,
  }
}

///|
fn st_pinfu_hand(context : @mahjong.WinContext) -> @mahjong.HandInput {
  st_input(
    [
      st_m(1),
      st_m(2),
      st_m(3),
      st_m(4),
      st_m(5),
      st_m(6),
      st_p(1),
      st_p(2),
      st_p(3),
      st_s(7),
      st_s(8),
      st_p(5),
      st_p(5),
    ],
    st_s(9),
    context~,
  )
}

///|
test "score integrates yaku dora fu honba and riichi sticks" {
  let base = st_pinfu_hand(
    st_context(Ron, riichi=Riichi, honba=2, riichi_sticks=1),
  )
  let hand : @mahjong.HandInput = { ..base, dora_indicators: [st_p(4)] }
  let result = @mahjong.score_standard(hand)
  assert_true(result.shape is Standard(wait=Ryanmen, ..))
  assert_true(result.yaku.any(value => value.yaku == Riichi && value.han == 1))
  assert_true(result.yaku.any(value => value.yaku == Pinfu && value.han == 1))
  assert_eq(result.bonus_han, { dora: 2, ura_dora: 0, aka_dora: 0 })
  assert_eq(result.han, 4)
  assert_eq(result.fu, 30)
  assert_eq(result.fu_items, [
    { reason: Base, fu: 20 },
    { reason: MenzenRon, fu: 10 },
  ])
  assert_eq(result.limit, BelowMangan)
  assert_eq(result.base_points, 1920)
  assert_eq(result.payment, RonPayment(discarder=8300))
  assert_eq(result.riichi_bonus, 1000)
  assert_eq(result.winner_gain, 9300)
  assert_eq(result, @mahjong.score(hand, @mahjong.RuleSet::standard()))
  let kiriage : @mahjong.RuleSet = {
    ..@mahjong.RuleSet::standard(),
    kiriage_mangan: true,
  }
  let kiriage_result = @mahjong.score(hand, kiriage)
  assert_eq(kiriage_result.limit, Mangan)
  assert_eq(kiriage_result.payment, RonPayment(discarder=8600))
  assert_eq(kiriage_result.winner_gain, 9600)
}

///|
test "score integrates dealer tsumo payments" {
  let hand = st_pinfu_hand(st_context(Tsumo, seat=East, riichi=Riichi, honba=1))
  let result = @mahjong.score_standard(hand)
  assert_eq(result.han, 3)
  assert_eq(result.fu, 20)
  assert_eq(result.limit, BelowMangan)
  assert_eq(result.payment, DealerTsumoPayment(each=1400))
  assert_eq(result.winner_gain, 4200)
}

///|
test "dora cannot satisfy the one-yaku requirement" {
  let hand = st_input(
    [
      st_m(1),
      st_m(2),
      st_m(3),
      st_m(4),
      st_m(5),
      st_m(6),
      st_p(7),
      st_p(8),
      st_p(9),
      st_s(3),
      st_s(5),
      st_h(West),
      st_h(West),
    ],
    st_s(4),
    dora=[st_s(3)],
  )
  try @mahjong.score_standard(hand) catch {
    NoYaku => ()
    _ => fail("expected NoYaku")
  } noraise {
    _ => fail("expected score_standard to raise")
  }
}

///|
fn st_counted_hand() -> @mahjong.HandInput {
  st_input(
    [
      st_m(1),
      st_m(1),
      st_m(2),
      st_m(2),
      st_m(3),
      st_m(3),
      st_m(4),
      st_m(4),
      st_m(5, red=true),
      st_m(5),
      st_m(6),
      st_m(6),
      st_m(7),
    ],
    st_m(7),
    dora=[st_m(6)],
    context=st_context(Ron, riichi=Riichi),
  )
}

///|
test "is_winning_hand checks structural completion" {
  let winning = st_counted_hand()
  assert_true(@mahjong.is_winning_hand(winning))
  let incomplete : @mahjong.HandInput = { ..winning, winning_tile: st_m(8) }
  assert_false(@mahjong.is_winning_hand(incomplete))
}

///|
test "counted yakuman can be capped at sanbaiman and best shape is deterministic" {
  let hand = st_counted_hand()
  let counted = @mahjong.score_standard(hand)
  assert_true(counted.shape is Standard(wait=Ryanmen, ..))
  assert_true(counted.yaku.any(value => value.yaku == Ryanpeikou))
  assert_eq(counted.han, 14)
  assert_eq(counted.fu, 30)
  assert_eq(counted.limit, Yakuman(1))
  assert_eq(counted.payment, RonPayment(discarder=32000))
  let no_counted : @mahjong.RuleSet = {
    ..@mahjong.RuleSet::standard(),
    counted_yakuman: false,
  }
  let capped = @mahjong.score(hand, no_counted)
  assert_true(capped.shape is Standard(wait=Ryanmen, ..))
  assert_eq(capped.han, 14)
  assert_eq(capped.fu, 30)
  assert_eq(capped.limit, Sanbaiman)
  assert_eq(capped.payment, RonPayment(discarder=24000))
}

///|
test "a later decomposition replaces an earlier lower-paying candidate" {
  let hand = st_input(
    [
      st_m(1),
      st_m(2),
      st_m(2),
      st_m(3),
      st_m(3),
      st_m(4),
      st_m(4),
      st_m(5),
      st_m(5),
      st_m(6),
      st_m(6),
      st_m(7),
      st_m(7),
    ],
    st_m(1),
    context=st_context(Ron, riichi=Riichi),
  )
  let result = @mahjong.score_standard(hand)
  assert_true(result.shape is Standard(pair=Numbered(Man, 4), wait=Ryanmen, ..))
  assert_true(result.yaku.any(value => value.yaku == Pinfu))
  assert_true(result.yaku.any(value => value.yaku == Ryanpeikou))
  assert_eq(result.han, 11)
  assert_eq(result.fu, 30)
  assert_eq(result.limit, Sanbaiman)
  assert_eq(result.payment, RonPayment(discarder=24000))
}

///|
fn st_compound_yakuman_hand() -> @mahjong.HandInput {
  st_input(
    [
      st_h(East),
      st_h(East),
      st_h(East),
      st_h(South),
      st_h(South),
      st_h(South),
      st_h(West),
      st_h(West),
      st_h(West),
      st_h(North),
      st_h(North),
      st_h(North),
      st_h(White),
    ],
    st_h(White),
    dora=[st_h(North)],
    context=st_context(Ron, honba=1, riichi_sticks=2),
  )
}

///|
test "compound and double yakuman use explicit multipliers and ignore dora" {
  let hand = st_compound_yakuman_hand()
  let result = @mahjong.score_standard(hand)
  assert_eq(result.yaku, [
    { yaku: Suuankou, han: 0, yakuman_multiplier: 2 },
    { yaku: Daisuushi, han: 0, yakuman_multiplier: 2 },
    { yaku: Tsuuiisou, han: 0, yakuman_multiplier: 1 },
  ])
  assert_eq(result.bonus_han, { dora: 0, ura_dora: 0, aka_dora: 0 })
  assert_eq(result.han, 0)
  assert_eq(result.fu, 0)
  assert_true(result.fu_items.is_empty())
  assert_eq(result.limit, Yakuman(5))
  assert_eq(result.base_points, 40000)
  assert_eq(result.payment, RonPayment(discarder=160300))
  assert_eq(result.riichi_bonus, 2000)
  assert_eq(result.winner_gain, 162300)
  let single_variants : @mahjong.RuleSet = {
    ..@mahjong.RuleSet::standard(),
    double_yakuman: false,
  }
  let single = @mahjong.score(hand, single_variants)
  assert_eq(single.limit, Yakuman(3))
  assert_eq(single.payment, RonPayment(discarder=96300))
  assert_eq(single.winner_gain, 98300)
}

///|
test "score validates rules before evaluating candidates" {
  let hand = st_pinfu_hand(st_context(Ron, riichi=Riichi))
  let invalid : @mahjong.RuleSet = {
    ..@mahjong.RuleSet::standard(),
    double_wind_pair_fu: 3,
  }
  try @mahjong.score(hand, invalid) catch {
    InvalidRule(_) => ()
    _ => fail("expected InvalidRule")
  } noraise {
    _ => fail("expected score to raise")
  }
}
