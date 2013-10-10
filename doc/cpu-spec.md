# CPU実験　コアアーキテクチャ
清水駿介

基本的にはDEC Alpha．比較や論理演算周りは，Alphaは直交性が高く美しいもののCPU実験で使うには無駄が多そうだったのでむしろMIPSに近づけた．厳密な意味論は書いていないが，曖昧性なく読めるようには書くつもり．不明な点が有れば指摘して欲しい．


## 大まかな仕様
整数レジスタ，浮動小数点レジスタともに，32bitでそれぞれ32個．ビッグエンディアン．R0はゼロ固定で，R31はリンクレジスタとして用いる．命令は固定長32bit．


## 命令フォーマット
*   1bit目が立ってれば分岐かジャンプ，立ってなければそれ以外
*   2bit目が立ってればメモリアクセス，立ってなければそれ以外
*   ただし1bit目も2bit目も立ってれば特殊命令
*   3bit目が立ってればオペランドは浮動小数点，立ってなければ整数

というデコードを可能にしている．そのせいで分岐命令がカツカツになってしまったので，命令追加が必要なら変更の可能性有り．

<table>
    <tr><th>Type</th>
        <th>31</th><th>30</th><th>29</th><th>28</th><th>27</th><th>26</th><th>25</th><th>24</th><th>23</th><th>22</th><th>21</th><th>20</th><th>19</th><th>18</th><th>17</th><th>16</th><th>15</th><th>14</th><th>13</th><th>12</th><th>11</th><th>10</th><th>9</th><th>8</th><th>7</th><th>6</th><th>5</th><th>4</th><th>3</th><th>2</th><th>1</th><th>0</th>
    </tr>
    <tr><td><b>R</b>egister-<b>O</b>peration</td>
        <td colspan="6">000xxx</td><td colspan="5">Rs</td><td colspan="5">Rt</td><td colspan="3">Unused</td><td colspan="1">0</td><td colspan="7">Function</td><td colspan="5">Rd</td>
    </tr>
    <tr><td><b>I</b>mmediate-<b>O</b>peration</td>
        <td colspan="6">000xxx</td><td colspan="5">Rs</td><td colspan="8">Immediate</td><td colspan="1">1</td><td colspan="7">Function</td><td colspan="5">Rd</td>
    </tr>
    <tr><td><b>L</b>ong Immediate-<b>O</b>peration</td>
        <td colspan="6">000xxx</td><td colspan="5">Rs</td><td colspan="16">Long Immediate</td><td colspan="5">Rd</td>
    </tr>
    <tr><td><b>F</b>loat-<b>O</b>peration</td>
        <td colspan="6">001xxx</td><td colspan="5">Fs</td><td colspan="5">Ft</td><td colspan="3">Unused</td><td colspan="1">0</td><td colspan="7">Function</td><td colspan="5">Fd</td>
    </tr>
    <tr><td><b>R</b>egisiter-<b>M</b>emory</td>
        <td colspan="6">010xxx</td><td colspan="5">Ra</td><td colspan="5">Rb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>F</b>loat-<b>M</b>emory</td>
        <td colspan="6">011xxx</td><td colspan="5">Fa</td><td colspan="5">Fb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>R</b>egisiter-<b>B</b>ranch</td>
        <td colspan="6">100xxx</td><td colspan="5">Ra</td><td colspan="5">Rb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>F</b>loat-<b>B</b>ranch</td>
        <td colspan="6">101xxx</td><td colspan="5">Fa</td><td colspan="5">Fb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>J</b>ump</td>
        <td colspan="6">1100xx</td><td colspan="5">Ra</td><td colspan="5">Function</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>Sp</b>ecial</td>
        <td colspan="6">11x100</td><td colspan="5">0</td><td colspan="5">Function</td><td colspan="16">Hoge</td>
    </tr>
</table>

<!--
   31 30 29 28 27 26 25 24 23 22 21 20 19 28 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
RO [     0000xx     ][     Rs      ][     Rt      ][Unused ][0][     Function      ][     Rd      ]
IO [     0000xx     ][     Rs      ][      Immediate       ][1][     Function      ][     Rd      ]
LO [     0001xx     ][     Rs      ][                Long Immediate                ][     Rd      ]
FO [     001xxx     ][     Fs      ][     Ft      ][Unused ][0][     Function      ][     Fd      ]
RM [     010xxx     ][     Ra      ][     Rb      ][                 Displacement                 ]
FM [     011xxx     ][     Fa      ][     Fb      ][                 Displacement                 ]
RB [     100xxx     ][     Ra      ][     Rb      ][                 Displacement                 ]
FB [     101xxx     ][     Fa      ][     Fb      ][                 Displacement                 ]
J  [     1100xx     ][     Ra      ][  Function   ][                 Displacement                 ]
SP [     11x1xx     ][                                    Hoge                                    ]
-->

