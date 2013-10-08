# CPU実験　コアアーキテクチャ
清水駿介

基本的にはDEC Alpha．比較や論理演算周りは，Alphaは直交性が高く美しいもののCPU実験で使うには無駄が多そうだったのでむしろMIPSに近づけた．厳密な意味論は書いていないが，曖昧性なく読めるようには書くつもり．不明な点が有れば指摘して欲しい．


## TODO
*   opcodeの決定．


## 大まかな仕様
整数レジスタ，浮動小数点レジスタともに，32bitでそれぞれ32個．ビッグエンディアン．R0はゼロ固定で，R31はリンクレジスタとして用いる．命令は固定長32bit．


## 命令フォーマット
<table>
    <tr><th>Type</th>
        <th>31</th><th>30</th><th>29</th><th>28</th><th>27</th><th>26</th><th>25</th><th>24</th><th>23</th><th>22</th><th>21</th><th>20</th><th>19</th><th>18</th><th>17</th><th>16</th><th>15</th><th>14</th><th>13</th><th>12</th><th>11</th><th>10</th><th>9</th><th>8</th><th>7</th><th>6</th><th>5</th><th>4</th><th>3</th><th>2</th><th>1</th><th>0</th>
    </tr>
    <tr><td>RO</td>
        <td colspan="6">OpCode</td><td colspan="5">Rs</td><td colspan="5">Rt</td><td colspan="3">Unused</td><td colspan="1">0</td><td colspan="7">Function</td><td colspan="5">Rd</td>
    </tr>
    <tr><td>IO</td>
        <td colspan="6">OpCode</td><td colspan="5">Rs</td><td colspan="8">Immediate</td><td colspan="1">1</td><td colspan="7">Function</td><td colspan="5">Rd</td>
    </tr>
    <tr><td>FO</td>
        <td colspan="6">OpCode</td><td colspan="5">Fs</td><td colspan="5">Ft</td><td colspan="3">Unused</td><td colspan="1">0</td><td colspan="7">Function</td><td colspan="5">Fd</td>
    </tr>
    <tr><td>RM</td>
        <td colspan="6">OpCode</td><td colspan="5">Ra</td><td colspan="5">Rb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td>FM</td>
        <td colspan="6">OpCode</td><td colspan="5">Fa</td><td colspan="5">Fb</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td>RJ</td>
        <td colspan="6">OpCode</td><td colspan="1">0</td><td colspan="9">Function</td><td colspan="11">Unused</td><td colspan="5">R</td>
    </tr>
    <tr><td>DJ</td>
        <td colspan="6">OpCode</td><td colspan="1">1</td><td colspan="9">Function</td><td colspan="16">Displacement</td>
    </tr>
</table>

<!--
  31 30 29 28 27 26 25 24 23 22 21 20 19 28 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
RO [     OpCode     ][     Rs      ][     Rt      ][Unused ][0][     Function      ][     Rd      ]
IO [     OpCode     ][     Rs      ][      Immediate       ][1][     Function      ][     Rd      ]
FO [     OpCode     ][     Fs      ][     Ft      ][Unused ][0][     Function      ][     Fd      ]
RM [     OpCode     ][     Ra      ][     Rb      ][                 Displacement                 ]
FM [     OpCode     ][     Fa      ][     Fb      ][                 Displacement                 ]
RJ [     OpCode     ][0][        Function         ][            Unused             ][      R      ]
DJ [     OpCode     ][1][        Function         ][                 Displacement                 ]
-->

Unusedには必ず0を入れるようにする．

別記無い場合は，Rsが入力の左側，ImmediateもしくはRtが入力の右側，Rdが結果．左右というのは各命令に対応する二項演算子を考えた時にどっちに来るかということである（引き算やシフト演算などでは左右の区別が必要）．基本的にImmediateに対しては符号拡張しない．

Displacementは，メモリアドレス（のオフセット）として用いる値で，32bit単位のアクセスしか不要なので，byte単位でのアドレスから下2bitを端折った上で使う．

一つのレジスタしか入力として取らない命令は即値を受け取ることにする（12番目のbitを1）．即値として用いる値は何でも良いはずだが，一応必ず0ということにしておく．

## ニーモニックの記法
### データサイズ
<dl>
    <dt>*u*ni byte</dt>
        <dd>1byte(8bit)</dd>
    <dt>*d*ouble byte</dt>
        <dd>2byte(16bit)</dd>
    <dt>*q*uad byte</dt>
        <dd>4byte(32bit)</dd>
    <dt>*o*cto byte</dt>
        <dd>8byte(64bit)</dd>
</dl>

### 符号
<dl>
    <dt>*u*nsigned</dt>
        <dd>符号無し</dd>
    <dt>*s*igned</dt>
        <dd>符号付き</dd>
</dl>


## 命令一覧

### 算術命令（RO，IO）
#### addqu，addqui
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

32bit符号無し整数同士の加算．下位bitは変化せず，オーバーフローは無視するため，符号付き整数の演算に使っても正しい結果を出す．

#### subqu，subqui
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

32bit符号無し整数同士の減算．下位bitは変化せず，アンダーフローは無視するため，符号付き整数の演算に使っても正しい結果を出す．

#### mulqul，mulquli
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

