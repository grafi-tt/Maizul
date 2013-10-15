# CPU実験　コアアーキテクチャ
清水駿介

DEC Alphaベースで部分的にMIPSの予定だったが，もはやどちらの原型も留めていない．

厳密な意味論は書いていないが，曖昧性なく読めるようには書くつもり．不明な点が有れば指摘して欲しい．


## 大まかな仕様
整数レジスタ，浮動小数点レジスタともに，32bitでそれぞれ32個．ビッグエンディアン．R0とF0はゼロ固定．命令は固定長32bit．


## 命令フォーマット
<table>
    <tr><th>Instruction Type</th>
        <th>31</th><th>30</th><th>29</th><th>28</th><th>27</th><th>26</th><th>25</th><th>24</th><th>23</th><th>22</th><th>21</th><th>20</th><th>19</th><th>18</th><th>17</th><th>16</th><th>15</th><th>14</th><th>13</th><th>12</th><th>11</th><th>10</th><th>9</th><th>8</th><th>7</th><th>6</th><th>5</th><th>4</th><th>3</th><th>2</th><th>1</th><th>0</th>
    </tr>
    <tr><td><b>I</b>mmediate-<b>O</b>peration</td>
        <td colspan="2">00</td><td colspan="4">ALUCode</td><td colspan="5">Ra</td><td colspan="5">Rd</td><td colspan="16">Immediate</td>
    </tr>
    <tr><td><b>R</b>egister-<b>O</b>peration</td>
        <td colspan="5">01000</td><td colspan="1">type</td><td colspan="5">Ra/Fa</td><td colspan="5">Rb/Fb</td><td colspan="5">Rd</td><td colspan="7">_</td><td colspan="4">ALUCode</td>
    <tr><td><b>F</b>loat-<b>O</b>peration</td>
        <td colspan="5">01100</td><td colspan="1">type</td><td colspan="5">Ra/Fa</td><td colspan="5">Rb/Fb</td><td colspan="5">Fd</td><td colspan="5">_</td><td colspan="2">sign</td><td colspan="4">FPUCode</td>
    </tr>
    <tr><td><b>J</b>ump</td>
        <td colspan="5">0101</td><td colspan="2">hint</td><td colspan="5">Rt</td><td colspan="5">Rl</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>R</b>egister-<b>S</b>pecial</td>
        <td colspan="5">01001</td><td colspan="1">type</td><td colspan="5">Rx/Fx</td><td colspan="5">Ry</td><td colspan="16">Function</td>
    </tr>
    <tr><td><b>F</b>loat-<b>S</b>pecial</td>
        <td colspan="5">01101</td><td colspan="1">type</td><td colspan="5">Rx/Fx</td><td colspan="5">Fy</td><td colspan="16">Function</td>
    </tr>
    <tr><td><b>D</b>E<b>B</b>UG</td>
        <td colspan="6">011111</td><td colspan="5">00000</td><td colspan="5">00000</td><td colspan="16">Arbitrary Debug Function on Simulator</td>
    </tr>
    <tr><td><b>R</b>egisiter-<b>M</b>emory</td>
        <td colspan="3">100</td><td colspan="3">RMCode</td><td colspan="5">Rm</td><td colspan="5">Rv</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>F</b>loat-<b>M</b>emory</td>
        <td colspan="3">101</td><td colspan="3">FMCode</td><td colspan="5">Rm</td><td colspan="5">Fv</td><td colspan="16">Displacement</td>
    </tr>
    <tr><td><b>R</b>egisiter-<b>B</b>ranch</td>
        <td colspan="3">110</td><td colspan="3">RBCode</td><td colspan="5">Ra</td><td colspan="5">Rb</td><td colspan="16">Target</td>
    </tr>
    <tr><td><b>F</b>loat-<b>B</b>ranch</td>
        <td colspan="3">111</td><td colspan="3">FBCode</td><td colspan="5">Fa</td><td colspan="5">Fb</td><td colspan="16">Target</td>
    </tr>
</table>

<!--
   31 30 29 28 27 26 25 24 23 22 21 20 19 28 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
