export const API_VERSION = 1;

const DEFAULT_WASM_URL = new URL("./dist/engine.wasm", import.meta.url);

export class MahjongError extends Error {
  constructor(error) {
    super(error.message);
    this.name = "MahjongError";
    this.code = error.code;
    this.details = error.details;
  }
}

function validateEngine(engine, backend) {
  if (
    typeof engine?.mahjong_api_version !== "function" ||
    typeof engine?.mahjong_score_json !== "function"
  ) {
    throw new TypeError(`${backend} scoring engine has invalid exports`);
  }
  const apiVersion = engine.mahjong_api_version();
  if (apiVersion !== API_VERSION) {
    throw new Error(
      `${backend} scoring engine uses API v${apiVersion}; expected API v${API_VERSION}`,
    );
  }
  if (typeof engine.mahjong_score_json("{") !== "string") {
    throw new TypeError(`${backend} scoring engine cannot exchange strings`);
  }
  return engine;
}

async function readWasm(url) {
  if (
    url.protocol === "file:" &&
    typeof process === "object" &&
    process?.versions?.node
  ) {
    const nodeFs = "node:fs/promises";
    const { readFile } = await import(nodeFs);
    return readFile(url);
  }
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch Wasm-GC engine: ${response.status}`);
  }
  return response.arrayBuffer();
}

async function loadWasmEngine(wasmUrl) {
  const url = wasmUrl instanceof URL ? wasmUrl : new URL(wasmUrl, import.meta.url);
  const bytes = await readWasm(url);
  const { instance } = await WebAssembly.instantiate(bytes, {}, {
    builtins: ["js-string"],
    importedStringConstants: "_",
  });
  return validateEngine(instance.exports, "Wasm-GC");
}

async function loadJavaScriptEngine() {
  const engine = await import("./dist/engine.js");
  return validateEngine(engine, "JavaScript");
}

function decodeResponse(raw) {
  let response;
  try {
    response = JSON.parse(raw);
  } catch (cause) {
    throw new TypeError("Scoring engine returned invalid JSON", { cause });
  }
  if (
    typeof response !== "object" ||
    response === null ||
    response.apiVersion !== API_VERSION ||
    typeof response.ok !== "boolean"
  ) {
    throw new TypeError("Scoring engine returned an invalid response envelope");
  }
  return response;
}

function createCalculatorFromEngine(engine, backend) {
  const scoreJson = (input) => engine.mahjong_score_json(input);
  const scoreResponse = (request) =>
    decodeResponse(scoreJson(JSON.stringify(request)));
  const score = (request) => {
    const response = scoreResponse(request);
    if (!response.ok) throw new MahjongError(response.error);
    return response.result;
  };
  return Object.freeze({
    apiVersion: API_VERSION,
    backend,
    score,
    scoreJson,
    scoreResponse,
  });
}

export async function createCalculator(options = {}) {
  const backend = options.backend ?? "auto";
  const wasmUrl = options.wasmUrl ?? DEFAULT_WASM_URL;
  if (backend === "wasm-gc") {
    return createCalculatorFromEngine(
      await loadWasmEngine(wasmUrl),
      "wasm-gc",
    );
  }
  if (backend === "javascript") {
    return createCalculatorFromEngine(
      await loadJavaScriptEngine(),
      "javascript",
    );
  }
  if (backend !== "auto") {
    throw new TypeError(`Unknown scoring backend: ${backend}`);
  }
  try {
    return createCalculatorFromEngine(
      await loadWasmEngine(wasmUrl),
      "wasm-gc",
    );
  } catch (wasmError) {
    try {
      return createCalculatorFromEngine(
        await loadJavaScriptEngine(),
        "javascript",
      );
    } catch (javascriptError) {
      throw new AggregateError(
        [wasmError, javascriptError],
        "Neither the Wasm-GC nor JavaScript scoring engine could be loaded",
      );
    }
  }
}
