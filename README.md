# 手抜き

手抜きはCSAプロトコルで通信する将棋プログラムです。


## 開発環境

- Debian 11
- LDC


## ビルドのしかた

~~~
$ sudo apt install build-essential llvm-dev ldc dub
$ git clone https://github.com/hikaen2/tenuki-usi.git
$ cd tenuki-usi
$ make
~~~


## 動かしかた

評価ベクターに[『どうたぬき』(tanuki- 第 1 回世界将棋 AI 電竜戦バージョン)](https://github.com/nodchip/tanuki-/releases/tag/tanuki-denryu1)の評価関数ファイル nn.bin を使っています。
nn.binを作業ディレクトリに置いて実行してください。
