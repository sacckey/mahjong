import { tileAssetUrl } from "./tile-assets.js";

const tileGroups = [
  Array.from({ length: 9 }, (_, index) => ({ kind: `${index + 1}m`, red: false })),
  [{ kind: "5m", red: true }],
  Array.from({ length: 9 }, (_, index) => ({ kind: `${index + 1}p`, red: false })),
  [{ kind: "5p", red: true }],
  Array.from({ length: 9 }, (_, index) => ({ kind: `${index + 1}s`, red: false })),
  [{ kind: "5s", red: true }],
  ["east", "south", "west", "north", "white", "green", "red"].map((kind) => ({ kind, red: false })),
];

const honorLabels = {
  east: "東",
  south: "南",
  west: "西",
  north: "北",
  white: "白",
  green: "發",
  red: "中",
};

const meldLabels = {
  chi: "チー",
  pon: "ポン",
  openKan: "明槓",
  closedKan: "暗槓",
  addedKan: "加槓",
};

const yakuLabels = {
  riichi: "立直", doubleRiichi: "ダブル立直", ippatsu: "一発", menzenTsumo: "門前清自摸和",
  tanyao: "断么九", pinfu: "平和", iipeikou: "一盃口", seatWind: "自風牌", roundWind: "場風牌",
  whiteDragon: "白", greenDragon: "發", redDragon: "中", rinshanKaihou: "嶺上開花", chankan: "槍槓",
  haiteiRaoyue: "海底摸月", houteiRaoyui: "河底撈魚", sanshokuDoujun: "三色同順", ittsu: "一気通貫",
  chanta: "混全帯么九", chiitoitsu: "七対子", toitoi: "対々和", sanankou: "三暗刻", honroutou: "混老頭",
  sanshokuDoukou: "三色同刻", sankantsu: "三槓子", shousangen: "小三元", junchan: "純全帯么九",
  honitsu: "混一色", ryanpeikou: "二盃口", chinitsu: "清一色", tenhou: "天和", chiihou: "地和",
  kokushiMusou: "国士無双", suuankou: "四暗刻", daisangen: "大三元", shousuushi: "小四喜",
  daisuushi: "大四喜", tsuuiisou: "字一色", ryuuiisou: "緑一色", chinroutou: "清老頭",
  chuurenPoutou: "九蓮宝燈", suukantsu: "四槓子",
};

const limitLabels = {
  belowMangan: "", mangan: "満貫", haneman: "跳満", baiman: "倍満", sanbaiman: "三倍満", yakuman: "役満",
};

const errorLabels = {
  invalid_json: "JSONを読み取れませんでした。",
  invalid_request: "入力形式に誤りがあります。",
  unsupported_api_version: "対応していないAPIバージョンです。",
  invalid_tile: "不正な牌が含まれています。",
  too_many_copies: "同じ牌が5枚以上あります。",
  invalid_hand_size: "手牌と鳴きの枚数が合っていません。",
  invalid_meld: "鳴きまたは槓の形が正しくありません。",
  contradictory_context: "同時に成立しない和了条件があります。",
  not_winning_hand: "和了形になっていません。",
  invalid_hand_shape: "和了形を解釈できませんでした。",
  invalid_rule: "ルール設定が正しくありません。",
  no_yaku: "役がありません。",
};

const state = {
  concealed: [],
  winning: null,
  melds: [],
  dora: [],
  ura: [],
  target: "concealed",
  meldDraft: [],
  engine: null,
  backend: null,
};

const elements = Object.fromEntries([
  "status-dot", "runtime-status", "concealed-count", "concealed-tiles", "winning-tile", "meld-count", "melds",
  "dora-tiles", "ura-tiles", "meld-builder", "meld-kind", "meld-draft", "clear-meld-draft", "tile-palette",
  "sample-button", "reset-button", "win-method", "seat-wind", "round-wind", "riichi", "honba", "riichi-sticks",
  "ippatsu", "rinshan", "chankan", "haitei", "houtei", "tenhou", "chiihou", "calculate-button", "input-hint",
  "result-placeholder", "result-content", "request-json", "response-json",
].map((id) => [id, document.getElementById(id)]));

const copyTile = (tile) => ({ kind: tile.kind, red: tile.red });
const expectedConcealedCount = () => 13 - state.melds.length * 3;
const meldTileCount = () => elements["meld-kind"].value === "chi" || elements["meld-kind"].value === "pon" ? 3 : 4;

