///|
/// A numbered-tile suit.
#derive(Debug, Eq, Compare)
pub(all) enum Suit {
  Man
  Pin
  Sou
}

///|
/// An honor tile.
#derive(Debug, Eq, Compare)
pub(all) enum Honor {
  East
  South
  West
  North
  White
  Green
  Red
}

///|
/// One of the 34 tile kinds. Numbered ranks must be between 1 and 9.
#derive(Debug, Eq, Compare)
pub(all) enum TileKind {
  Numbered(Suit, Int32)
  HonorTile(Honor)
}

///|
/// A physical tile. A red tile must be a numbered five.
#derive(Debug, Eq)
pub(all) struct Tile {
  kind : TileKind
  is_red : Bool
}

///|
/// A called or declared meld.
#derive(Debug, Eq)
pub(all) enum MeldKind {
  Chi
  Pon
  OpenKan
  ClosedKan
  AddedKan
}

///|
/// Tiles in a meld are stored explicitly so red fives are preserved.
#derive(Debug, Eq)
pub(all) struct Meld {
  kind : MeldKind
  tiles : Array[Tile]
}

///|
/// A player's seat or the prevailing wind.
#derive(Debug, Eq, Compare)
pub(all) enum Wind {
  East
  South
  West
  North
}

///|
/// How the hand was won.
#derive(Debug, Eq)
pub(all) enum WinMethod {
  Ron
  Tsumo
}

///|
/// Riichi state supplied by the game engine.
#derive(Debug, Eq)
pub(all) enum RiichiState {
  NoRiichi
  Riichi
  DoubleRiichi
}

///|
/// Situational facts that cannot be inferred from the tiles alone.
#derive(Debug, Eq)
pub(all) struct WinContext {
  win_method : WinMethod
  seat_wind : Wind
  round_wind : Wind
  riichi : RiichiState
  ippatsu : Bool
  rinshan : Bool
  chankan : Bool
  haitei : Bool
  houtei : Bool
  tenhou : Bool
  chiihou : Bool
  honba : Int32
  riichi_sticks : Int32
}

