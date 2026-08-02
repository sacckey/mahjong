///|
let pinfu_request : String =
  #|{"apiVersion":1,"hand":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"2m","red":false},{"kind":"3m","red":false},{"kind":"4m","red":false},{"kind":"5m","red":false},{"kind":"6m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"5p","red":false},{"kind":"5p","red":false}],"winningTile":{"kind":"9s","red":false},"melds":[],"doraIndicators":[],"uraDoraIndicators":[]},"context":{"winMethod":"ron","seatWind":"south","roundWind":"east","riichi":"riichi","ippatsu":false,"rinshan":false,"chankan":false,"haitei":false,"houtei":false,"tenhou":false,"chiihou":false,"honba":0,"riichiSticks":0},"rules":"standard"}

///|
let tenpai_analysis_request : String =
  #|{"apiVersion":1,"operation":"calculateShanten","input":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"2m","red":false},{"kind":"3m","red":false},{"kind":"4m","red":false},{"kind":"5m","red":false},{"kind":"6m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"5p","red":false},{"kind":"5p","red":false}],"melds":[]}}

///|
test "JSON boundary returns a complete score" {
  let response = @transport.score_json(pinfu_request)
  assert_true(response.contains("\"apiVersion\":1"))
  assert_true(response.contains("\"ok\":true"))
  assert_true(response.contains("\"han\":2"))
  assert_true(response.contains("\"fu\":30"))
  assert_true(response.contains("\"discarder\":2000"))
  assert_true(response.contains("\"winnerGain\":2000"))
  assert_true(response.contains("\"id\":\"riichi\""))
  assert_true(response.contains("\"id\":\"pinfu\""))
}

///|
test "JSON boundary reports invalid JSON without raising" {
  let response = @transport.score_json("{")
  assert_true(response.contains("\"ok\":false"))
  assert_true(response.contains("\"code\":\"invalid_json\""))
}

///|
test "JSON boundary rejects unsupported API versions" {
  let response = @transport.score_json(
    pinfu_request.replace(old="\"apiVersion\":1", new="\"apiVersion\":2"),
  )
  assert_true(response.contains("\"code\":\"unsupported_api_version\""))
  assert_true(response.contains("\"requested\":2"))
  assert_true(response.contains("\"supported\":1"))
}

///|
test "JSON boundary rejects unsupported tile codes" {
  let response = @transport.score_json(
    pinfu_request.replace(old="\"kind\":\"1m\"", new="\"kind\":\"0m\""),
  )
  assert_true(response.contains("\"code\":\"invalid_request\""))
  assert_true(response.contains("unknown tile kind: 0m"))
}

///|
test "analysis JSON boundary calculates shanten" {
  let response = @transport.analysis_json(tenpai_analysis_request)
  assert_true(response.contains("\"apiVersion\":1"))
  assert_true(response.contains("\"ok\":true"))
  assert_true(response.contains("\"minimum\":0"))
  assert_true(response.contains("\"standard\":0"))
}

///|
test "analysis JSON boundary reports tenpai and waiting tiles" {
  let tenpai = @transport.analysis_json(
    tenpai_analysis_request.replace(
      old="\"operation\":\"calculateShanten\"",
      new="\"operation\":\"isTenpai\"",
    ),
  )
  assert_true(tenpai.contains("\"result\":true"))
  let waits = @transport.analysis_json(
    tenpai_analysis_request.replace(
      old="\"operation\":\"calculateShanten\"",
      new="\"operation\":\"waitingTiles\"",
    ),
  )
  assert_true(waits.contains("\"result\":[\"6s\",\"9s\"]"))
}

///|
test "analysis JSON boundary returns protocol and analysis errors" {
  let invalid_operation = @transport.analysis_json(
    tenpai_analysis_request.replace(
      old="\"operation\":\"calculateShanten\"",
      new="\"operation\":\"unknown\"",
    ),
  )
  assert_true(invalid_operation.contains("\"code\":\"invalid_request\""))
  let invalid_size = @transport.analysis_json(
    tenpai_analysis_request.replace(
      old="{\"kind\":\"5p\",\"red\":false},{\"kind\":\"5p\",\"red\":false}",
      new="{\"kind\":\"5p\",\"red\":false}",
    ),
  )
  assert_true(invalid_size.contains("\"code\":\"invalid_hand_size\""))
}
