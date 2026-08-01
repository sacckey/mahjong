# JSON API v1

JS・Wasm-GCなどMoonBit外の呼び出し元では、`sacckey/mahjong/ffi`が公開する次の2関数を使用します。

- `mahjong_api_version() -> Int`
- `mahjong_score_json(input: String) -> String`

`mahjong_score_json`は例外を外へ送出せず、成功と失敗のどちらもJSONで返します。キー名、列挙値、エラーコードは機械処理用の識別子であり、画面へ表示する文言は呼び出し側で用意します。

## 入力

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

## 成功

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
      "discarder": 2000,
      "each": null,
      "dealer": null,
      "nonDealerEach": null
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

支払いは`ron`、`dealerTsumo`、`nonDealerTsumo`の3形式です。該当しない支払いフィールドは`null`になります。

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

境界層が返すエラーコードは次のとおりです。

- JSON・プロトコル: `invalid_json`、`invalid_request`、`unsupported_api_version`
- 牌・手牌: `invalid_tile`、`too_many_copies`、`invalid_hand_size`、`invalid_meld`
- 条件・ルール: `contradictory_context`、`invalid_rule`
- 和了判定: `not_winning_hand`、`invalid_hand_shape`、`no_yaku`

`message`は開発者向けの英語文です。UIでは`code`を翻訳して表示してください。`details`の有無と内容はエラーごとに異なるため、分岐の基準には使用しません。
