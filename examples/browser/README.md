# Browser example

MoonBit製の境界APIを、ブラウザから実際に利用する最小構成のGUIです。ビルドツールやフレームワークへの依存はなく、MoonBitの生成物と静的ファイルだけで動きます。

リポジトリのルートで次を実行してください。

```sh
moon build --target wasm-gc src/ffi
moon build --target js src/ffi
python3 -m http.server 8000
```

その後、<http://127.0.0.1:8000/examples/browser/>を開きます。

アプリはWasm-GCを先に読み込み、JS String Builtinsに対応していないブラウザではMoonBitのJavaScript生成物へ切り替わります。選ばれたバックエンドは画面右上に表示されます。

生成物は`_build`以下に置かれ、Gitとmooncakesの配布物には含まれません。

牌画像は[`FluffyStuff/riichi-mahjong-tiles`](https://github.com/FluffyStuff/riichi-mahjong-tiles)のRegular版SVG（パブリックドメイン）です。コミット`26e127ba2117f45cdce5ea0225748cc0cfad3169`に固定してGitHubから読み込むため、表示にはインターネット接続が必要です。読み込めない場合は文字表示になります。
