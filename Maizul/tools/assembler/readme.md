# アセンブラ

## 実行方法

    ./myasm <file>

出力はテキストだが，

    ruby ../format/bintxt2bin

で，コアやシミュレータが受け付けるバイナリになる．

## 構文・ニーモニック
`lexer.mll`と`parser.mly`に全て書いている．あとはsampleを見てもらえば．

## データ構造について
`type.mli`でアセンブラが用いるデータ構造を定義している．このデータ構造をpretty printしたものを再度パースすれば，同じデータが得られるようになっている．

コンパイラのようなプログラムで用いることが可能．