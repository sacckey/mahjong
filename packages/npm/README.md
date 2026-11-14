# @sacckey/mahjong

MoonBitで実装した四人リーチ麻雀の点数計算・牌姿解析ライブラリを、JavaScript・TypeScriptから利用するためのnpmパッケージです。

## インストール

```sh
npm install @sacckey/mahjong
```

## 使い方

```js
import { API_VERSION, createCalculator } from "@sacckey/mahjong";

const tile = (kind, red = false) => ({ kind, red });
const calculator = await createCalculator();
const result = calculator.score({
  apiVersion: API_VERSION,
  hand: {
    concealedTiles: [
      "1m", "2m", "3m", "4m", "5m", "6m", "1p",
      "2p", "3p", "7s", "8s", "5p", "5p",
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
});

console.log(result.han, result.fu, result.payment);
```

`createCalculator()`はWasm-GCを優先し、利用できない環境ではJavaScript生成物へ自動的に切り替えます。使用中の実装は`calculator.backend`で確認できます。

Cloudflare Workersなどのworkerd環境でJavaScript生成物を使用する場合は、`createCalculator({ backend: "javascript" })`を指定できます。この場合、WasmファイルのURL解決や取得は行いません。

## シャンテン数・聴牌・待ち牌

`concealedTiles`には、現在の副露前の手牌をすべて渡します。点数計算の入力とは異なり、和了牌を分離しません。副露がなければ`melds`は省略できます。

```js
const input = {
  concealedTiles: [
    "1m", "2m", "3m", "4m", "5m", "6m", "1p",
    "2p", "3p", "7s", "8s", "5p", "5p",
  ].map((kind) => tile(kind)),
};

const shanten = calculator.calculateShanten(input);
const tenpai = calculator.isTenpai(input);
const waits = calculator.waitingTiles(input);

console.log(shanten.minimum); // 0
console.log(tenpai); // true
console.log(waits); // ["6s", "9s"]
```

`waitingTiles()`と`isTenpai()`は構造上13枚の入力だけを受け付けます。役、フリテン、河や山に残る枚数は考慮しません。

## 同一牌を5枚以上使うゲーム

通常は同一牌種を4枚までに制限します。第2引数に`maxCopiesPerKind: null`を渡すと、この枚数制限だけを解除できます。正の整数を渡すとその枚数が上限になります。手牌枚数、和了形、役、符などのルールは変わりません。

```js
const tileCopyRules = { maxCopiesPerKind: null };

const result = calculator.score(request, tileCopyRules);
const shanten = calculator.calculateShanten(input, tileCopyRules);
const tenpai = calculator.isTenpai(input, tileCopyRules);
const waits = calculator.waitingTiles(input, tileCopyRules);
```

同じ牌が5枚あれば、雀頭2枚と刻子3枚のように分解されます。立直後の暗槓判定はこの設定の対象外です。

## 立直後の暗槓

立直時に固定された13枚と、その後にツモった4枚目の牌を渡します。すべての和了形で元の3枚が独立した暗刻になる場合だけ`true`を返します。

```js
const input = {
  concealedTiles: [
    "5m", "5m", "5m", "1p", "2p", "3p", "4p",
    "5p", "6p", "7s", "8s", "east", "east",
  ].map((kind) => tile(kind)),
};

const allowed = calculator.canClosedKanAfterRiichi(input, tile("5m"));
console.log(allowed); // true
```

## エラー

`score()`は入力や和了判定のエラー時に`MahjongError`をthrowします。`code`を画面表示用の文言に対応付けてください。

```js
import { MahjongError } from "@sacckey/mahjong";

try {
  const result = calculator.score(request);
} catch (error) {
  if (error instanceof MahjongError) {
    console.error(error.code, error.message, error.details);
  }
}
```

throwせずに成功・失敗のエンベロープを受け取る場合は`scoreResponse()`または`analysisResponse()`、JSON文字列の低レベル境界を直接使う場合は`scoreJson()`または`analysisJson()`を使用します。

JSON API v1の詳細は[GitHubの仕様](https://github.com/sacckey/mahjong/blob/main/docs/json-api-v1.md)を参照してください。

## 開発

MoonBitとNode.jsが必要です。ビルド時にMoonBitのJavaScript・Wasm-GC生成物が`dist`へコピーされます。

```sh
cd packages/npm
npm test
npm pack --dry-run
```