Unusedの値は何であっても動くはずだが，一応0を入れるようにする．

別記無い場合は，Rsが入力の左側，Long Immediate もしくはImmediateもしくはRtが入力の右側，Rdが結果．左右というのは各命令に対応する二項演算子を考えた時にどっちに来るかということである（引き算やシフト演算などでは左右の区別が必要）．

Immediateに対しては符号拡張せず，Long Immediateに対しては符号拡張を行う．Displacementは，メモリアドレス（のオフセット）として用いる値で，32bit単位のアクセスしか不要なので，byte単位でのアドレスから下2bitを端折った上で使う．

一つのレジスタしか入力として取らない命令は即値を受け取ることにする（12番目のbitを1）．即値として用いる値は何でも良いはずだが，一応必ず0ということにしておく．

## ニーモニックの記法
### データサイズ
<dl>
    <dt><b>u</b>ni byte</dt>
        <dd>1byte(8bit)</dd>
    <dt><b>d</b>ouble byte</dt>
        <dd>2byte(16bit)</dd>
    <dt><b>q</b>uad byte</dt>
        <dd>4byte(32bit)</dd>
    <dt><b>o</b>cto byte</dt>
        <dd>8byte(64bit)</dd>
</dl>

### 符号
<dl>
    <dt><b>u</b>nsigned</dt>
        <dd>符号無し</dd>
    <dt><b>s</b>igned</dt>
        <dd>符号付き</dd>
</dl>


## 命令一覧

### ALU（RO，IO，LO）
ちょうど16命令．足りないようならまだ命令は増やせる．

functionが0の命令のみ，LOフォーマットでも用いることができる．これによって，即値のレジスタへのロードを二命令で行える．

#### xor，xori，xorl
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd>Register / Immediate <code>000000</code></dd>
        <dd>Long Immediate <code>000100</code></dd>
    <dt>function</dt>
        <dd><code>0000000</code></dd>
</dl>

ビットごとのXOR．Long Immediateの-1とXORすることで，bitwiseのnotが可能．

#### and，andi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>000000</code></dd>
    <dt>function</dt>
        <dd><code>0000001</code></dd>
</dl>

ビットごとのAND．

#### or，ori
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>000000</code></dd>
    <dt>function</dt>
        <dd><code>0000010</code></dd>
</dl>

ビットごとのOR．

#### rotq，rotqi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>最低</dd>
    <dt>opcode</dt>
        <dd><code>000000</code></dd>
    <dt>function</dt>
        <dd><code>0000011</code></dd>
</dl>

32bit整数に対する左循環シフト．シフト量としてRtもしくはImmediateの下位5bitを用いる．循環シフトは32を法として合同な動作をするので，これで正にも負にもシフトできていると言える．

#### addqu，addqui，addqul
<dl>
    <dt></dt>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd>Register / Immediate <code>000001</code></dd>
        <dd>Long Immediate <code>000101</code></dd>
    <dt>function</dt>
        <dd><code>0000000</code></dd>
</dl>

32bit符号無し整数同士の加算．下位bitは変化せず，オーバーフローは無視するため，符号付き整数の演算に使っても正しい結果を出す．

#### subqu，subqui
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>000001</code></dd>
    <dt>function</dt>
        <dd><code>0000001</code></dd>
</dl>

32bit符号無し整数同士の減算．下位bitは変化せず，アンダーフローは無視するため，符号付き整数の演算に使っても正しい結果を出す．

##### eq，eqi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000001</code></dd>
    <dt>function</dt>
        <dd><code>0000010</code></dd>
</dl>

Rs = Rt

##### lt，lti
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000001</code></dd>
    <dt>function</dt>
        <dd><code>0000011</code></dd>
</dl>

Rs < Rt

#### movh，movhs，movhl
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd>Register / Immediate <code>000010</code></dd>
        <dd>Long Immediate <code>000110</code></dd>
    <dt>function</dt>
        <dd><code>0000000</code></dd>
</dl>

Rsの下位16bitをRdの下位16bitに，RtまたはImmediateまたはLong Immediateの下位16bitをRdの上位16bitにセット．