IO [ 00 ][ ALUcode  ][     Ra      ][     Rd      ][                  Immediate                   ]
RO [    01000    ][t][    Ra/Fa    ][    Rb/Fb    ][     Rd      ][         _         ][ ALUCode  ]
FO [    01100    ][t][    Ra/Fa    ][    Rb/Fb    ][     Fd      ][      _      ][sgn ][ FPUCode  ]
J  [    0101  ][hint][     Rt      ][     Rl      ][                    Target                    ]
RS [    01001    ][t][    Rx/Fx    ][     Ry      ][                   Function                   ]
FS [    01101    ][t][    Rx/Fx    ][     Fy      ][                   Function                   ]
DB [    011111      ][    00000    ][    00000    ][    Arbitrary Debug Function on Simulator     ]
RM [  100  ][RMCode ][     Rm      ][     Rv      ][                 Displacement                 ]
FM [  101  ][FMCode ][     Rm      ][     Fv      ][                 Displacement                 ]
RB [  110  ][RBCode ][     Ra      ][     Rb      ][                    Target                    ]
FB [  111  ][FBCode ][     Fa      ][     Fb      ][                    Target                    ]
-->

### type
入力オペランドが整数か浮動小数点数かを示す．

<dl>
    <dt>type = 0</dt>
        <dd>Ra，Rb，Ryを使用</dd>
    <dt>type = 1</dt>
        <dd>Fa，Fb，Fyを使用</dd>
</dl>

### sign
浮動小数点の演算結果の符号の操作．

<dl>
    <dt>sign = 00</dt>
        <dd>ε 変化なし</dd>
    <dt>sign = 01</dt>
        <dd>negate 反転</dd>
    <dt>sign = 10</dt>
        <dd>plus 正（abs）</dd>
    <dt>sign = 11</dt>
        <dd>minus 負</dd>
</dl>

### hint
jmp命令実行時の分岐予測の方向を示す．まだコアの側で実装していないが，ある程度の高速化には必須だと思うので必ず適切にセットすること．

<dl>
    <dt>hint = 00</dt>
        <dd>命令中の即値にジャンプすると予測．単なるジャンプのときに用いる．</dd>
    <dt>hint = 01</dt>
        <dd>命令中の即値にジャンプしつつ，リンクレジスタとして用いるレジスタに格納する値を，内部的なスタックにプッシュと予測．関数呼び出しのときに用いる．</dd>
    <dt>hint = 10</dt>
        <dd>スタックに積まれた値にジャンプし，スタックをポップすると予測．関数からのリターンのときに用いる．</dd>
    <dt>hint = 11</dt>
        <dd>今のところ未定義．Alphaではコルーチンを実現するような怪しい挙動が定まっていたが，それを実装するメリットも無さそうだし，コンパイラ班と相談ということで．</dd>
</dl>


## 命令一覧

### ALU（RO，IO）

    Rbv := Rb when type == 0
    Rbv := sign_extend(Immediate) when type == 1

とする．

#### add，addi
ALUCode `0000`

    Rd := Ra + Rbv （演算結果の溢れは無視）

#### sub，subi
ALUCode `0001`

    Rd := Ra - Rbv （演算結果の溢れは無視）

#### eq，eqi
ALUCode `0010`

    Rd := Ra == Rbv

#### lt，lti
ALUCode `0011`

    Rd := Ra < (Rb or sign_extend(Immediate)) （符号付き整数として比較）

#### and，andi
ALUCode `0100`

    Rd := Ra & Rbv

#### or，ori
ALUCode `0101`

    Rd := Ra | Rbv

#### xor，xori
ALUCode `0110`

    Rd := Ra ^ Rbv

#### sll，slli
ALUCode `0111`

    Rd := Ra << lower_5bit(Rbv)

#### srl，srli
ALUCode `1000`

    Rd := Ra >> lower_5bit(Rbv) (ただし論理シフト)

#### sra，srai
ALUCode `1001`

    Rd := Ra >> lower_5bit(Rbv) (ただし算術シフト)

#### cat，cati
ALUCode `1010`

   Rd := lower_16bit(Ra) | (lower_16bit(Rbv) << 16)

#### mul，muli
ALUCode `1011`

min-rtに必須ではないけど、これくらいは入れときたい。高速化目指したarchでは省くかも。

    Rd := lower_32bit(Ra * Rbv) （符号付きとしての乗算でも符号無しとしての乗算でも結果は同じ）

#### fmovr
ALUCode `1100`

    Rd := Fa

#### ftor
ALUCode `1101`

1クロックで回るなら実装したい．

    Rd := ftoi(Fa)

#### feq
ALUCode `1110`

    Rd := Fa = Fb

#### flt
ALUCode `1111`

    Rd := Fa < Fb

### FPU（FO）
#### fadd，faddn，faddp，faddm
FPUCode `0000`

    Fd := Fa + Fb

