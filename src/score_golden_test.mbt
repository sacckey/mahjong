///|
/// Hand-authored expected values for the standard rules. These values are not
/// generated from the scoring implementation; future external datasets should
/// be normalized into the same summary before comparison.
struct ScoreGoldenSummary {
  yaku : Array[@mahjong.YakuValue]
  bonus_han : @mahjong.BonusHan
  han : Int
  fu : Int
  limit : @mahjong.Limit
  base_points : Int
  payment : @mahjong.WinPayment
  riichi_bonus : Int
  winner_gain : Int
} derive(Debug, Eq)

///|
struct ScoreGoldenCase {
  name : String
  input : @mahjong.HandInput
  expected : ScoreGoldenSummary
}

///|
fn sg_m(rank : Int) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Man, rank)
}

///|
fn sg_p(rank : Int) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Pin, rank)
}

///|
fn sg_s(rank : Int) -> @mahjong.Tile {
  try! @mahjong.Tile::numbered(Sou, rank)
}

///|
fn sg_h(honor : @mahjong.Honor) -> @mahjong.Tile {
  @mahjong.Tile::honor(honor)
}

///|
fn sg_context(
  win_method : @mahjong.WinMethod,
  seat? : @mahjong.Wind = South,
  round? : @mahjong.Wind = East,
  riichi? : @mahjong.RiichiState = NoRiichi,
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
    honba: 0,
    riichi_sticks: 0,
  }
}

