///|
fn tile_kind_from_code(code : String) -> @mahjong.TileKind raise RequestError {
  match code {
    "1m" => @mahjong.Numbered(@mahjong.Man, 1)
    "2m" => @mahjong.Numbered(@mahjong.Man, 2)
    "3m" => @mahjong.Numbered(@mahjong.Man, 3)
    "4m" => @mahjong.Numbered(@mahjong.Man, 4)
    "5m" => @mahjong.Numbered(@mahjong.Man, 5)
    "6m" => @mahjong.Numbered(@mahjong.Man, 6)
    "7m" => @mahjong.Numbered(@mahjong.Man, 7)
    "8m" => @mahjong.Numbered(@mahjong.Man, 8)
    "9m" => @mahjong.Numbered(@mahjong.Man, 9)
    "1p" => @mahjong.Numbered(@mahjong.Pin, 1)
    "2p" => @mahjong.Numbered(@mahjong.Pin, 2)
    "3p" => @mahjong.Numbered(@mahjong.Pin, 3)
    "4p" => @mahjong.Numbered(@mahjong.Pin, 4)
    "5p" => @mahjong.Numbered(@mahjong.Pin, 5)
    "6p" => @mahjong.Numbered(@mahjong.Pin, 6)
    "7p" => @mahjong.Numbered(@mahjong.Pin, 7)
    "8p" => @mahjong.Numbered(@mahjong.Pin, 8)
    "9p" => @mahjong.Numbered(@mahjong.Pin, 9)
    "1s" => @mahjong.Numbered(@mahjong.Sou, 1)
    "2s" => @mahjong.Numbered(@mahjong.Sou, 2)
    "3s" => @mahjong.Numbered(@mahjong.Sou, 3)
    "4s" => @mahjong.Numbered(@mahjong.Sou, 4)
    "5s" => @mahjong.Numbered(@mahjong.Sou, 5)
    "6s" => @mahjong.Numbered(@mahjong.Sou, 6)
    "7s" => @mahjong.Numbered(@mahjong.Sou, 7)
    "8s" => @mahjong.Numbered(@mahjong.Sou, 8)
    "9s" => @mahjong.Numbered(@mahjong.Sou, 9)
    "east" => @mahjong.HonorTile(@mahjong.East)
    "south" => @mahjong.HonorTile(@mahjong.South)
    "west" => @mahjong.HonorTile(@mahjong.West)
    "north" => @mahjong.HonorTile(@mahjong.North)
    "white" => @mahjong.HonorTile(@mahjong.White)
    "green" => @mahjong.HonorTile(@mahjong.Green)
    "red" => @mahjong.HonorTile(@mahjong.Red)
    _ => raise InvalidRequest("unknown tile kind: \{code}")
  }
}

///|
fn tile_from_dto(dto : TileDto) -> @mahjong.Tile raise RequestError {
  { kind: tile_kind_from_code(dto.kind), is_red: dto.red }
}

///|
fn meld_kind_from_string(kind : String) -> @mahjong.MeldKind raise RequestError {
  match kind {
    "chi" => @mahjong.Chi
    "pon" => @mahjong.Pon
    "openKan" => @mahjong.OpenKan
    "closedKan" => @mahjong.ClosedKan
    "addedKan" => @mahjong.AddedKan
    _ => raise InvalidRequest("unknown meld kind: \{kind}")
  }
}

///|
fn meld_from_dto(dto : MeldDto) -> @mahjong.Meld raise RequestError {
  { kind: meld_kind_from_string(dto.kind), tiles: dto.tiles.map(tile_from_dto) }
}

///|
fn wind_from_string(wind : String) -> @mahjong.Wind raise RequestError {
  match wind {
    "east" => @mahjong.East
    "south" => @mahjong.South
    "west" => @mahjong.West
    "north" => @mahjong.North
    _ => raise InvalidRequest("unknown wind: \{wind}")
  }
}

///|
fn win_method_from_string(
  win_method : String,
) -> @mahjong.WinMethod raise RequestError {
  match win_method {
    "ron" => @mahjong.Ron
    "tsumo" => @mahjong.Tsumo
    _ => raise InvalidRequest("unknown win method: \{win_method}")
  }
}

///|
fn riichi_from_string(
  riichi : String,
) -> @mahjong.RiichiState raise RequestError {
  match riichi {
    "none" => @mahjong.NoRiichi
    "riichi" => @mahjong.Riichi
    "doubleRiichi" => @mahjong.DoubleRiichi
    _ => raise InvalidRequest("unknown riichi state: \{riichi}")
  }
}

///|
fn context_from_dto(dto : ContextDto) -> @mahjong.WinContext raise RequestError {
  {
    win_method: win_method_from_string(dto.winMethod),
    seat_wind: wind_from_string(dto.seatWind),
    round_wind: wind_from_string(dto.roundWind),
    riichi: riichi_from_string(dto.riichi),
    ippatsu: dto.ippatsu,
    rinshan: dto.rinshan,
    chankan: dto.chankan,
    haitei: dto.haitei,
    houtei: dto.houtei,
    tenhou: dto.tenhou,
    chiihou: dto.chiihou,
    honba: dto.honba,
    riichi_sticks: dto.riichiSticks,
  }
}

///|
fn hand_from_request(
  request : ScoreRequestDto,
) -> @mahjong.HandInput raise RequestError {
  if request.rules != "standard" {
    raise InvalidRequest("unsupported rules: \{request.rules}")
  }
  {
    concealed_tiles: request.hand.concealedTiles.map(tile_from_dto),
    winning_tile: tile_from_dto(request.hand.winningTile),
    melds: request.hand.melds.map(meld_from_dto),
    dora_indicators: request.hand.doraIndicators.map(tile_from_dto),
    ura_dora_indicators: request.hand.uraDoraIndicators.map(tile_from_dto),
    context: context_from_dto(request.context),
  }
}

///|
fn analysis_input_from_request(
  request : AnalysisRequestDto,
) -> @analysis.AnalysisInput raise RequestError {
  @analysis.AnalysisInput::new(
    request.input.concealedTiles.map(tile_from_dto),
    melds=request.input.melds.map(meld_from_dto),
  )
}
