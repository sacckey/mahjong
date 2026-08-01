///|
/// A numbered-tile suit.
pub(all) enum Suit {
  Man
  Pin
  Sou
} derive(Debug, Eq, Compare)

///|
/// An honor tile.
pub(all) enum Honor {
  East
  South
  West
  North
  White
  Green
  Red
} derive(Debug, Eq, Compare)

///|
/// One of the 34 tile kinds. Numbered ranks must be between 1 and 9.
pub(all) enum TileKind {
  Numbered(Suit, Int)
  HonorTile(Honor)
} derive(Debug, Eq, Compare)

///|
/// A physical tile. A red tile must be a numbered five.
pub(all) struct Tile {
  kind : TileKind
  is_red : Bool
} derive(Debug, Eq)

///|
/// A called or declared meld.
pub(all) enum MeldKind {
  Chi
  Pon
  OpenKan
  ClosedKan
  AddedKan
} derive(Debug, Eq)

///|
/// Tiles in a meld are stored explicitly so red fives are preserved.
pub(all) struct Meld {
  kind : MeldKind
  tiles : Array[Tile]
} derive(Debug, Eq)

///|
/// A player's seat or the prevailing wind.
pub(all) enum Wind {
  East
  South
  West
  North
} derive(Debug, Eq, Compare)

///|
/// How the hand was won.
pub(all) enum WinMethod {
  Ron
  Tsumo
} derive(Debug, Eq)

///|
/// Riichi state supplied by the game engine.
pub(all) enum RiichiState {
  NoRiichi
  Riichi
  DoubleRiichi
} derive(Debug, Eq)

///|
/// Situational facts that cannot be inferred from the tiles alone.
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
  honba : Int
  riichi_sticks : Int
} derive(Debug, Eq)

///|
/// Complete scoring input. `concealed_tiles` excludes `winning_tile`.
pub(all) struct HandInput {
  concealed_tiles : Array[Tile]
  winning_tile : Tile
  melds : Array[Meld]
  dora_indicators : Array[Tile]
  ura_dora_indicators : Array[Tile]
  context : WinContext
} derive(Debug, Eq)

///|
/// Configurable choices in the version-one ruleset.
pub(all) struct RuleSet {
  open_tanyao : Bool
  kiriage_mangan : Bool
  double_yakuman : Bool
  counted_yakuman : Bool
  double_wind_pair_fu : Int
} derive(Debug, Eq)

///|
/// The default rules described in `docs/rules-v1.md`.
pub fn RuleSet::standard() -> RuleSet {
  {
    open_tanyao: true,
    kiriage_mangan: false,
    double_yakuman: true,
    counted_yakuman: true,
    double_wind_pair_fu: 4,
  }
}

///|
/// Wait shape used for fu and yaku evaluation.
pub(all) enum WaitKind {
  Ryanmen
  Kanchan
  Penchan
  Tanki
  Shanpon
  KokushiSingle
  KokushiThirteenSided
} derive(Debug, Eq)

///|
/// A group in a standard four-groups-and-a-pair hand.
pub(all) enum Group {
  Sequence(TileKind, is_open~ : Bool)
  Triplet(TileKind, is_open~ : Bool)
  Quad(TileKind, is_open~ : Bool)
} derive(Debug, Eq)

///|
/// One structural interpretation of a winning hand.
pub(all) enum HandShape {
  Standard(pair~ : TileKind, groups~ : Array[Group], wait~ : WaitKind)
  SevenPairs(Array[TileKind])
  ThirteenOrphans(wait~ : WaitKind)
} derive(Debug, Eq)

///|
/// Standard yaku and yakuman supported by version one.
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
} derive(Debug, Eq, Compare)

///|
/// One matched yaku. Exactly one of `han` and `yakuman_multiplier` is non-zero.
pub(all) struct YakuValue {
  yaku : Yaku
  han : Int
  yakuman_multiplier : Int
} derive(Debug, Eq)

///|
/// Bonus han do not satisfy the one-yaku requirement.
pub(all) struct BonusHan {
  dora : Int
  ura_dora : Int
  aka_dora : Int
} derive(Debug, Eq)

///|
/// A reason contributing to the rounded fu total.
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
} derive(Debug, Eq)

///|
/// One item in the fu explanation.
pub(all) struct FuItem {
  reason : FuReason
  fu : Int
} derive(Debug, Eq)

///|
/// Limit category applied to the basic points.
pub(all) enum Limit {
  BelowMangan
  Mangan
  Haneman
  Baiman
  Sanbaiman
  Yakuman(Int)
} derive(Debug, Eq)

///|
/// Final payment by win method. Values already include honba.
pub(all) enum WinPayment {
  RonPayment(discarder~ : Int)
  DealerTsumoPayment(each~ : Int)
  NonDealerTsumoPayment(dealer~ : Int, non_dealer_each~ : Int)
} derive(Debug, Eq)

///|
/// Result of the arithmetic point calculation.
pub(all) struct PointResult {
  han : Int
  fu : Int
  limit : Limit
  base_points : Int
  payment : WinPayment
  riichi_bonus : Int
  winner_gain : Int
} derive(Debug, Eq)

///|
/// Complete result returned after hand evaluation.
pub(all) struct ScoreResult {
  shape : HandShape
  yaku : Array[YakuValue]
  bonus_han : BonusHan
  han : Int
  fu : Int
  fu_items : Array[FuItem]
  limit : Limit
  base_points : Int
  payment : WinPayment
  riichi_bonus : Int
  winner_gain : Int
} derive(Debug, Eq)

///|
/// Errors from validating or evaluating a hand.
pub(all) suberror ScoreError {
  InvalidTile(String)
  TooManyCopies(TileKind, Int)
  InvalidHandSize(Int)
  InvalidMeld(String)
  ContradictoryContext(String)
  NotWinningHand
  InvalidHandShape
  InvalidRule(String)
  NoYaku
} derive(Debug, Eq)