function tilePresentation(tile) {
  if (honorLabels[tile.kind]) {
    return {
      text: honorLabels[tile.kind],
      mark: "",
      className: `honor ${tile.kind === "green" ? "green-dragon" : tile.kind === "red" ? "red-dragon" : ""}`,
      label: `${honorLabels[tile.kind]}牌`,
    };
  }
  const rank = tile.kind[0];
  const suit = tile.kind[1];
  const suitLabels = { m: "萬", p: "筒", s: "索" };
  return {
    text: rank,
    mark: suitLabels[suit],
    className: `${suit === "s" ? "sou" : suit === "p" ? "pin" : "man"} ${tile.red ? "red-five" : ""}`,
    label: `${tile.red ? "赤" : ""}${rank}${suitLabels[suit]}`,
  };
}

function tileButton(tile, onClick, extraClass = "") {
  const view = tilePresentation(tile);
  const button = document.createElement("button");
  button.type = "button";
  button.className = `tile ${view.className} ${extraClass}`;
  button.setAttribute("aria-label", view.label);
  button.title = view.label;
  const face = document.createElement("span");
  face.className = "tile-fallback";
  face.textContent = view.text;
  button.append(face);
  if (view.mark) {
    const mark = document.createElement("span");
    mark.className = "suit-mark";
    mark.textContent = view.mark;
    button.append(mark);
  }
  const image = document.createElement("img");
  image.alt = "";
  image.decoding = "async";
  image.draggable = false;
  image.referrerPolicy = "no-referrer";
  image.addEventListener("load", () => button.classList.add("tile-image-loaded"));
  image.addEventListener("error", () => image.remove());
  image.src = tileAssetUrl(tile);
  button.append(image);
  button.addEventListener("click", onClick);
  return button;
}

function renderTileList(container, tiles, removeAt) {
  container.replaceChildren();
  container.classList.toggle("empty", tiles.length === 0);
  tiles.forEach((tile, index) => container.append(tileButton(tile, () => removeAt(index))));
}

function renderMelds() {
  elements.melds.replaceChildren();
  elements.melds.classList.toggle("empty", state.melds.length === 0);
  state.melds.forEach((meld, meldIndex) => {
    const group = document.createElement("div");
    group.className = "meld";
    group.dataset.label = meldLabels[meld.kind];
    meld.tiles.forEach((tile) => group.append(tileButton(tile, () => {
      state.melds.splice(meldIndex, 1);
      render();
    })));
    group.title = "クリックしてこの組を削除";
    elements.melds.append(group);
  });
}

function renderMeldDraft() {
  const count = meldTileCount();
  if (state.meldDraft.length === 0) {
    elements["meld-draft"].textContent = `牌を${count}枚選んでください`;
    return;
  }
  const labels = state.meldDraft.map((tile) => tilePresentation(tile).label).join("・");
  elements["meld-draft"].textContent = `${labels}（${state.meldDraft.length} / ${count}枚）`;
}

function renderPalette() {
  elements["tile-palette"].replaceChildren();
  tileGroups.forEach((group, groupIndex) => {
    group.forEach((tile) => elements["tile-palette"].append(tileButton(tile, () => addTile(tile), "palette-tile")));
    if ([1, 3, 5].includes(groupIndex)) {
      const separator = document.createElement("div");
      separator.className = "palette-break";
      elements["tile-palette"].append(separator);
    }
  });
}

function addTile(tile) {
  const next = copyTile(tile);
  if (state.target === "concealed") {
    if (state.concealed.length < 13) state.concealed.push(next);
  } else if (state.target === "winning") {
    state.winning = next;
  } else if (state.target === "dora" || state.target === "ura") {
    if (state[state.target].length < 5) state[state.target].push(next);
  } else {
    state.meldDraft.push(next);
    if (state.meldDraft.length === meldTileCount()) {
      state.melds.push({ kind: elements["meld-kind"].value, tiles: state.meldDraft.map(copyTile) });
      state.meldDraft = [];
    }
  }
  render();
}

function inputStatus() {
  if (!state.engine) return "計算エンジンを読み込んでいます";
  if (state.meldDraft.length > 0) return "鳴き・槓の牌を最後まで選んでください";
  const expected = expectedConcealedCount();
  if (state.concealed.length !== expected) return `手牌を${expected}枚にしてください（現在${state.concealed.length}枚）`;
  if (!state.winning) return "和了牌を1枚選んでください";
  return "入力済みです。点数を計算できます";
}

