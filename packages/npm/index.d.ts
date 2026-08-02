export const API_VERSION: 1;

export type Backend = "wasm-gc" | "javascript";
export type BackendPreference = "auto" | Backend;

export interface CalculatorOptions {
  backend?: BackendPreference;
  wasmUrl?: string | URL;
}

export type NumberTileRank = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
export type NumberTileSuit = "m" | "p" | "s";
export type NumberTileKind = `${NumberTileRank}${NumberTileSuit}`;
export type HonorTileKind =
  | "east"
  | "south"
  | "west"
  | "north"
  | "white"
  | "green"
  | "red";
export type TileKind = NumberTileKind | HonorTileKind;

export interface Tile {
  kind: TileKind;
  red: boolean;
}

export type MeldKind = "chi" | "pon" | "openKan" | "closedKan" | "addedKan";

export interface Meld {
  kind: MeldKind;
  tiles: Tile[];
}

export interface AnalysisInput {
  /** All concealed tiles currently in the hand. */
  concealedTiles: Tile[];
  melds?: Meld[];
}

export type AnalysisOperation =
  | "calculateShanten"
  | "isTenpai"
  | "waitingTiles";

export interface AnalysisRequest {
  apiVersion: typeof API_VERSION;
  operation: AnalysisOperation;
  input: AnalysisInput;
}

export interface ShantenResult {
  minimum: number;
  standard: number;
  sevenPairs: number | null;
  thirteenOrphans: number | null;
}

export interface Hand {
  /** The concealed tiles without the winning tile. */
  concealedTiles: Tile[];
  winningTile: Tile;
  melds: Meld[];
  doraIndicators: Tile[];
  uraDoraIndicators: Tile[];
}

export type Wind = "east" | "south" | "west" | "north";
export type WinMethod = "ron" | "tsumo";
export type RiichiState = "none" | "riichi" | "doubleRiichi";

export interface WinContext {
  winMethod: WinMethod;
  seatWind: Wind;
  roundWind: Wind;
  riichi: RiichiState;
  ippatsu: boolean;
  rinshan: boolean;
  chankan: boolean;
  haitei: boolean;
  houtei: boolean;
  tenhou: boolean;
  chiihou: boolean;
  honba: number;
  riichiSticks: number;
}

export interface ScoreRequest {
  apiVersion: typeof API_VERSION;
  hand: Hand;
  context: WinContext;
  rules: "standard";
}

export type LimitKind =
  | "belowMangan"
  | "mangan"
  | "haneman"
  | "baiman"
  | "sanbaiman"
  | "yakuman";

export interface Limit {
  kind: LimitKind;
  yakumanMultiplier: number;
}

export type Payment =
  | {
      kind: "ron";
      discarder: number;
    }
  | {
      kind: "dealerTsumo";
      each: number;
    }
  | {
      kind: "nonDealerTsumo";
      dealer: number;
      nonDealerEach: number;
    };

export type YakuId =
  | "riichi"
  | "doubleRiichi"
  | "ippatsu"
  | "menzenTsumo"
  | "tanyao"
  | "pinfu"
  | "iipeikou"
  | "seatWind"
  | "roundWind"
  | "whiteDragon"
  | "greenDragon"
  | "redDragon"
  | "rinshanKaihou"
  | "chankan"
  | "haiteiRaoyue"
  | "houteiRaoyui"
  | "sanshokuDoujun"
  | "ittsu"
  | "chanta"
  | "chiitoitsu"
  | "toitoi"
  | "sanankou"
  | "honroutou"
  | "sanshokuDoukou"
  | "sankantsu"
  | "shousangen"
  | "junchan"
  | "honitsu"
  | "ryanpeikou"
  | "chinitsu"
  | "tenhou"
  | "chiihou"
  | "kokushiMusou"
  | "suuankou"
  | "daisangen"
  | "shousuushi"
  | "daisuushi"
  | "tsuuiisou"
  | "ryuuiisou"
  | "chinroutou"
  | "chuurenPoutou"
  | "suukantsu";

export interface YakuValue {
  id: YakuId;
  han: number;
  yakumanMultiplier: number;
}

export interface BonusHan {
  dora: number;
  uraDora: number;
  akaDora: number;
}

export type FuReason =
  | "base"
  | "menzenRon"
  | "tsumo"
  | "valuePair"
  | "wait"
  | "openTriplet"
  | "closedTriplet"
  | "openQuad"
  | "closedQuad"
  | "openPinfuShape"
  | "sevenPairsFixed";

export interface FuItem {
  reason: FuReason;
  fu: number;
}

export type GroupKind = "sequence" | "triplet" | "quad";

export interface Group {
  kind: GroupKind;
  tile: TileKind;
  open: boolean;
}

export type WaitKind =
  | "ryanmen"
  | "kanchan"
  | "penchan"
  | "tanki"
  | "shanpon"
  | "kokushiSingle"
  | "kokushiThirteenSided";

export type HandShape =
  | {
      kind: "standard";
      pair: TileKind;
      groups: Group[];
      tiles: [];
      wait: Exclude<WaitKind, "kokushiSingle" | "kokushiThirteenSided">;
    }
  | {
      kind: "sevenPairs";
      groups: [];
      tiles: TileKind[];
      wait: "tanki";
    }
  | {
      kind: "thirteenOrphans";
      groups: [];
      tiles: [];
      wait: "kokushiSingle" | "kokushiThirteenSided";
    };

export interface ScoreResult {
  han: number;
  fu: number;
  limit: Limit;
  basePoints: number;
  payment: Payment;
  riichiBonus: number;
  winnerGain: number;
  yaku: YakuValue[];
  bonusHan: BonusHan;
  fuItems: FuItem[];
  shape: HandShape;
}

export type ScoreErrorCode =
  | "invalid_json"
  | "invalid_request"
  | "unsupported_api_version"
  | "invalid_tile"
  | "too_many_copies"
  | "invalid_hand_size"
  | "invalid_meld"
  | "contradictory_context"
  | "not_winning_hand"
  | "invalid_hand_shape"
  | "invalid_rule"
  | "no_yaku";

export interface ScoreError {
  code: ScoreErrorCode;
  message: string;
  details: unknown;
}

export interface ScoreSuccess {
  apiVersion: typeof API_VERSION;
  ok: true;
  result: ScoreResult;
}

export interface ScoreFailure {
  apiVersion: typeof API_VERSION;
  ok: false;
  error: ScoreError;
}

export type ScoreResponse = ScoreSuccess | ScoreFailure;

export interface AnalysisSuccess {
  apiVersion: typeof API_VERSION;
  ok: true;
  result: ShantenResult | boolean | TileKind[];
}

export type AnalysisResponse = AnalysisSuccess | ScoreFailure;

export class MahjongError extends Error {
  readonly code: ScoreErrorCode;
  readonly details: unknown;
  constructor(error: ScoreError);
}

export interface Calculator {
  readonly apiVersion: typeof API_VERSION;
  readonly backend: Backend;
  score(request: ScoreRequest): ScoreResult;
  scoreResponse(request: ScoreRequest): ScoreResponse;
  scoreJson(input: string): string;
  calculateShanten(input: AnalysisInput): ShantenResult;
  isTenpai(input: AnalysisInput): boolean;
  waitingTiles(input: AnalysisInput): TileKind[];
  analysisResponse(request: AnalysisRequest): AnalysisResponse;
  analysisJson(input: string): string;
}

export function createCalculator(options?: CalculatorOptions): Promise<Calculator>;
