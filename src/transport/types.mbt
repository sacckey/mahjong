///|
priv struct TileDto {
  kind : String
  red : Bool
} derive(FromJson)

///|
priv struct MeldDto {
  kind : String
  tiles : Array[TileDto]
} derive(FromJson)

///|
priv struct HandDto {
  concealedTiles : Array[TileDto]
  winningTile : TileDto
  melds : Array[MeldDto]
  doraIndicators : Array[TileDto]
  uraDoraIndicators : Array[TileDto]
} derive(FromJson)

///|
priv struct ContextDto {
  winMethod : String
  seatWind : String
  roundWind : String
  riichi : String
  ippatsu : Bool
  rinshan : Bool
  chankan : Bool
  haitei : Bool
  houtei : Bool
  tenhou : Bool
  chiihou : Bool
  honba : Int
  riichiSticks : Int
} derive(FromJson)

///|
priv struct ScoreRequestDto {
  apiVersion : Int
  hand : HandDto
  context : ContextDto
  rules : String
} derive(FromJson)

///|
priv struct YakuDto {
  id : String
  han : Int
  yakumanMultiplier : Int
} derive(ToJson)

///|
priv struct BonusHanDto {
  dora : Int
  uraDora : Int
  akaDora : Int
} derive(ToJson)

///|
priv struct FuItemDto {
  reason : String
  fu : Int
} derive(ToJson)

///|
priv struct GroupDto {
  kind : String
  tile : String
  open : Bool
} derive(ToJson)

///|
priv struct ShapeDto {
  kind : String
  pair : String?
  groups : Array[GroupDto]
  tiles : Array[String]
  wait : String
} derive(ToJson)

///|
priv struct LimitDto {
  kind : String
  yakumanMultiplier : Int
} derive(ToJson)

///|
priv struct PaymentDto {
  kind : String
  discarder : Int?
  each : Int?
  dealer : Int?
  nonDealerEach : Int?
} derive(ToJson)

///|
priv struct ScoreResultDto {
  han : Int
  fu : Int
  limit : LimitDto
  basePoints : Int
  payment : PaymentDto
  riichiBonus : Int
  winnerGain : Int
  yaku : Array[YakuDto]
  bonusHan : BonusHanDto
  fuItems : Array[FuItemDto]
  shape : ShapeDto
} derive(ToJson)

///|
priv struct SuccessEnvelope {
  apiVersion : Int
  ok : Bool
  result : ScoreResultDto
} derive(ToJson)

///|
priv struct ErrorDto {
  code : String
  message : String
  details : Json
} derive(ToJson)

///|
priv struct ErrorEnvelope {
  apiVersion : Int
  ok : Bool
  error : ErrorDto
} derive(ToJson)

///|
priv suberror RequestError {
  InvalidRequest(String)
} derive(Debug)