function render() {
  renderTileList(elements["concealed-tiles"], state.concealed, (index) => { state.concealed.splice(index, 1); render(); });
  renderTileList(elements["winning-tile"], state.winning ? [state.winning] : [], () => { state.winning = null; render(); });
  renderTileList(elements["dora-tiles"], state.dora, (index) => { state.dora.splice(index, 1); render(); });
  renderTileList(elements["ura-tiles"], state.ura, (index) => { state.ura.splice(index, 1); render(); });
  renderMelds();
  renderMeldDraft();
  const expected = expectedConcealedCount();
  elements["concealed-count"].textContent = `${state.concealed.length} / ${expected}枚`;
  elements["meld-count"].textContent = `${state.melds.length}組`;
  const ready = Boolean(state.engine && state.winning && state.concealed.length === expected && state.meldDraft.length === 0);
  elements["calculate-button"].disabled = !ready;
  elements["input-hint"].textContent = inputStatus();
}

function requestFromState() {
  const value = (id) => elements[id].value;
  const checked = (id) => elements[id].checked;
  return {
    apiVersion: 1,
    hand: {
      concealedTiles: state.concealed,
      winningTile: state.winning,
      melds: state.melds,
      doraIndicators: state.dora,
      uraDoraIndicators: state.ura,
    },
    context: {
      winMethod: value("win-method"),
      seatWind: value("seat-wind"),
      roundWind: value("round-wind"),
      riichi: value("riichi"),
      ippatsu: checked("ippatsu"),
      rinshan: checked("rinshan"),
      chankan: checked("chankan"),
      haitei: checked("haitei"),
      houtei: checked("houtei"),
      tenhou: checked("tenhou"),
      chiihou: checked("chiihou"),
      honba: Number(value("honba")),
      riichiSticks: Number(value("riichi-sticks")),
    },
    rules: "standard",
  };
}

function paymentText(payment) {
  if (payment.kind === "ron") return `${payment.discarder.toLocaleString("ja-JP")}点`;
  if (payment.kind === "dealerTsumo") return `${payment.each.toLocaleString("ja-JP")}点オール`;
  return `親 ${payment.dealer.toLocaleString("ja-JP")}点 / 子 ${payment.nonDealerEach.toLocaleString("ja-JP")}点`;
}

