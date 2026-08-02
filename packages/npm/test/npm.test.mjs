import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import {
  API_VERSION,
  MahjongError,
  createCalculator,
} from "../index.js";

const tile = (kind, red = false) => ({ kind, red });
const sampleRequest = {
  apiVersion: API_VERSION,
  hand: {
    concealedTiles: [
      "1m",
      "2m",
      "3m",
      "4m",
      "5m",
      "6m",
      "1p",
      "2p",
      "3p",
      "7s",
      "8s",
      "5p",
      "5p",
    ].map((kind) => tile(kind)),
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

const tenpaiInput = {
  concealedTiles: [
    "1m",
    "2m",
    "3m",
    "4m",
    "5m",
    "6m",
    "1p",
    "2p",
    "3p",
    "7s",
    "8s",
    "5p",
    "5p",
  ].map((kind) => tile(kind)),
};

function verifyResult(result) {
  assert.equal(result.han, 2);
  assert.equal(result.fu, 30);
  assert.deepEqual(result.payment, {
    kind: "ron",
    discarder: 2000,
  });
  assert.equal(result.winnerGain, 2000);
}

test("JavaScript backend scores a hand", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  assert.equal(calculator.apiVersion, API_VERSION);
  assert.equal(calculator.backend, "javascript");
  verifyResult(calculator.score(sampleRequest));
});

test("Wasm-GC backend scores a hand", async () => {
  const calculator = await createCalculator({ backend: "wasm-gc" });
  assert.equal(calculator.backend, "wasm-gc");
  verifyResult(calculator.score(sampleRequest));
});

test("automatic backend selection scores a hand", async () => {
  const calculator = await createCalculator();
  assert.match(calculator.backend, /^(wasm-gc|javascript)$/);
  verifyResult(calculator.score(sampleRequest));
});

test("automatic backend selection falls back to JavaScript", async () => {
  const calculator = await createCalculator({
    wasmUrl: new URL("./missing-engine.wasm", import.meta.url),
  });
  assert.equal(calculator.backend, "javascript");
  verifyResult(calculator.score(sampleRequest));
});

test("scoreResponse keeps protocol errors as values", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  const response = calculator.scoreResponse({
    ...sampleRequest,
    apiVersion: 2,
  });
  assert.equal(response.ok, false);
  assert.equal(response.error.code, "unsupported_api_version");
});

test("score throws MahjongError for scoring errors", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  const invalidRequest = {
    ...sampleRequest,
    hand: {
      ...sampleRequest.hand,
      winningTile: tile("1s"),
    },
  };
  assert.throws(
    () => calculator.score(invalidRequest),
    (error) =>
      error instanceof MahjongError && error.code === "not_winning_hand",
  );
});

test("scoreJson exposes the raw JSON boundary", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  const response = JSON.parse(calculator.scoreJson("{"));
  assert.equal(response.ok, false);
  assert.equal(response.error.code, "invalid_json");
});

for (const backend of ["javascript", "wasm-gc"]) {
  test(`${backend} backend analyzes shanten and waits`, async () => {
    const calculator = await createCalculator({ backend });
    assert.deepEqual(calculator.calculateShanten(tenpaiInput), {
      minimum: 0,
      standard: 0,
      sevenPairs: 5,
      thirteenOrphans: 11,
    });
    assert.equal(calculator.isTenpai(tenpaiInput), true);
    assert.deepEqual(calculator.waitingTiles(tenpaiInput), ["6s", "9s"]);
  });
}

test("analysisResponse keeps analysis errors as values", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  const response = calculator.analysisResponse({
    apiVersion: API_VERSION,
    operation: "waitingTiles",
    input: {
      concealedTiles: tenpaiInput.concealedTiles.slice(0, 12),
    },
  });
  assert.equal(response.ok, false);
  assert.equal(response.error.code, "invalid_hand_size");
});

test("analysis methods throw MahjongError for invalid hands", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  assert.throws(
    () =>
      calculator.calculateShanten({
        concealedTiles: tenpaiInput.concealedTiles.slice(0, 12),
      }),
    (error) =>
      error instanceof MahjongError && error.code === "invalid_hand_size",
  );
});

test("analysisJson exposes the raw JSON boundary", async () => {
  const calculator = await createCalculator({ backend: "javascript" });
  const response = JSON.parse(calculator.analysisJson("{"));
  assert.equal(response.ok, false);
  assert.equal(response.error.code, "invalid_json");
});

test("an invalid import.meta.url does not break the JavaScript backend", async () => {
  const source = await readFile(new URL("../index.js", import.meta.url), "utf8");
  const engineProperty = "__mahjongWorkerdTestEngine";
  globalThis[engineProperty] = {
    mahjong_api_version: () => API_VERSION,
    mahjong_score_json: () =>
      JSON.stringify({ apiVersion: API_VERSION, ok: false, error: {} }),
    mahjong_analysis_json: () =>
      JSON.stringify({ apiVersion: API_VERSION, ok: false, error: {} }),
  };
  try {
    const workerdLikeSource = source
      .replaceAll("import.meta.url", '""')
      .replace(
        'await import("./dist/engine.js")',
        `globalThis.${engineProperty}`,
      );
    const moduleUrl = `data:text/javascript;base64,${Buffer.from(
      workerdLikeSource,
    ).toString("base64")}`;
    const workerdLikeModule = await import(moduleUrl);
    const javascript = await workerdLikeModule.createCalculator({
      backend: "javascript",
    });
    assert.equal(javascript.backend, "javascript");
    const automatic = await workerdLikeModule.createCalculator();
    assert.equal(automatic.backend, "javascript");
  } finally {
    delete globalThis[engineProperty];
  }
});