///|
/// Create a context with no situational yaku, honba, or riichi sticks.
pub fn WinContext::new(
  win_method : WinMethod,
  seat_wind~ : Wind,
  round_wind~ : Wind,
) -> WinContext {
  {
    win_method,
    seat_wind,
    round_wind,
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
/// Complete scoring input. `concealed_tiles` excludes `winning_tile`.
#derive(Debug, Eq)
pub(all) struct HandInput {
  concealed_tiles : Array[Tile]
  winning_tile : Tile
  melds : Array[Meld]
  dora_indicators : Array[Tile]
  ura_dora_indicators : Array[Tile]
  context : WinContext
}

///|
/// Create an input without melds, dora indicators, or ura-dora indicators.
pub fn HandInput::new(
  concealed_tiles : Array[Tile],
  winning_tile~ : Tile,
  context~ : WinContext,
) -> HandInput {
  {
    concealed_tiles,
    winning_tile,
    melds: [],
    dora_indicators: [],
    ura_dora_indicators: [],
    context,
  }
}

///|
/// Validation rules for the number of physical copies of one tile kind.
/// `None` permits any count that fits in the structural hand size.
#derive(Debug, Eq)
pub(all) struct TileCopyRules {
  max_copies_per_kind : Int32?
}

///|
/// Use the four-copy limit of an ordinary riichi mahjong tile set.
pub fn TileCopyRules::standard() -> TileCopyRules {
  { max_copies_per_kind: Some(4), }
}

///|
/// Permit duplicate physical tiles beyond the ordinary four copies.
pub fn TileCopyRules::unlimited() -> TileCopyRules {
  { max_copies_per_kind: None, }
}

///|
/// Configurable choices in the version-one ruleset.
#derive(Debug, Eq)
pub(all) struct RuleSet {
  open_tanyao : Bool
  kiriage_mangan : Bool
  double_yakuman : Bool
  counted_yakuman : Bool
  double_wind_pair_fu : Int32
  /// Local yaku to score in addition to the standard yaku.
  local_yaku : Array[LocalYaku]
}

///|
/// The default rules described in `docs/rules-v1.md`.
pub fn RuleSet::standard() -> RuleSet {
  {
    open_tanyao: true,
    kiriage_mangan: false,
    double_yakuman: true,
    counted_yakuman: true,
    double_wind_pair_fu: 4,
    local_yaku: [],
  }
}

///|
/// Wait shape used for fu and yaku evaluation.
#derive(Debug, Eq)
pub(all) enum WaitKind {
  Ryanmen
  Kanchan
  Penchan
  Tanki
  Shanpon
  KokushiSingle
  KokushiThirteenSided
}

///|
/// A group in a standard four-groups-and-a-pair hand.
#derive(Debug, Eq)
pub(all) enum Group {
  Sequence(TileKind, is_open~ : Bool)
  Triplet(TileKind, is_open~ : Bool)
  Quad(TileKind, is_open~ : Bool)
}

///|
/// One structural interpretation of a winning hand.
#derive(Debug, Eq)
pub(all) enum HandShape {
  Standard(pair~ : TileKind, groups~ : Array[Group], wait~ : WaitKind)
  SevenPairs(Array[TileKind])
  ThirteenOrphans(wait~ : WaitKind)
}

///|
/// Local yaku that `RuleSet.local_yaku` can enable. None are scored by default.
#derive(Debug, Eq, Compare)
pub(all) enum LocalYaku {
  /// Man, pin, sou, a wind, and a dragon all appear. Two han.
  Uumensai
  /// Three triplets or quads of consecutive ranks in one suit. Two han.
  Sanrenkou
  /// Three identical sequences. Three han, two when open. Replaces iipeikou.
  IsshokuSanjun
  /// Pairs of two through eight in pin, closed. Yakuman.
  Daisharin
  /// Pairs of two through eight in sou, closed. Yakuman.
  Daichikurin
  /// Pairs of two through eight in man, closed. Yakuman.
  Daisuurin
  /// Pairs of all seven honors. Double yakuman. Replaces tsuuiisou.
  Daichisei
}

///|
/// Standard yaku and yakuman supported by version one, plus enabled local yaku.
#derive(Debug, Eq, Compare)
pub(all) enum Yaku {
  Riichi
  DoubleRiichi
  Ippatsu
  MenzenTsumo
  Tanyao
  Pinfu
  Iipeikou
  SeatWind
  RoundWind
  WhiteDragon
  GreenDragon
  RedDragon
  RinshanKaihou
  Chankan
  HaiteiRaoyue
  HouteiRaoyui
  SanshokuDoujun
  Ittsu
  Chanta
  Chiitoitsu
  Toitoi
  Sanankou
  Honroutou
  SanshokuDoukou
  Sankantsu
  Shousangen
  Junchan
  Honitsu
  Ryanpeikou
  Chinitsu
  Tenhou
  Chiihou
  KokushiMusou
  Suuankou
  Daisangen
  Shousuushi
  Daisuushi
  Tsuuiisou
  Ryuuiisou
  Chinroutou
  ChuurenPoutou
  Suukantsu
  Local(LocalYaku)
}

///|
/// One matched yaku. Exactly one of `han` and `yakuman_multiplier` is non-zero.
#derive(Debug, Eq)
pub(all) struct YakuValue {
  yaku : Yaku
  han : Int32
  yakuman_multiplier : Int32
}

///|
/// Bonus han do not satisfy the one-yaku requirement.
#derive(Debug, Eq)
pub(all) struct BonusHan {
  dora : Int32
  ura_dora : Int32
  aka_dora : Int32
}

///|
/// A reason contributing to the rounded fu total.
#derive(Debug, Eq)
pub(all) enum FuReason {
  Base
  MenzenRon
  Tsumo
  ValuePair
  Wait
  OpenTriplet
  ClosedTriplet
  OpenQuad
  ClosedQuad
  OpenPinfuShape
  SevenPairsFixed
}

///|
/// One item in the fu explanation.
#derive(Debug, Eq)
pub(all) struct FuItem {
  reason : FuReason
  fu : Int32
}

///|
/// Limit category applied to the basic points.
#derive(Debug, Eq)
pub(all) enum Limit {
  BelowMangan
  Mangan
  Haneman
  Baiman
  Sanbaiman
  Yakuman(Int32)
}

///|
/// Final payment by win method. Values already include honba.
#derive(Debug, Eq)
pub(all) enum WinPayment {
  RonPayment(discarder~ : Int32)
  DealerTsumoPayment(each~ : Int32)
  NonDealerTsumoPayment(dealer~ : Int32, non_dealer_each~ : Int32)
}

///|
/// Result of the arithmetic point calculation.
#derive(Debug, Eq)
pub(all) struct PointResult {
  han : Int32
  fu : Int32
  limit : Limit
  base_points : Int32
  payment : WinPayment
  riichi_bonus : Int32
  winner_gain : Int32
}

///|
/// Complete result returned after hand evaluation.
#derive(Debug, Eq)
pub(all) struct ScoreResult {
  shape : HandShape
  yaku : Array[YakuValue]
  bonus_han : BonusHan
  han : Int32
  fu : Int32
  fu_items : Array[FuItem]
  limit : Limit
  base_points : Int32
  payment : WinPayment
  riichi_bonus : Int32
  winner_gain : Int32
}

///|
/// Errors from validating or evaluating a hand.
#derive(Debug, Eq)
pub(all) suberror ScoreError {
  InvalidTile(String)
  TooManyCopies(TileKind, Int32)
  InvalidHandSize(Int32)
  InvalidMeld(String)
  ContradictoryContext(String)
  NotWinningHand
  InvalidHandShape
  InvalidRule(String)
  NoYaku
}