#### lsftq，lsftqi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000010</code></dd>
    <dt>function</dt>
        <dd><code>0000001</code></dd>
</dl>

32bit整数に対する左シフト．RtもしくはImmediateは，unsignedとして扱う，つまり単に下6bitだけを用いる．

#### rsftqu，rsftqui
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000010</code></dd>
    <dt>function</dt>
        <dd><code>0000010</code></dd>
</dl>

32bit整数に対する右論理シフト．シフト量は必ず正で，RtもしくはImmediateの下位5bitだけを用いる．

#### rsftqs，rsftqsi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000010</code></dd>
    <dt>function</dt>
        <dd><code>0000011</code></dd>
</dl>

32bit整数に対する右算術シフト．シフト量は必ず正で，RtもしくはImmediateの下位5bitだけを用いる．

#### mulqul，mulquli，mulqull
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd>Register / Immediate <code>000011</code></dd>
        <dd>Long Immediate <code>000111</code></dd>
    <dt>function</dt>
        <dd><code>0000000</code></dd>
</dl>

32bit符号無し整数同士の乗算．下32bitを格納．符号bitによって下位32bitは変化しないため，符号付き整数の演算に使っても正しい結果を出す．

#### mulquh，mulquhi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
    <dt>opcode</dt>
        <dd><code>000011</code></dd>
    <dt>function</dt>
        <dd><code>0000001</code></dd>
</dl>

符号無し32bit整数同士の乗算．上32bitを格納．

符号付き32bit整数同士の乗算は，ソフトウェアによって補正することで行う．Alphaのドキュメントに記載の数式参照

#### movez，movezi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>000011</code></dd>
    <dt>function</dt>
        <dd><code>0000010</code></dd>
</dl>

Rsが0に等しいなら，RdをRtあるいはImmediateで置き換える．

#### movnz，movnzi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>000011</code></dd>
    <dt>function</dt>
        <dd><code>0000011</code></dd>
</dl>

Rsが0に等しくないなら，RdをRtあるいはImmediateで置き換える．


### 浮動小数点演算（FO）
#### 比較命令について
浮動小数点比較の命令は実装せず，必要となることがあれば浮動小数点比較による条件分岐によって代替することにする．

浮動小数点同士の比較はminCamlには分岐のオペランドとして出現しないために，比較命令はmin-rt動作のために不要であるのに大して，実装する場合は

*   汎用レジスタに書き込むのはハードウェアのコストが大きい可能性がある
*   浮動小数点レジスタに書き込んでもあまり役に立たない
*   特殊レジスタを用意すると命令が複雑になる

という問題があるためである．

#### functionの意味
浮動小数点演算の結果の符号をFunctionに埋め込んだ2bitで指定できるようにする．

fmov以外に関しては，「変化なし」のみ必須．

sgn一覧

<dl>
    <dt>00</dt>
        <dd>変化なし</dd>
    <dt>01</dt>
        <dd>反転</dd>
    <dt>10</dt>
        <dd>正（abs）</dd>
    <dt>11</dt>
        <dd>負</dd>
</dl>

delayはFPUの実行サイクル数から1引いた値の二進数表現で，3bitとする．（なので8クロックの遅延まで許容．高速化によって4クロックになれば嬉しい．）

#### fadd，faddn，faddp，faddm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001000</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]00</code></dd>
</dl>

ウッfaddだ．仕様はFPU班と相談．

#### fsub，fsubn，fsubp，fsubm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001000</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]01</code></dd>
</dl>

ほぼfadd．

#### fmul，fmuln，fmulp，fmulm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001000</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]10</code></dd>
</dl>

仕様はFPU班と相談．

#### fmov，fmovn，fmovp，fmovm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001000</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]11</code></dd>
</dl>

コア班が実装．fmovnはfneg，fmovpはfabs．

#### finv
<dl>
    <dt>実装箇所</dt>
        <dd>コア or ライブラリ</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001001</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]00</code></dd>
</dl>

FPU班に任せる．

#### fsqrt
<dl>
    <dt>実装箇所</dt>
        <dd>コア or ライブラリ</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>001001</code></dd>
    <dt>function</dt>
        <dd><code>[delay][sgn]01</code></dd>
</dl>

FPU班に任せる．

#### fsinなど
<dl>
    <dt>実装箇所</dt>
        <dd>ライブラリ</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

FPU班に任せる．


### メモリアクセス命令（RM，FM）
最低限の命令のみ．即値のロード・ストアに対応するには命令フォーマットの変更が必要になりそう．

