# sacckey/mahjong

MoonBitで実装した四人リーチ麻雀の点数計算・牌姿解析ライブラリです。

入力検証、和了形の列挙、役・ドラ・符の判定、支払い計算を行い、最も高い点数になる解釈を返します。採用ルールは[`docs/rules-v1.md`](../docs/rules-v1.md)を参照してください。

## 使い方

```sh
moon add sacckey/mahjong
```

実行するパッケージの`moon.pkg`でimportします。

```moonbit nocheck
import {
  "sacckey/mahjong"
}

pkgtype(kind: "executable")
```

次の例は、南家が立直し、平和形を9索でツモ和了した場合を計算します。`concealed_tiles`には和了牌を含めず、ツモ牌またはロン牌を`winning_tile`へ指定します。

```moonbit nocheck
///|
fn main raise {
  let tile = (suit, rank) => @mahjong.Tile::numbered(suit, rank)
  let context = {
    ..@mahjong.WinContext::new(
      @mahjong.Tsumo,
      seat_wind=@mahjong.South,
      round_wind=@mahjong.East,
    ),
    riichi: @mahjong.Riichi,
  }
  let input = @mahjong.HandInput::new(
    [
      tile(@mahjong.Man, 1),
      tile(@mahjong.Man, 2),
      tile(@mahjong.Man, 3),
      tile(@mahjong.Man, 4),
      tile(@mahjong.Man, 5),
      tile(@mahjong.Man, 6),
      tile(@mahjong.Pin, 1),
      tile(@mahjong.Pin, 2),
      tile(@mahjong.Pin, 3),
      tile(@mahjong.Sou, 7),
      tile(@mahjong.Sou, 8),
      tile(@mahjong.Pin, 5),
      tile(@mahjong.Pin, 5),
    ],
    winning_tile=tile(@mahjong.Sou, 9),
    context~,
  )
  let result = @mahjong.score_standard(input)
  match result.payment {
    @mahjong.NonDealerTsumoPayment(dealer~, non_dealer_each~) => {
      println("\{result.han}翻 \{result.fu}符")
      println(
        "子 \{non_dealer_each}点 / 親 \{dealer}点（合計 \{result.winner_gain}点）",
      )
    }
    _ => println("unexpected payment")
  }
}
```

```text
3翻 20符
子 700点 / 親 1300点（合計 2700点）
```

## 公開API

| 関数 | 用途 |
|---|---|
| `score_standard(input)` | 標準ルールで点数を計算する |
| `score(input, rules)` | `RuleSet`を指定して計算する |
| `score_with_tile_copy_rules(input, rules, tile_copy_rules)` | 同一牌種の枚数上限を変えて計算する |
| `is_winning_hand(input)` | 和了形かどうかだけを調べる |
| `calculate_points(han, fu, dealer~, win_method~)` | 確定した翻と符から支払いを計算する |

`ScoreResult`からは翻数`han`、符数`fu`、支払い内訳`payment`、供託を含む和了者の受取額`winner_gain`などを取得できます。

同一牌種を5枚以上使えるゲームでは`TileCopyRules::unlimited()`を渡します。変わるのは物理枚数の検証だけで、5枚あれば雀頭2枚と刻子3枚のように通常どおり分解されます。

## 牌姿解析

`sacckey/mahjong/analysis`パッケージの`calculate_shanten`、`is_tenpai`、`waiting_tiles`で、通常形、七対子、国士無双のシャンテン数、構造上の聴牌、待ち牌を調べられます。役、フリテン、河に見えている牌は考慮しません。使用例は[パッケージのREADME](analysis/README.mbt.md)、仕様は[`docs/analysis-v1.md`](../docs/analysis-v1.md)を参照してください。

## JS・Wasm-GCから使う

JavaScript・TypeScriptからはnpmパッケージを使います。Wasm-GCを優先し、利用できない環境ではJavaScript生成物へ切り替わります。APIは[`packages/npm/README.md`](../packages/npm/README.md)を参照してください。

```sh
npm install @sacckey/mahjong
```

MoonBit外から直接呼ぶ場合は、`sacckey/mahjong/ffi`パッケージがexportする`mahjong_score_json`、`mahjong_analysis_json`、`mahjong_api_version`を使います。入力、結果、エラーコードは[`docs/json-api-v1.md`](../docs/json-api-v1.md)で定義しています。

## ブラウザ利用例

手牌、鳴き、ドラ表示牌、和了条件をGUIで入力できる静的アプリを<https://sacckey.github.io/mahjong/>で公開しています。ソースとローカルでの動かし方は[`examples/browser`](../examples/browser/)にあります。

## 開発

```sh
moon check --target all
moon test --target all
```

`MahjongRepository/mahjong`との差分検証は[`tools/conformance/README.md`](../tools/conformance/README.md)を参照してください。
