///|
fn tile_kind_code(kind : @mahjong.TileKind) -> String {
  match kind {
    @mahjong.Numbered(@mahjong.Man, rank) => "\{rank}m"
    @mahjong.Numbered(@mahjong.Pin, rank) => "\{rank}p"
    @mahjong.Numbered(@mahjong.Sou, rank) => "\{rank}s"
    @mahjong.HonorTile(@mahjong.East) => "east"
    @mahjong.HonorTile(@mahjong.South) => "south"
    @mahjong.HonorTile(@mahjong.West) => "west"
    @mahjong.HonorTile(@mahjong.North) => "north"
    @mahjong.HonorTile(@mahjong.White) => "white"
    @mahjong.HonorTile(@mahjong.Green) => "green"
    @mahjong.HonorTile(@mahjong.Red) => "red"
  }
}

///|
fn wait_id(wait : @mahjong.WaitKind) -> String {
  match wait {
    @mahjong.Ryanmen => "ryanmen"
    @mahjong.Kanchan => "kanchan"
    @mahjong.Penchan => "penchan"
    @mahjong.Tanki => "tanki"
    @mahjong.Shanpon => "shanpon"
    @mahjong.KokushiSingle => "kokushiSingle"
    @mahjong.KokushiThirteenSided => "kokushiThirteenSided"
  }
}

///|
fn group_dto(group : @mahjong.Group) -> GroupDto {
  match group {
    @mahjong.Sequence(tile, is_open~) =>
      { kind: "sequence", tile: tile_kind_code(tile), open: is_open }
    @mahjong.Triplet(tile, is_open~) =>
      { kind: "triplet", tile: tile_kind_code(tile), open: is_open }
    @mahjong.Quad(tile, is_open~) =>
      { kind: "quad", tile: tile_kind_code(tile), open: is_open }
  }
}

///|
fn shape_dto(shape : @mahjong.HandShape) -> ShapeDto {
  match shape {
    @mahjong.Standard(pair~, groups~, wait~) =>
      {
        kind: "standard",
        pair: Some(tile_kind_code(pair)),
        groups: groups.map(group_dto),
        tiles: [],
        wait: wait_id(wait),
      }
    @mahjong.SevenPairs(pairs) =>
      {
        kind: "sevenPairs",
        pair: None,
        groups: [],
        tiles: pairs.map(tile_kind_code),
        wait: "tanki",
      }
    @mahjong.ThirteenOrphans(wait~) =>
      {
        kind: "thirteenOrphans",
        pair: None,
        groups: [],
        tiles: [],
        wait: wait_id(wait),
      }
  }
}

///|
fn yaku_id(yaku : @mahjong.Yaku) -> String {
  match yaku {
    @mahjong.Riichi => "riichi"
    @mahjong.DoubleRiichi => "doubleRiichi"
    @mahjong.Ippatsu => "ippatsu"
    @mahjong.MenzenTsumo => "menzenTsumo"
    @mahjong.Tanyao => "tanyao"
    @mahjong.Pinfu => "pinfu"
    @mahjong.Iipeikou => "iipeikou"
    @mahjong.SeatWind => "seatWind"
    @mahjong.RoundWind => "roundWind"
    @mahjong.WhiteDragon => "whiteDragon"
    @mahjong.GreenDragon => "greenDragon"
    @mahjong.RedDragon => "redDragon"
    @mahjong.RinshanKaihou => "rinshanKaihou"
    @mahjong.Chankan => "chankan"
    @mahjong.HaiteiRaoyue => "haiteiRaoyue"
    @mahjong.HouteiRaoyui => "houteiRaoyui"
    @mahjong.SanshokuDoujun => "sanshokuDoujun"
    @mahjong.Ittsu => "ittsu"
    @mahjong.Chanta => "chanta"
    @mahjong.Chiitoitsu => "chiitoitsu"
    @mahjong.Toitoi => "toitoi"
    @mahjong.Sanankou => "sanankou"
    @mahjong.Honroutou => "honroutou"
    @mahjong.SanshokuDoukou => "sanshokuDoukou"
    @mahjong.Sankantsu => "sankantsu"
    @mahjong.Shousangen => "shousangen"
    @mahjong.Junchan => "junchan"
    @mahjong.Honitsu => "honitsu"
    @mahjong.Ryanpeikou => "ryanpeikou"
    @mahjong.Chinitsu => "chinitsu"
    @mahjong.Tenhou => "tenhou"
    @mahjong.Chiihou => "chiihou"
    @mahjong.KokushiMusou => "kokushiMusou"
    @mahjong.Suuankou => "suuankou"
    @mahjong.Daisangen => "daisangen"
    @mahjong.Shousuushi => "shousuushi"
    @mahjong.Daisuushi => "daisuushi"
    @mahjong.Tsuuiisou => "tsuuiisou"
    @mahjong.Ryuuiisou => "ryuuiisou"
    @mahjong.Chinroutou => "chinroutou"
    @mahjong.ChuurenPoutou => "chuurenPoutou"
    @mahjong.Suukantsu => "suukantsu"
  }
}

