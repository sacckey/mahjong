///|
/// Tiles relevant to structural hand analysis. `concealed_tiles` contains all
/// tiles currently held outside declared melds.
pub(all) struct AnalysisInput {
  concealed_tiles : Array[@mahjong.Tile]
  melds : Array[@mahjong.Meld]
} derive(Debug, Eq)

///|
/// Create an analysis input without requiring declared melds.
pub fn AnalysisInput::new(
  concealed_tiles : Array[@mahjong.Tile],
  melds? : Array[@mahjong.Meld] = [],
) -> AnalysisInput {
  { concealed_tiles, melds }
}

///|
/// Shanten counts for each supported hand family. A complete hand is `-1`
/// and a tenpai hand is `0`. Special-hand values are absent after a meld.
pub(all) struct ShantenResult {
  minimum : Int
  standard : Int
  seven_pairs : Int?
  thirteen_orphans : Int?
} derive(Debug, Eq)

///|
/// Invalid structural-analysis input.
pub(all) suberror AnalysisError {
  InvalidTile(String)
  TooManyCopies(@mahjong.TileKind, Int)
  InvalidMeld(String)
  InvalidHandSize(Int)
} derive(Debug, Eq)
