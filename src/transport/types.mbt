///|
#derive(FromJson)
priv struct TileDto {
  kind : String
  red : Bool
}

///|
#derive(FromJson)
priv struct MeldDto {
  kind : String
  tiles : Array[TileDto]
}

///|
#derive(FromJson)
priv struct HandDto {
  concealedTiles : Array[TileDto]
  winningTile : TileDto
  melds : Array[MeldDto]
  doraIndicators : Array[TileDto]
  uraDoraIndicators : Array[TileDto]
}

///|
#derive(FromJson)
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
  honba : Int32
  riichiSticks : Int32
}

///|
#derive(FromJson)
priv struct TileCopyRulesDto {
  maxCopiesPerKind : Json
}

///|
#derive(FromJson)
priv struct ScoreRequestDto {
  apiVersion : Int32
  hand : HandDto
  context : ContextDto
  rules : String
  localYaku : Array[String]?
  tileCopyRules : TileCopyRulesDto?
}

///|
#derive(FromJson)
priv struct AnalysisInputDto {
  concealedTiles : Array[TileDto]
  melds : Array[MeldDto]
  drawnTile : TileDto?
}

///|
#derive(FromJson)
priv struct AnalysisRequestDto {
  apiVersion : Int32
  operation : String
  input : AnalysisInputDto
  tileCopyRules : TileCopyRulesDto?
}

///|
#derive(ToJson)
priv struct YakuDto {
  id : String
  han : Int32
  yakumanMultiplier : Int32
}

///|
#derive(ToJson)
priv struct BonusHanDto {
  dora : Int32
  uraDora : Int32
  akaDora : Int32
}

///|
#derive(ToJson)
priv struct FuItemDto {
  reason : String
  fu : Int32
}

///|
#derive(ToJson)
priv struct GroupDto {
  kind : String
  tile : String
  open : Bool
}

///|
#derive(ToJson)
priv struct ShapeDto {
  kind : String
  pair : String?
  groups : Array[GroupDto]
  tiles : Array[String]
  wait : String
}

///|
#derive(ToJson)
priv struct LimitDto {
  kind : String
  yakumanMultiplier : Int32
}

///|
#derive(ToJson)
priv struct PaymentDto {
  kind : String
  discarder : Int32?
  each : Int32?
  dealer : Int32?
  nonDealerEach : Int32?
}

///|
#derive(ToJson)
priv struct ScoreResultDto {
  han : Int32
  fu : Int32
  limit : LimitDto
  basePoints : Int32
  payment : PaymentDto
  riichiBonus : Int32
  winnerGain : Int32
  yaku : Array[YakuDto]
  bonusHan : BonusHanDto
  fuItems : Array[FuItemDto]
  shape : ShapeDto
}

///|
#derive(ToJson)
priv struct ShantenResultDto {
  minimum : Int32
  standard : Int32
  sevenPairs : Int32?
  thirteenOrphans : Int32?
}

///|
#derive(ToJson)
priv struct SuccessEnvelope {
  apiVersion : Int32
  ok : Bool
  result : ScoreResultDto
}

///|
#derive(ToJson)
priv struct AnalysisSuccessEnvelope {
  apiVersion : Int32
  ok : Bool
  result : Json
}

///|
#derive(ToJson)
priv struct ErrorDto {
  code : String
  message : String
  details : Json
}

///|
#derive(ToJson)
priv struct ErrorEnvelope {
  apiVersion : Int32
  ok : Bool
  error : ErrorDto
}

///|
#derive(Debug)
priv suberror RequestError {
  InvalidRequest(String)
}