///|
fn fu_reason_id(reason : @mahjong.FuReason) -> String {
  match reason {
    @mahjong.Base => "base"
    @mahjong.MenzenRon => "menzenRon"
    @mahjong.Tsumo => "tsumo"
    @mahjong.ValuePair => "valuePair"
    @mahjong.Wait => "wait"
    @mahjong.OpenTriplet => "openTriplet"
    @mahjong.ClosedTriplet => "closedTriplet"
    @mahjong.OpenQuad => "openQuad"
    @mahjong.ClosedQuad => "closedQuad"
    @mahjong.OpenPinfuShape => "openPinfuShape"
    @mahjong.SevenPairsFixed => "sevenPairsFixed"
  }
}

///|
fn limit_dto(limit : @mahjong.Limit) -> LimitDto {
  match limit {
    @mahjong.BelowMangan => { kind: "belowMangan", yakumanMultiplier: 0 }
    @mahjong.Mangan => { kind: "mangan", yakumanMultiplier: 0 }
    @mahjong.Haneman => { kind: "haneman", yakumanMultiplier: 0 }
    @mahjong.Baiman => { kind: "baiman", yakumanMultiplier: 0 }
    @mahjong.Sanbaiman => { kind: "sanbaiman", yakumanMultiplier: 0 }
    @mahjong.Yakuman(multiplier) =>
      { kind: "yakuman", yakumanMultiplier: multiplier }
  }
}

///|
fn payment_dto(payment : @mahjong.WinPayment) -> PaymentDto {
  match payment {
    @mahjong.RonPayment(discarder~) =>
      {
        kind: "ron",
        discarder: Some(discarder),
        each: None,
        dealer: None,
        nonDealerEach: None,
      }
    @mahjong.DealerTsumoPayment(each~) =>
      {
        kind: "dealerTsumo",
        discarder: None,
        each: Some(each),
        dealer: None,
        nonDealerEach: None,
      }
    @mahjong.NonDealerTsumoPayment(dealer~, non_dealer_each~) =>
      {
        kind: "nonDealerTsumo",
        discarder: None,
        each: None,
        dealer: Some(dealer),
        nonDealerEach: Some(non_dealer_each),
      }
  }
}

///|
fn score_result_dto(result : @mahjong.ScoreResult) -> ScoreResultDto {
  {
    han: result.han,
    fu: result.fu,
    limit: limit_dto(result.limit),
    basePoints: result.base_points,
    payment: payment_dto(result.payment),
    riichiBonus: result.riichi_bonus,
    winnerGain: result.winner_gain,
    yaku: result.yaku.map(value => {
      id: yaku_id(value.yaku),
      han: value.han,
      yakumanMultiplier: value.yakuman_multiplier,
    }),
    bonusHan: {
      dora: result.bonus_han.dora,
      uraDora: result.bonus_han.ura_dora,
      akaDora: result.bonus_han.aka_dora,
    },
    fuItems: result.fu_items.map(item => {
      reason: fu_reason_id(item.reason),
      fu: item.fu,
    }),
    shape: shape_dto(result.shape),
  }
}
