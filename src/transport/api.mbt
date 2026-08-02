///|
const API_VERSION : Int = 1

///|
fn encode_error(code : String, message : String, details : Json) -> String {
  @json.to_json(ErrorEnvelope::{
    apiVersion: API_VERSION,
    ok: false,
    error: { code, message, details },
  }).stringify()
}

///|
fn score_error_response(error : @mahjong.ScoreError) -> String {
  match error {
    @mahjong.InvalidTile(message) =>
      encode_error(
        "invalid_tile",
        "A tile is invalid.",
        Json::object({ "reason": Json::string(message) }),
      )
    @mahjong.TooManyCopies(kind, count) =>
      encode_error(
        "too_many_copies",
        "The hand contains too many copies of a tile.",
        Json::object({
          "tile": Json::string(tile_kind_code(kind)),
          "count": Json::Json(count),
        }),
      )
    @mahjong.InvalidHandSize(size) =>
      encode_error(
        "invalid_hand_size",
        "The number of tiles does not match the meld count.",
        Json::object({ "size": Json::Json(size) }),
      )
    @mahjong.InvalidMeld(message) =>
      encode_error(
        "invalid_meld",
        "A meld is invalid.",
        Json::object({ "reason": Json::string(message) }),
      )
    @mahjong.ContradictoryContext(message) =>
      encode_error(
        "contradictory_context",
        "The winning conditions contradict each other.",
        Json::object({ "reason": Json::string(message) }),
      )
    @mahjong.NotWinningHand =>
      encode_error(
        "not_winning_hand",
        "The tiles do not form a winning hand.",
        Json::null(),
      )
    @mahjong.InvalidHandShape =>
      encode_error(
        "invalid_hand_shape",
        "The winning hand has no valid structural interpretation.",
        Json::null(),
      )
    @mahjong.InvalidRule(message) =>
      encode_error(
        "invalid_rule",
        "The rules configuration is invalid.",
        Json::object({ "reason": Json::string(message) }),
      )
    @mahjong.NoYaku =>
      encode_error("no_yaku", "The winning hand has no yaku.", Json::null())
  }
}

///|
fn analysis_error_response(error : @analysis.AnalysisError) -> String {
  match error {
    @analysis.InvalidTile(message) =>
      encode_error(
        "invalid_tile",
        "A tile is invalid.",
        Json::object({ "reason": Json::string(message) }),
      )
    @analysis.TooManyCopies(kind, count) =>
      encode_error(
        "too_many_copies",
        "The hand contains too many copies of a tile.",
        Json::object({
          "tile": Json::string(tile_kind_code(kind)),
          "count": Json::Json(count),
        }),
      )
    @analysis.InvalidMeld(message) =>
      encode_error(
        "invalid_meld",
        "A meld is invalid.",
        Json::object({ "reason": Json::string(message) }),
      )
    @analysis.InvalidHandSize(size) =>
      encode_error(
        "invalid_hand_size",
        "The number of structural tiles must be thirteen or fourteen.",
        Json::object({ "size": Json::Json(size) }),
      )
  }
}

///|
fn encode_analysis_success(result : Json) -> String {
  @json.to_json(AnalysisSuccessEnvelope::{
    apiVersion: API_VERSION,
    ok: true,
    result,
  }).stringify()
}

///|
/// Return the version of the JSON protocol.
pub fn api_version() -> Int {
  API_VERSION
}

///|
/// Score one hand through a target-independent JSON boundary.
///
/// This function never raises. Both successful results and errors are returned
/// as versioned JSON envelopes.
pub fn score_json(input : String) -> String {
  let parsed = @json.parse(input) catch {
    _ =>
      return encode_error(
        "invalid_json",
        "The input is not valid JSON.",
        Json::null(),
      )
  }
  let request : ScoreRequestDto = @json.from_json(parsed) catch {
    _ =>
      return encode_error(
        "invalid_request",
        "The JSON value does not match the scoring request schema.",
        Json::null(),
      )
  }
  if request.apiVersion != API_VERSION {
    return encode_error(
      "unsupported_api_version",
      "The requested API version is not supported.",
      Json::object({
        "requested": Json::Json(request.apiVersion),
        "supported": Json::Json(API_VERSION),
      }),
    )
  }
  let hand = hand_from_request(request) catch {
    InvalidRequest(message) =>
      return encode_error(
        "invalid_request",
        "The scoring request contains an unsupported value.",
        Json::object({ "reason": Json::string(message) }),
      )
  }
  let result = @mahjong.score_standard(hand) catch {
    error => return score_error_response(error)
  }
  @json.to_json(SuccessEnvelope::{
    apiVersion: API_VERSION,
    ok: true,
    result: score_result_dto(result),
  }).stringify()
}

///|
/// Analyze a hand through a target-independent JSON boundary.
///
/// Supported operations are `calculateShanten`, `isTenpai`, and
/// `waitingTiles`. This function never raises.
pub fn analysis_json(input : String) -> String {
  let parsed = @json.parse(input) catch {
    _ =>
      return encode_error(
        "invalid_json",
        "The input is not valid JSON.",
        Json::null(),
      )
  }
  let request : AnalysisRequestDto = @json.from_json(parsed) catch {
    _ =>
      return encode_error(
        "invalid_request",
        "The JSON value does not match the analysis request schema.",
        Json::null(),
      )
  }
  if request.apiVersion != API_VERSION {
    return encode_error(
      "unsupported_api_version",
      "The requested API version is not supported.",
      Json::object({
        "requested": Json::Json(request.apiVersion),
        "supported": Json::Json(API_VERSION),
      }),
    )
  }
  let analysis_input = analysis_input_from_request(request) catch {
    InvalidRequest(message) =>
      return encode_error(
        "invalid_request",
        "The analysis request contains an unsupported value.",
        Json::object({ "reason": Json::string(message) }),
      )
  }
  match request.operation {
    "calculateShanten" => {
      let result = @analysis.calculate_shanten(analysis_input) catch {
        error => return analysis_error_response(error)
      }
      encode_analysis_success(@json.to_json(shanten_result_dto(result)))
    }
    "isTenpai" => {
      let result = @analysis.is_tenpai(analysis_input) catch {
        error => return analysis_error_response(error)
      }
      encode_analysis_success(@json.to_json(result))
    }
    "waitingTiles" => {
      let result = @analysis.waiting_tiles(analysis_input) catch {
        error => return analysis_error_response(error)
      }
      encode_analysis_success(@json.to_json(result.map(tile_kind_code)))
    }
    operation =>
      encode_error(
        "invalid_request",
        "The analysis operation is not supported.",
        Json::object({ "operation": Json::string(operation) }),
      )
  }
}