function escapeHtml(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

function renderResult(response) {
  elements["result-placeholder"].classList.add("hidden");
  elements["result-content"].classList.remove("hidden");
  if (!response.ok) {
    const label = errorLabels[response.error.code] ?? response.error.message;
    elements["result-content"].innerHTML = `<div class="result-error"><p class="step">ERROR</p><h2>${escapeHtml(label)}</h2><p>${escapeHtml(response.error.message)}</p><code>${escapeHtml(response.error.code)}</code></div>`;
    return;
  }
  const result = response.result;
  const yakuman = result.limit.kind === "yakuman";
  const scoreTitle = yakuman
    ? `${result.limit.yakumanMultiplier > 1 ? `${result.limit.yakumanMultiplier}倍` : ""}役満`
    : `${result.han}翻 ${result.fu}符`;
  const limit = limitLabels[result.limit.kind];
  const yakuItems = result.yaku.map((item) => {
    const value = item.yakumanMultiplier > 0 ? `${item.yakumanMultiplier}倍役満` : `${item.han}翻`;
    return `<div class="result-item"><span>${escapeHtml(yakuLabels[item.id] ?? item.id)}</span><strong>${value}</strong></div>`;
  }).join("");
  const bonusItems = [
    ["ドラ", result.bonusHan.dora], ["裏ドラ", result.bonusHan.uraDora], ["赤ドラ", result.bonusHan.akaDora],
  ].filter(([, count]) => count > 0).map(([label, count]) => `<div class="result-item"><span>${label}</span><strong>${count}翻</strong></div>`).join("");
  elements["result-content"].innerHTML = `
    <div class="result-heading">
      <div><p class="step">RESULT</p><div class="score-main"><strong>${escapeHtml(scoreTitle)}</strong>${limit ? `<span>${limit}</span>` : ""}</div></div>
      <div class="payment-main"><span>支払い</span><strong>${escapeHtml(paymentText(result.payment))}</strong><span>和了者の収入 ${result.winnerGain.toLocaleString("ja-JP")}点（供託込み）</span></div>
    </div>
    <div class="result-grid">
      <div><h3>役</h3><div class="result-list">${yakuItems || "<span>—</span>"}</div></div>
      <div><h3>ドラ</h3><div class="result-list">${bonusItems || '<div class="result-item"><span>なし</span><strong>0翻</strong></div>'}</div></div>
    </div>`;
}

function calculate() {
  const request = requestFromState();
  const requestJson = JSON.stringify(request);
  elements["request-json"].textContent = JSON.stringify(request, null, 2);
  try {
    const raw = state.engine.mahjong_score_json(requestJson);
    elements["response-json"].textContent = JSON.stringify(JSON.parse(raw), null, 2);
    renderResult(JSON.parse(raw));
    document.getElementById("result-panel").scrollIntoView({ behavior: "smooth", block: "start" });
  } catch (error) {
    const response = { ok: false, error: { code: "runtime_error", message: String(error) } };
    elements["response-json"].textContent = JSON.stringify(response, null, 2);
    renderResult(response);
  }
}

function reset() {
  state.concealed = [];
  state.winning = null;
  state.melds = [];
  state.dora = [];
  state.ura = [];
  state.meldDraft = [];
  ["ippatsu", "rinshan", "chankan", "haitei", "houtei", "tenhou", "chiihou"].forEach((id) => { elements[id].checked = false; });
  elements["win-method"].value = "ron";
  elements["seat-wind"].value = "south";
  elements["round-wind"].value = "east";
  elements.riichi.value = "none";
  elements.honba.value = "0";
  elements["riichi-sticks"].value = "0";
  elements["request-json"].textContent = "—";
  elements["response-json"].textContent = "—";
  elements["result-placeholder"].classList.remove("hidden");
  elements["result-content"].classList.add("hidden");
  render();
}

function loadSample() {
  reset();
  state.concealed = ["1m", "2m", "3m", "4m", "5m", "6m", "1p", "2p", "3p", "7s", "8s", "5p", "5p"].map((kind) => ({ kind, red: false }));
  state.winning = { kind: "9s", red: false };
  elements.riichi.value = "riichi";
  render();
}

async function loadEngine() {
  const wasmUrl = new URL("../../_build/wasm-gc/debug/build/ffi/ffi.wasm", import.meta.url);
  try {
    const response = await fetch(wasmUrl);
    if (!response.ok) throw new Error(`Wasm fetch failed: ${response.status}`);
    const bytes = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(bytes, {}, {
      builtins: ["js-string"],
      importedStringConstants: "_",
    });
    const engine = instance.exports;
    if (engine.mahjong_api_version() !== 1 || typeof engine.mahjong_score_json("{") !== "string") throw new Error("Wasm string exports unavailable");
    state.engine = engine;
    state.backend = "Wasm-GC";
  } catch (wasmError) {
    console.info("Wasm-GC is unavailable; using the JavaScript backend.", wasmError);
    const engine = await import("../../_build/js/debug/build/ffi/ffi.js");
    if (engine.mahjong_api_version() !== 1) throw new Error("Unsupported scoring API version");
    state.engine = engine;
    state.backend = "JavaScript";
  }
  elements["status-dot"].classList.add("ready");
  elements["runtime-status"].textContent = `API v1 · ${state.backend}`;
  render();
}

document.querySelectorAll(".target-tab").forEach((button) => {
  button.addEventListener("click", () => {
    state.target = button.dataset.target;
    document.querySelectorAll(".target-tab").forEach((candidate) => candidate.classList.toggle("active", candidate === button));
    elements["meld-builder"].classList.toggle("hidden", state.target !== "meld");
  });
});

elements["meld-kind"].addEventListener("change", () => { state.meldDraft = []; renderMeldDraft(); });
elements["clear-meld-draft"].addEventListener("click", () => { state.meldDraft = []; renderMeldDraft(); });
elements["sample-button"].addEventListener("click", loadSample);
elements["reset-button"].addEventListener("click", reset);
elements["calculate-button"].addEventListener("click", calculate);

renderPalette();
render();
loadEngine().catch((error) => {
  console.error(error);
  elements["status-dot"].classList.add("error");
  elements["runtime-status"].textContent = "計算エンジンを読み込めませんでした";
  elements["input-hint"].textContent = "READMEの手順でMoonBit生成物をビルドしてください";
});
