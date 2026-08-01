import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  mahjong_api_version as jsApiVersion,
  mahjong_score_json as jsScoreJson,
} from "../../_build/js/debug/build/ffi/ffi.js";
import { tileAssetRevision, tileAssetUrl, tileFrontAssetUrl } from "./tile-assets.js";
import { sortHandTiles } from "./tile-order.js";

const tile = (kind, red = false) => ({ kind, red });
const sampleRequest = {
  apiVersion: 1,
  hand: {
    concealedTiles: ["1m", "2m", "3m", "4m", "5m", "6m", "1p", "2p", "3p", "7s", "8s", "5p", "5p"].map((kind) => tile(kind)),
    winningTile: tile("9s"),
    melds: [],
    doraIndicators: [],
    uraDoraIndicators: [],
  },
  context: {
    winMethod: "ron",
    seatWind: "south",
    roundWind: "east",
    riichi: "riichi",
    ippatsu: false,
    rinshan: false,
    chankan: false,
    haitei: false,
    houtei: false,
    tenhou: false,
    chiihou: false,
    honba: 0,
    riichiSticks: 0,
  },
  rules: "standard",
};

assert.equal(tileAssetRevision, "26e127ba2117f45cdce5ea0225748cc0cfad3169");
assert.match(tileFrontAssetUrl, /\/Regular\/Front\.svg$/);
assert.match(tileAssetUrl(tile("1m")), /\/Regular\/Man1\.svg$/);
assert.match(tileAssetUrl(tile("5p", true)), /\/Regular\/Pin5-Dora\.svg$/);
assert.match(tileAssetUrl(tile("9s")), /\/Regular\/Sou9\.svg$/);
assert.match(tileAssetUrl(tile("east")), /\/Regular\/Ton\.svg$/);
assert.match(tileAssetUrl(tile("red")), /\/Regular\/Chun\.svg$/);
assert.deepEqual(
  sortHandTiles([
    tile("red"),
    tile("5m", true),
    tile("1s"),
    tile("5m"),
    tile("east"),
    tile("9p"),
    tile("1m"),
  ]),
  [tile("1m"), tile("5m"), tile("5m", true), tile("9p"), tile("1s"), tile("east"), tile("red")],
);

function verifyEngine(apiVersion, scoreJson, backend) {
  assert.equal(apiVersion(), 1, `${backend}: API version`);
  const response = JSON.parse(scoreJson("{"));
  assert.equal(response.apiVersion, 1, `${backend}: response API version`);
  assert.equal(response.ok, false, `${backend}: error envelope`);
  assert.equal(response.error.code, "invalid_json", `${backend}: error code`);
  const score = JSON.parse(scoreJson(JSON.stringify(sampleRequest)));
  assert.equal(score.ok, true, `${backend}: score envelope`);
  assert.equal(score.result.han, 2, `${backend}: han`);
  assert.equal(score.result.fu, 30, `${backend}: fu`);
  assert.equal(score.result.payment.discarder, 2000, `${backend}: payment`);
}

verifyEngine(jsApiVersion, jsScoreJson, "JavaScript");

const wasmBytes = await readFile(new URL("../../_build/wasm-gc/debug/build/ffi/ffi.wasm", import.meta.url));
const { instance } = await WebAssembly.instantiate(wasmBytes, {}, {
  builtins: ["js-string"],
  importedStringConstants: "_",
});
verifyEngine(instance.exports.mahjong_api_version, instance.exports.mahjong_score_json, "Wasm-GC");

console.log("Browser boundary smoke test passed for JavaScript and Wasm-GC.");