///|
fn sg_input(
  concealed : Array[@mahjong.Tile],
  winning : @mahjong.Tile,
  melds? : Array[@mahjong.Meld] = [],
  context? : @mahjong.WinContext = sg_context(Ron),
) -> @mahjong.HandInput {
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
fn sg_yaku(yaku : @mahjong.Yaku, han : Int) -> @mahjong.YakuValue {
  { yaku, han, yakuman_multiplier: 0 }
}

///|
fn sg_yakuman(yaku : @mahjong.Yaku, multiplier : Int) -> @mahjong.YakuValue {
  { yaku, han: 0, yakuman_multiplier: multiplier }
}

///|
fn sg_no_bonus() -> @mahjong.BonusHan {
  { dora: 0, ura_dora: 0, aka_dora: 0 }
}

///|
fn sg_summary(result : @mahjong.ScoreResult) -> ScoreGoldenSummary {
  {
    yaku: result.yaku,
    bonus_han: result.bonus_han,
    han: result.han,
    fu: result.fu,
    limit: result.limit,
    base_points: result.base_points,
    payment: result.payment,
    riichi_bonus: result.riichi_bonus,
    winner_gain: result.winner_gain,
  }
}

///|
fn sg_pinfu_hand(context : @mahjong.WinContext) -> @mahjong.HandInput {
  sg_input(
    [
      sg_m(1),
      sg_m(2),
      sg_m(3),
      sg_m(4),
      sg_m(5),
      sg_m(6),
      sg_p(1),
      sg_p(2),
      sg_p(3),
      sg_s(7),
      sg_s(8),
      sg_p(5),
      sg_p(5),
    ],
    sg_s(9),
    context~,
  )
}

///|
fn sg_seven_pairs_hand() -> @mahjong.HandInput {
  sg_input(
    [
      sg_m(1),
      sg_m(1),
      sg_m(2),
      sg_m(2),
      sg_p(3),
      sg_p(3),
      sg_p(4),
      sg_p(4),
      sg_s(5),
      sg_s(5),
      sg_s(6),
      sg_s(6),
      sg_h(East),
    ],
    sg_h(East),
    context=sg_context(Ron, riichi=Riichi),
  )
}

///|
fn sg_open_tanyao_hand() -> @mahjong.HandInput {
  let chi : @mahjong.Meld = { kind: Chi, tiles: [sg_m(2), sg_m(3), sg_m(4)] }
  sg_input(
    [
      sg_p(3),
      sg_p(4),
      sg_p(5),
      sg_s(4),
      sg_s(5),
      sg_s(6),
      sg_s(7),
      sg_s(8),
      sg_p(5),
      sg_p(5),
    ],
    sg_s(6),
    melds=[chi],
  )
}

///|
fn sg_open_white_dragon_hand() -> @mahjong.HandInput {
  let pon : @mahjong.Meld = {
    kind: Pon,
    tiles: [sg_h(White), sg_h(White), sg_h(White)],
  }
  sg_input(
    [
      sg_m(1),
      sg_m(2),
      sg_p(4),
      sg_p(5),
      sg_p(6),
      sg_s(7),
      sg_s(8),
      sg_s(9),
      sg_m(2),
      sg_m(2),
    ],
    sg_m(3),
    melds=[pon],
  )
}

///|
fn sg_ittsu_hand() -> @mahjong.HandInput {
  sg_input(
    [
      sg_m(1),
      sg_m(2),
      sg_m(3),
      sg_m(4),
      sg_m(5),
      sg_m(6),
      sg_m(7),
      sg_m(8),
      sg_m(9),
      sg_p(2),
      sg_p(3),
      sg_s(5),
      sg_s(5),
    ],
    sg_p(4),
  )
}

///|
fn sg_kokushi_thirteen_sided_hand() -> @mahjong.HandInput {
  sg_input(
    [
      sg_m(1),
      sg_m(9),
      sg_p(1),
      sg_p(9),
      sg_s(1),
      sg_s(9),
      sg_h(East),
      sg_h(South),
      sg_h(West),
      sg_h(North),
      sg_h(White),
      sg_h(Green),
      sg_h(Red),
    ],
    sg_h(East),
  )
}

///|
fn score_golden_cases() -> Array[ScoreGoldenCase] {
  [
    {
      name: "child ron: riichi pinfu",
      input: sg_pinfu_hand(sg_context(Ron, riichi=Riichi)),
      expected: {
        yaku: [sg_yaku(Riichi, 1), sg_yaku(Pinfu, 1)],
        bonus_han: sg_no_bonus(),
        han: 2,
        fu: 30,
        limit: BelowMangan,
        base_points: 480,
        payment: RonPayment(discarder=2000),
        riichi_bonus: 0,
        winner_gain: 2000,
      },
    },
    {
      name: "dealer tsumo: menzen tsumo pinfu",
      input: sg_pinfu_hand(sg_context(Tsumo, seat=East)),
      expected: {
        yaku: [sg_yaku(MenzenTsumo, 1), sg_yaku(Pinfu, 1)],
        bonus_han: sg_no_bonus(),
        han: 2,
        fu: 20,
        limit: BelowMangan,
        base_points: 320,
        payment: DealerTsumoPayment(each=700),
        riichi_bonus: 0,
        winner_gain: 2100,
      },
    },
    {
      name: "child ron: riichi seven pairs",
      input: sg_seven_pairs_hand(),
      expected: {
        yaku: [sg_yaku(Riichi, 1), sg_yaku(Chiitoitsu, 2)],
        bonus_han: sg_no_bonus(),
        han: 3,
        fu: 25,
        limit: BelowMangan,
        base_points: 800,
        payment: RonPayment(discarder=3200),
        riichi_bonus: 0,
        winner_gain: 3200,
      },
    },
    {
      name: "child ron: open tanyao",
      input: sg_open_tanyao_hand(),
      expected: {
        yaku: [sg_yaku(Tanyao, 1)],
        bonus_han: sg_no_bonus(),
        han: 1,
        fu: 30,
        limit: BelowMangan,
        base_points: 240,
        payment: RonPayment(discarder=1000),
        riichi_bonus: 0,
        winner_gain: 1000,
      },
    },
    {
      name: "child ron: open white dragon",
      input: sg_open_white_dragon_hand(),
      expected: {
        yaku: [sg_yaku(WhiteDragon, 1)],
        bonus_han: sg_no_bonus(),
        han: 1,
        fu: 30,
        limit: BelowMangan,
        base_points: 240,
        payment: RonPayment(discarder=1000),
        riichi_bonus: 0,
        winner_gain: 1000,
      },
    },
    {
      name: "child ron: pinfu ittsu",
      input: sg_ittsu_hand(),
      expected: {
        yaku: [sg_yaku(Pinfu, 1), sg_yaku(Ittsu, 2)],
        bonus_han: sg_no_bonus(),
        han: 3,
        fu: 30,
        limit: BelowMangan,
        base_points: 960,
        payment: RonPayment(discarder=3900),
        riichi_bonus: 0,
        winner_gain: 3900,
      },
    },
    {
      name: "child ron: thirteen-sided kokushi",
      input: sg_kokushi_thirteen_sided_hand(),
      expected: {
        yaku: [sg_yakuman(KokushiMusou, 2)],
        bonus_han: sg_no_bonus(),
        han: 0,
        fu: 0,
        limit: Yakuman(2),
        base_points: 16000,
        payment: RonPayment(discarder=64000),
        riichi_bonus: 0,
        winner_gain: 64000,
      },
    },
  ]
}

///|
test "golden standard scoring cases" {
  for case in score_golden_cases() {
    let actual = sg_summary(@mahjong.score_standard(case.input))
    if actual != case.expected {
      fail(
        "\{case.name}\nexpected: \{Repr(case.expected)}\nactual: \{Repr(actual)}",
      )
    }
  }
}