32bit符号無し整数同士の乗算．下32bitを格納．符号bitによって下位32bitは変化しないため，符号付き整数の演算に使っても正しい結果を出す．

#### mulquh，mulquhi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

符号無し32bit整数同士の乗算．上32bitを格納．

#### mulqsh
<dl>
    <dt>実装箇所</dt>
        <dd>ライブラリ or アセンブラ</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

符号付き32bit整数同士の乗算．上32bitを格納．Alphaのドキュメントに記載の数式参照

#### div
<dl>
    <dt>実装箇所</dt>
        <dd>ライブラリ</dd>
    <dt>実装優先度</dt>
        <dd>最低</dd>
</dl>

除算．詳細未定．


### ビット演算（RO，IO）
#### not，noti
<dl>
    <dt>実装箇所</dt>
        <dd>アセンブラ</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

    nor R0 Rs Rd / nori R0 imm Rd

全てのbitを反転．MinCamlのnotの実装に利用．

#### nor，nori
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

ビットごとのNOR．notの実装のために用いる．

#### and，andi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

ビットごとのAND．

#### or，ori
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

ビットごとのOR．

#### xor，xori
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

ビットごとのXOR．

#### lsftq，lsftqi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

32bit整数に対する左シフト．RtもしくはImmediateは，unsignedとして扱う，つまり単に下6bitだけを用いる．

#### rsftqu，rsftqui
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

32bit整数に対する右論理シフト．シフト量は必ず正で，RtもしくはImmediateの下位5bitだけを用いる．

#### rsftqs，rsftqsi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>余興</dd>
</dl>

32bit整数に対する右算術シフト．シフト量は必ず正で，RtもしくはImmediateの下位5bitだけを用いる．

#### rotq，rotqi
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>最低</dd>
</dl>

32bit整数に対する左循環シフト．シフト量としてRtもしくはImmediateの下位5bitを用いる．循環シフトは32を法として合同な動作をするので，これで正にも負にもシフトできていると言える．

#### clzq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>最低</dd>
</dl>

一入力．Leading Zeroを数える．

#### cppq
<dl>
    <dt>実装箇所</dt><dd>コア</dd>
    <dt>実装優先度</dt><dd>最低</dd>
</dl>

一入力．popcount．

#### mez，mezi
<dl>
    <dt>実装箇所</dt><dd>コア</dd>
    <dt>実装優先度</dt><dd>最低</dd>
</dl>

Rsが0に等しいなら，RdをRtあるいはImmediateで置き換える．

#### mnz，mnzi
<dl>
    <dt>実装箇所</dt><dd>コア</dd>
    <dt>実装優先度</dt><dd>最低</dd>
</dl>

Rsが0に等しくないなら，RdをRtあるいはImmediateで置き換える．


### 浮動小数点演算（FO）
浮動小数点演算の結果の符号をFunctionに埋め込んだ2bitで指定できるようにする．

fmov以外に関しては，「変化なし」のみ必須．

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

#### fadd，faddn，faddp，faddm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

ウッfaddだ．仕様はFPU班と相談．

#### fsub，fsubn，fsubp，fsubm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

ほぼfadd．

#### fmul，fmuln，fmulp，fmulm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

仕様はFPU班と相談．

#### fmov，fmovn，fmovp，fmovm
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

コア班が実装．fmovnはfneg，fmovpはfabs．

#### finv
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

FPU班に任せる．

#### fsqrt
<dl>
    <dt>実装箇所</dt>
        <dd>コア or ライブラリ</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
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


### メモリアクセス命令（RM）
最低限の命令のみ．即値のロード・ストアに対応するには命令フォーマットの変更が必要になりそう．

#### ldq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Rbの下2bitをクリアした上で，Displacementを2bit左にシフトして足しあわせてアドレスを計算．

RaにアドレスをもとにSRAMから取得した値をロード．

#### stq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Rbの下2bitをクリアした上で，Displacementを2bit左にシフトして足しあわせてアドレスを計算．

Raの値をSRAM上のアドレスが指す位置にストア．


### 条件分岐命令（RM）
条件分岐命令によるレジスタ内のアドレスへのジャンプは，ユースケースが無さそうな割に実装するなら考えることがあまりに多いので，サポートしない．

#### beq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Ra = Rb ならジャンプ

#### bne
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

Ra ≠ Rb ならジャンプ

#### blt
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Ra < Rb ならジャンプ

#### blte
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

Ra ≦ Rb ならジャンプ

#### bfeq
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Fa = Fb ならジャンプ

#### bfne
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

Fa ≠Fb ならジャンプ

#### bflt
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

Fa < Fb ならジャンプ

#### bflte
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>高速化</dd>
</dl>

Fa ≦Fb ならジャンプ


### 無条件分岐命令（RJ，DJ）
#### jr，jd
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

R/Displacementにジャンプ．

#### jlr，jld
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

R/Displacementにジャンプ．このとき，PCをリンクレジスタ（R31）にセット．

#### ret
<dl>
    <dt>実装箇所</dt>
        <dd>コア</dd>
    <dt>実装優先度</dt>
        <dd>必須</dd>
</dl>

0入力の命令．リンクレジスタ（R31）にジャンプ．命令フォーマットはDJとし，Displacementは取りあえず必ず0とする．

jrを使ってアセンブラで実装することも可能だが，後々の高速化の可能性のために別命令にする．