#### fsub，fsubn，fsubp，fdubm
FPUCode `0001`

    Fd := Fa - Fb

faddと同様．

#### fmul，fmuln，fmulp，fmulm
FPUCode `0010`

    Fd := Fa * Fb

仕様はFPU班と相談．

#### finv，finvm，finvp，finvm
FPUCode `0011`

    Fd := 1 / Fa （Fbは0レジスタに固定）

仕様はFPU班と相談．

#### fsqr，fsqrm，fsqrp，fsqrm
FPUCode `0100`

    Fd := √ Fa （Fbは0レジスタに固定）

仕様はFPU班と相談．

#### fmov，fmovn，fmovp，fmovm
FPUCode `0101`

    Fd := Fa（Fbは0レジスタに固定）

コア班が実装．

#### rmovf，rmovfn，rmovfp，rmovfm
FPUCode `0110`

    Fd := Ra（Rbは0レジスタに固定）

コア班が実装．

#### rtof，rtofn，rtofm，rtofm
FPUCode `0111`

    Fd := itof(Fa)

FPU班が変換ルーチンを実装（ソフトウェア実装も可？）

#### fsinなど
FPUCode `1???`

もしハードウェア化するなら


### メモリアクセス命令（RM，FM）
SRAMに対しては内部的には32bit単位のアドレスを用いてアクセスする．

#### ldq，fldq
RMCode `000` / FMCode `000`

    Rv := load_sram(Rb >> 2 & Displacement)
    Fv := load_sram(Rb >> 2 & Displacement)

#### stq，fstq
RMCode `001` / FMCode `001`

    store_sram(Rb >> 2 & Displacement, Rv)
    store_sram(Fb >> 2 & Displacement, Rv)


### 条件分岐命令（RB，FB）
条件分岐命令によるレジスタ内のアドレスへのジャンプは，ユースケースが無さそうなので今のところ未サポートとしておく．

#### beq，fbeq
RBCode `000` / FBCode `000`

    PC := Target if Ra = Rb
    PC := Target if Fa = Fb

#### bne，fbne
RBCode `001` / FBCode `001`

    PC := Target if Ra ≠ Rb
    PC := Target if Fa ≠ Fb

#### blt，fblt
RBCode `010` / FBCode `010`

    PC := Target if Ra < Rb
    PC := Target if Fa < Fb

#### bgte，fbgte
RBCode `011` / FBCode `011`

    PC := Target if Ra ≧ Rb
    PC := Target if Fa ≧ Fb


### 無条件ジャンプ命令（J）
一命令のみ．

#### jmp

    (PC, Rl) := (Rt | Target, PC + 4)


この一命令で，関数呼び出しおよびreturnも実現できる．Rl，Rtがそれぞれ，関数呼び出し時，関数リターン時のリンクレジスタになる．上の方に書いたが，適切にhintをつけないとコアでは低速になる．

RtとTargetをorするという挙動だが，実際にはどちらか片方だけを用いてもう片方を0に固定する使い方を主に想定している．

### 特殊命令（RS，FS）
Functionを広く取ったが，現状シリアル通信のみ．

#### get
Function `0000000000000000` / RS / type = 0

RxをR0に固定

要するに `01001000000xxxxx0000000000000000`で，xxxxxに値を書き込むレジスタの番号を指定．

標準出力なりシリアル通信なりから入力を受け取ってRyの値とする．単なるバイト列として，ビッグエンディアンなので最上位から順に入力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．

#### fget
Function `0000000000000000` / FS / type = 1

FxをF0に固定

要するに `01101100000xxxxx0000000000000000`で，xxxxxに値を書き込むレジスタの番号を指定．

標準出力なりシリアル通信なりから入力を受け取ってFyの値とする．単なるバイト列として，ビッグエンディアンなので最上位から順に入力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．

#### put
Function `0000000000000001` / RS / type = 0

RyをR0に固定

要するに `010010xxxxx000000000000000000001`で，xxxxxに値を読み込むレジスタの番号を指定．

Rxの値を標準出力なりシリアル通信なりに出力する．単なるバイト列として，ビッグエンディアンなので最上位から順に出力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．

#### fput
Function `0000000000000001` / FS / type = 1

FyをF0に固定

要するに `011011xxxxx000000000000000000001`で，xxxxxに値を読み込むレジスタの番号を指定．

Fxの値を標準出力なりシリアル通信なりに出力する．単なるバイト列として，ビッグエンディアンなので最上位から順に出力を行う．コアで実行する際にはこの命令はブロックする（割り込みは未サポート）．