#### 記法
<dl>
    <dt>register<dt>
        <dd>t = 0<dd>
    <dt>float<dt>
        <dd>t = 1<dd>
</dl>

#### ldq，fldq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>01[t]000</code></dd>
</dl>

Rbの下2bitをクリアした上で，Displacementを2bit左にシフトして足しあわせてアドレスを計算．

RaにアドレスをもとにSRAMから取得した値をロード．

#### stq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>01[t]001</code></dd>
</dl>

Rbの下2bitをクリアした上で，Displacementを2bit左にシフトして足しあわせてアドレスを計算．

Raの値をSRAM上のアドレスが指す位置にストア．


### 条件分岐命令（RB，FB）
条件分岐命令によるレジスタ内のアドレスへのジャンプは，ユースケースが無さそうな割に実装するなら考えることがあまりに多いので，サポートしない．

#### 記法
<dl>
    <dt>register<dt>
        <dd>t = 0<dd>
    <dt>float<dt>
        <dd>t = 1<dd>
</dl>

#### beq，fbeq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>10[t]000</code></dd>
</dl>

Ra = Rb / Fa = Fb ならジャンプ

#### bne，fbne
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>10[t]001</code></dd>
</dl>

Ra ≠ Rb / Fa ≠ Fb ならジャンプ

#### blt，fblt
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>10[t]010</code></dd>
</dl>

Ra < Rb / Fa < Fb ならジャンプ

#### blte，fblte
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
    <dt>opcode</dt>
        <dd><code>10[t]011</code></dd>
</dl>

Ra ≦ Rb / Fa ≦ Fb ならジャンプ


### 無条件ジャンプ命令（RJ，DJ）
#### jr，jd
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>110000</code></dd>
    <dt>function</dt>
        <dd><code>00000</code></dd>
</dl>

R/Displacementにジャンプ．

#### jlr，jld
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>110000</code></dd>
    <dt>function</dt>
        <dd><code>00001</code></dd>
</dl>

R/Displacementにジャンプ．このとき，PCをリンクレジスタ（R31）にセット．

#### ret
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>110000</code></dd>
    <dt>function</dt>
        <dd><code>00010</code></dd>
</dl>

0入力の命令．リンクレジスタ（R31）にジャンプ．命令フォーマットはDJとし，Displacementは取りあえず必ず0とする．



### 特殊命令（SP）
#### get，fget
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>11[t]100</code></dd>
</dl>

<table>
    <tr>
        <th>31</th><th>30</th><th>29</th><th>28</th><th>27</th><th>26</th><th>25</th><th>24</th><th>23</th><th>22</th><th>21</th><th>20</th><th>19</th><th>18</th><th>17</th><th>16</th><th>15</th><th>14</th><th>13</th><th>12</th><th>11</th><th>10</th><th>9</th><th>8</th><th>7</th><th>6</th><th>5</th><th>4</th><th>3</th><th>2</th><th>1</th><th>0</th>
    </tr>
    <tr>
        <td colspan="6">110100</td><td colspan="21">000000000000000000000</td><td colspan="5">R</td>
    </tr>
    <tr>
        <td colspan="6">111100</td><td colspan="21">000000000000000000000</td><td colspan="5">F</td>
    </tr>
</table>

標準出力なりシリアル通信なりから入力を受け取ってRまたはFの値とする．単なるバイト列として，ビッグエンディアンなので最上位ビットから順に入力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．

#### put，fput
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
    <dt>opcode</dt>
        <dd><code>11[t]100</code></dd>
</dl>

<table>
    <tr>
        <th>31</th><th>30</th><th>29</th><th>28</th><th>27</th><th>26</th><th>25</th><th>24</th><th>23</th><th>22</th><th>21</th><th>20</th><th>19</th><th>18</th><th>17</th><th>16</th><th>15</th><th>14</th><th>13</th><th>12</th><th>11</th><th>10</th><th>9</th><th>8</th><th>7</th><th>6</th><th>5</th><th>4</th><th>3</th><th>2</th><th>1</th><th>0</th>
    </tr>
    <tr>
        <td colspan="6">110100</td><td colspan="21">000000000000000000001</td><td colspan="5">R</td>
    </tr>
    <tr>
        <td colspan="6">111100</td><td colspan="21">000000000000000000001</td><td colspan="5">F</td>
    </tr>
</table>

RまたはFの値を標準出力なりシリアル通信なりに出力する．単なるバイト列として，ビッグエンディアンなので最上位ビットから順に出力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．
