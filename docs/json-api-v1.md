# JSON API v1

JS・Wasm-GCなどMoonBit外の呼び出し元では、`sacckey/mahjong/ffi`が公開する次の3関数を使用します。

- `mahjong_api_version() -> Int`
- `mahjong_score_json(input: String) -> String`
- `mahjong_analysis_json(input: String) -> String`

JSON関数は例外を外へ送出せず、成功と失敗のどちらもJSONで返します。キー名、列挙値、エラーコードは機械処理用の識別子であり、画面へ表示する文言は呼び出し側で用意します。

## 点数計算の入力

`concealedTiles`は和了牌を含みません。数牌は`1m`から`9s`、字牌は`east`、`south`、`west`、`north`、`white`、`green`、`red`で表します。赤牌は5の数牌に`red: true`を指定します。

```json
{
  "apiVersion": 1,
  "hand": {
    "concealedTiles": [
      { "kind": "1m", "red": false },
      { "kind": "2m", "red": false }
    ],
    "winningTile": { "kind": "9s", "red": false },
    "melds": [],
    "doraIndicators": [],
    "uraDoraIndicators": []
  },
  "context": {
    "winMethod": "ron",
    "seatWind": "south",
    "roundWind": "east",
    "riichi": "riichi",
    "ippatsu": false,
    "rinshan": false,
    "chankan": false,
    "haitei": false,
    "houtei": false,
    "tenhou": false,
    "chiihou": false,
    "honba": 0,
    "riichiSticks": 0
  },
  "rules": "standard"
}
```

`melds[].kind`は`chi`、`pon`、`openKan`、`closedKan`、`addedKan`のいずれかです。v1では`rules`は`standard`のみを受け付けます。

## 点数計算の成功

```json
{
  "apiVersion": 1,
  "ok": true,
  "result": {
    "han": 2,
    "fu": 30,
    "limit": { "kind": "belowMangan", "yakumanMultiplier": 0 },
    "basePoints": 480,
    "payment": {
      "kind": "ron",
      "discarder": 2000
    },
    "riichiBonus": 0,
    "winnerGain": 2000,
    "yaku": [
      { "id": "riichi", "han": 1, "yakumanMultiplier": 0 },
      { "id": "pinfu", "han": 1, "yakumanMultiplier": 0 }
    ],
    "bonusHan": { "dora": 0, "uraDora": 0, "akaDora": 0 },
    "fuItems": [
      { "reason": "base", "fu": 20 },
      { "reason": "menzenRon", "fu": 10 }
    ],
    "shape": {
      "kind": "standard",
      "pair": "5p",
      "groups": [
        { "kind": "sequence", "tile": "1m", "open": false },
        { "kind": "sequence", "tile": "4m", "open": false },
        { "kind": "sequence", "tile": "1p", "open": false },
        { "kind": "sequence", "tile": "7s", "open": false }
      ],
      "tiles": [],
      "wait": "ryanmen"
    }
  }
}
```

支払いは`ron`、`dealerTsumo`、`nonDealerTsumo`の3形式です。`ron`は`discarder`、`dealerTsumo`は`each`、`nonDealerTsumo`は`dealer`と`nonDealerEach`を持ち、該当しない支払いフィールドは出力されません。

## 牌姿解析

`mahjong_analysis_json`は`calculateShanten`、`isTenpai`、`waitingTiles`の3操作を受け付けます。`concealedTiles`には現在の副露前の手牌をすべて含め、和了牌は分離しません。

```json
{
  "apiVersion": 1,
  "operation": "calculateShanten",
  "input": {
    "concealedTiles": [
      { "kind": "1m", "red": false },
      { "kind": "2m", "red": false }
    ],
    "melds": []
  }
}
```

`calculateShanten`の成功時は、通常形、七対子、国士無双と、その最小シャンテン数を返します。副露がある場合、評価対象外となる七対子と国士無双は`null`です。

```json
{
  "apiVersion": 1,
  "ok": true,
  "result": {
    "minimum": 0,
    "standard": 0,
    "sevenPairs": 5,
    "thirteenOrphans": 11
  }
}
```

`isTenpai`の`result`は真偽値、`waitingTiles`の`result`は正規順に並んだ牌種の配列です。

```json
{ "apiVersion": 1, "ok": true, "result": true }
```

```json
{ "apiVersion": 1, "ok": true, "result": ["6s", "9s"] }
```

`isTenpai`と`waitingTiles`は構造上13枚の入力だけを受け付けます。役、フリテン、河や山に残る枚数は考慮しません。

## 失敗

```json
{
  "apiVersion": 1,
  "ok": false,
  "error": {
    "code": "not_winning_hand",
    "message": "The tiles do not form a winning hand.",
    "details": null
  }
}
```

境界層が返すエラーコードは次のとおりです。牌姿解析では、このうちJSON・プロトコルと牌・手牌のエラーを使用します。

- JSON・プロトコル: `invalid_json`、`invalid_request`、`unsupported_api_version`
- 牌・手牌: `invalid_tile`、`too_many_copies`、`invalid_hand_size`、`invalid_meld`
- 条件・ルール: `contradictory_context`、`invalid_rule`
- 和了判定: `not_winning_hand`、`invalid_hand_shape`、`no_yaku`

`message`は開発者向けの英語文です。UIでは`code`を翻訳して表示してください。`details`の有無と内容はエラーごとに異なるため、分岐の基準には使用しません。
