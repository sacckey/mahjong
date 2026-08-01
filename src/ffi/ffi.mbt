///|
/// Return the JSON protocol version to a foreign caller.
pub fn api_version() -> Int {
  @transport.api_version()
}

///|
/// Score a hand supplied as JSON and return a JSON success or error envelope.
pub fn score_json(input : String) -> String {
  @transport.score_json(input)
}
