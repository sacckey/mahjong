# Browser example

MoonBit製の境界APIを、ブラウザから実際に利用する最小構成のGUIです。ビルドツールやフレームワークへの依存はなく、MoonBitの生成物と静的ファイルだけで動きます。

リポジトリのルートで次を実行してください。

```sh
moon build --target wasm-gc src/ffi
moon build --target js src/ffi
python3 -m http.server 8000
```

その後、<http://127.0.0.1:8000/examples/browser/>を開きます。

アプリはWasm-GCを先に読み込みます。JS String Builtinsに対応していないブラウザでは、同じ`mahjong_score_json`境界を持つMoonBitのJavaScript生成物へ自動的に切り替わります。画面右上に実際に選ばれたバックエンドが表示されます。

生成物は`_build`以下に置かれ、Gitとmooncakesの配布物には含まれません。

牌の表示には[`FluffyStuff/riichi-mahjong-tiles`](https://github.com/FluffyStuff/riichi-mahjong-tiles)のRegular版SVGを使用しています。素材はパブリックドメインです。表示の再現性を保つため、参照先をコミット`26e127ba2117f45cdce5ea0225748cc0cfad3169`へ固定しています。牌画像はGitHubから読み込むため、表示にはインターネット接続が必要です。読み込めない場合は文字牌表示へフォールバックします。
