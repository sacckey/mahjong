# sacckey/mahjong

MoonBitで実装する四人リーチ麻雀の点数計算・牌姿解析ライブラリです。

通常ルールの一局について、入力検証、和了形列挙、役・ドラ・符の判定、支払い計算、最高点となる解釈の選択まで実装しています。ルールの初期仕様は[`docs/rules-v1.md`](../docs/rules-v1.md)を参照してください。

## インストールと実行

既存のMoonBitプロジェクトにライブラリを追加します。

```sh
moon add sacckey/mahjong
```

新規プロジェクトで試す場合は、次のように作成できます。

```sh
moon new mahjong-example
cd mahjong-example
moon add sacckey/mahjong
```

`cmd/main/moon.pkg`でライブラリをimportします。

```moonbit nocheck
import {
  "sacckey/mahjong"
}

pkgtype(kind: "executable")
```

`cmd/main/main.mbt`を次の内容にします。この例は、南家が立直し、平和形を9索でツモ和了した場合を計算します。

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

実行すると次のように表示されます。

```sh
moon run cmd/main
```

```text
3翻 20符
子 700点 / 親 1300点（合計 2700点）
```

## 公開API

基本の入口は、標準ルールで計算する`score_standard`と、`RuleSet`を指定する`score`です。上の例のように、`HandInput.concealed_tiles`には和了牌を含めず、ツモ牌またはロン牌を`winning_tile`へ指定します。

`ScoreResult`からは翻数の`han`、符数の`fu`、支払い内訳の`payment`、供託を含む和了者の受取額`winner_gain`などを取得できます。

和了形かどうかだけを調べる場合は`is_winning_hand`、既に確定した翻数と符から支払いを計算する場合は`calculate_points`を使用できます。役判定、符計算、ドラ計算、和了形分解は`score`の内部処理です。

## シャンテン数・聴牌・待ち牌

牌姿の解析には`sacckey/mahjong/analysis`パッケージを使用します。点数計算とは独立して、通常形、七対子、国士無双のシャンテン数、構造上の聴牌状態、待ち牌一覧を計算します。

```moonbit nocheck
///|
import {
  "sacckey/mahjong",
  "sacckey/mahjong/analysis",
}
```

基本の入口は`calculate_shanten`、`is_tenpai`、`waiting_tiles`です。待ち牌判定は役、フリテン、河に見えている牌を考慮しません。詳細は[`docs/analysis-v1.md`](../docs/analysis-v1.md)を参照してください。

## JS・Wasm-GCから使う

MoonBit外との境界には`sacckey/mahjong/ffi`パッケージを使用します。JSとWasm-GCのどちらにも、同じJSONプロトコルを受け取る`mahjong_score_json`、`mahjong_analysis_json`と、プロトコルバージョンを返す`mahjong_api_version`がexportされます。

JSONの入力、結果、エラーコードは[`docs/json-api-v1.md`](../docs/json-api-v1.md)で定義しています。境界層はコアのMoonBit APIから分離されているため、MoonBitから利用する場合は引き続き型付きの`score_standard`または`score`を使えます。

JavaScript・TypeScriptからは`@sacckey/mahjong`を使用できます。パッケージはWasm-GCを優先し、利用できない環境ではJavaScript生成物へ切り替わります。

```sh
npm install @sacckey/mahjong
```

npm向けのAPIと開発手順は[`packages/npm/README.md`](../packages/npm/README.md)を参照してください。

## ブラウザ利用例

手牌、和了牌、鳴き・槓、ドラ表示牌、和了条件をGUIで入力できる静的アプリを[`examples/browser`](../examples/browser/)に置いています。

公開版は<https://sacckey.github.io/mahjong/>で試せます。ローカルで動かす場合は、リポジトリのルートで次を実行します。

```sh
moon build --target wasm-gc src/ffi
moon build --target js src/ffi
python3 -m http.server 8000
```

<http://127.0.0.1:8000/examples/browser/>を開いてください。Wasm-GCを優先し、未対応のブラウザではMoonBitのJavaScript生成物へ切り替わります。このアプリと生成物はmooncakesの配布物には含まれません。

## 開発

```sh
moon check --target all
moon test --target all
```

`MahjongRepository/mahjong`との開発用差分検証は次のコマンドで実行できます。Python依存と生成ケースは配布ライブラリには含まれません。

```sh
uv run tools/conformance/check.py
```

詳細は[`tools/conformance/README.md`](../tools/conformance/README.md)を参照してください。
