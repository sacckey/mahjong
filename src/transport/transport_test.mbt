///|
let pinfu_request : String =
  #|{"apiVersion":1,"hand":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"2m","red":false},{"kind":"3m","red":false},{"kind":"4m","red":false},{"kind":"5m","red":false},{"kind":"6m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"5p","red":false},{"kind":"5p","red":false}],"winningTile":{"kind":"9s","red":false},"melds":[],"doraIndicators":[],"uraDoraIndicators":[]},"context":{"winMethod":"ron","seatWind":"south","roundWind":"east","riichi":"riichi","ippatsu":false,"rinshan":false,"chankan":false,"haitei":false,"houtei":false,"tenhou":false,"chiihou":false,"honba":0,"riichiSticks":0},"rules":"standard"}

///|
let tenpai_analysis_request : String =
  #|{"apiVersion":1,"operation":"calculateShanten","input":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"2m","red":false},{"kind":"3m","red":false},{"kind":"4m","red":false},{"kind":"5m","red":false},{"kind":"6m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"5p","red":false},{"kind":"5p","red":false}],"melds":[]}}

///|
let riichi_kan_analysis_request : String =
  #|{"apiVersion":1,"operation":"canClosedKanAfterRiichi","input":{"concealedTiles":[{"kind":"5m","red":false},{"kind":"5m","red":false},{"kind":"5m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"4p","red":false},{"kind":"5p","red":false},{"kind":"6p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"east","red":false},{"kind":"east","red":false}],"melds":[],"drawnTile":{"kind":"5m","red":false}}}

///|
let five_copy_score_request : String =
  #|{"apiVersion":1,"hand":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"4p","red":false},{"kind":"5p","red":false},{"kind":"6p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"9s","red":false}],"winningTile":{"kind":"1m","red":false},"melds":[],"doraIndicators":[],"uraDoraIndicators":[]},"context":{"winMethod":"ron","seatWind":"south","roundWind":"east","riichi":"riichi","ippatsu":false,"rinshan":false,"chankan":false,"haitei":false,"houtei":false,"tenhou":false,"chiihou":false,"honba":0,"riichiSticks":0},"rules":"standard"}

///|
let five_copy_wait_request : String =
  #|{"apiVersion":1,"operation":"waitingTiles","input":{"concealedTiles":[{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1m","red":false},{"kind":"1p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"4p","red":false},{"kind":"5p","red":false},{"kind":"6p","red":false},{"kind":"7s","red":false},{"kind":"8s","red":false},{"kind":"9s","red":false}],"melds":[]}}

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
test "analysis JSON boundary checks a closed kan after riichi" {
  let response = @transport.analysis_json(riichi_kan_analysis_request)
  assert_true(response.contains("\"ok\":true"))
  assert_true(response.contains("\"result\":true"))
  let missing_draw = @transport.analysis_json(
    riichi_kan_analysis_request.replace(
      old=",\"drawnTile\":{\"kind\":\"5m\",\"red\":false}",
      new="",
    ),
  )
  assert_true(missing_draw.contains("\"code\":\"invalid_request\""))
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

///|
test "JSON boundary accepts unlimited tile copies explicitly" {
  let standard = @transport.score_json(five_copy_score_request)
  assert_true(standard.contains("\"code\":\"too_many_copies\""))
  let score = @transport.score_json(
    five_copy_score_request.replace(
      old="\"rules\":\"standard\"",
      new="\"rules\":\"standard\",\"tileCopyRules\":{\"maxCopiesPerKind\":null}",
    ),
  )
  assert_true(score.contains("\"ok\":true"))
  assert_true(score.contains("\"pair\":\"1m\""))
  assert_true(score.contains("\"kind\":\"triplet\",\"tile\":\"1m\""))
  let standard_waits = @transport.analysis_json(five_copy_wait_request)
  assert_true(standard_waits.contains("\"result\":[]"))
  let unlimited_waits = @transport.analysis_json(
    five_copy_wait_request.replace(
      old="\"input\":",
      new="\"tileCopyRules\":{\"maxCopiesPerKind\":null},\"input\":",
    ),
  )
  assert_true(unlimited_waits.contains("\"result\":[\"1m\"]"))
  let invalid_limit = @transport.analysis_json(
    five_copy_wait_request.replace(
      old="\"input\":",
      new="\"tileCopyRules\":{\"maxCopiesPerKind\":0},\"input\":",
    ),
  )
  assert_true(invalid_limit.contains("\"code\":\"invalid_rule\""))
}

///|
let daisharin_request : String =
  #|{"apiVersion":1,"hand":{"concealedTiles":[{"kind":"2p","red":false},{"kind":"2p","red":false},{"kind":"3p","red":false},{"kind":"3p","red":false},{"kind":"4p","red":false},{"kind":"4p","red":false},{"kind":"5p","red":false},{"kind":"5p","red":false},{"kind":"6p","red":false},{"kind":"6p","red":false},{"kind":"7p","red":false},{"kind":"7p","red":false},{"kind":"8p","red":false}],"winningTile":{"kind":"8p","red":false},"melds":[],"doraIndicators":[],"uraDoraIndicators":[]},"context":{"winMethod":"ron","seatWind":"south","roundWind":"east","riichi":"none","ippatsu":false,"rinshan":false,"chankan":false,"haitei":false,"houtei":false,"tenhou":false,"chiihou":false,"honba":0,"riichiSticks":0},"rules":"standard"}

///|
test "JSON boundary scores local yaku only when requested" {
  let standard = @transport.score_json(daisharin_request)
  assert_true(standard.contains("\"kind\":\"sanbaiman\""))
  assert_false(standard.contains("daisharin"))
  let enabled = @transport.score_json(
    daisharin_request.replace(
      old="\"rules\":\"standard\"",
      new="\"rules\":\"standard\",\"localYaku\":[\"daisharin\"]",
    ),
  )
  assert_true(enabled.contains("\"kind\":\"yakuman\""))
  assert_true(enabled.contains("\"id\":\"daisharin\""))
  let unknown = @transport.score_json(
    daisharin_request.replace(
      old="\"rules\":\"standard\"",
      new="\"rules\":\"standard\",\"localYaku\":[\"renhou\"]",
    ),
  )
  assert_true(unknown.contains("\"code\":\"invalid_request\""))
  assert_true(unknown.contains("unknown local yaku: renhou"))
}
