open Printf

module M = Map.Make(String)

type label = string
type reg = int
type addr = int
type imm = int
type reg_imm = Reg of reg | Imm of imm
type sign = Straight | Negate | Plus | Minus

type expr =
  | Setl of reg * label (* pseudo op *)
  | Add of reg * reg * reg_imm
  | Sub of reg * reg * reg_imm
  | Eq of reg * reg * reg_imm
  | Lt of reg * reg * reg_imm
  | And of reg * reg * reg_imm
  | Or of reg * reg * reg_imm
  | Xor of reg * reg * reg_imm
  | Sll of reg * reg * reg_imm
  | Srl of reg * reg * reg_imm
  | Sra of reg * reg * reg_imm
  | Mul of reg * reg * reg_imm
  | Cat of reg * reg * reg_imm
  | Fmovr of reg * reg
  | Ftor of reg * reg
  | Feq of reg * reg * reg
  | Flt of reg * reg * reg
  | Fadd of reg * reg * reg * sign
  | Fsub of reg * reg * reg * sign
  | Fmul of reg * reg * reg * sign
  | Finv of reg * reg * sign
  | Fsqr of reg * reg * sign
  | Fmov of reg * reg * sign
  | Rmovf of reg * reg * sign
  | Rtof of reg * reg * sign
  | Ld of reg * addr * imm
  | St of reg * addr * imm
  | Fld of reg * addr * imm
  | Fst of reg * addr * imm
  | Beq of reg * reg * label
  | Bne of reg * reg * label
  | Blt of reg * reg * label
  | Bgt of reg * reg * label
  | Fbeq of reg * reg * label
  | Fbne of reg * reg * label
  | Fblt of reg * reg * label
  | Fbgt of reg * reg * label
  | Jmp of reg * reg * label
  | Get of reg
  | Put of reg
  | Getb of reg
  | Putb of reg

type top =
  | Toplabel of label
  | Top of expr

let dump_expr = function
  | Setl(x, y) -> sprintf "setl\t%d\t%s;;\n" x y
  | Add(x, y, Reg z) -> sprintf "add\t%d\t%d\t%d;;\n" x y z
  | Add(x, y, Imm z) -> sprintf "addi\t%d\t%d\t%d;;\n" x y z
  | Sub(x, y, Reg z) -> sprintf "sub\t%d\t%d\t%d;;\n" x y z
  | Sub(x, y, Imm z) -> sprintf "subi\t%d\t%d\t%d;;\n" x y z
  | Eq(x, y, Reg z) -> sprintf "eq\t%d\t%d\t%d;;\n" x y z
  | Eq(x, y, Imm z) -> sprintf "eqi\t%d\t%d\t%d;;\n" x y z
  | Lt(x, y, Reg z) -> sprintf "lt\t%d\t%d\t%d;;\n" x y z
  | Lt(x, y, Imm z) -> sprintf "lti\t%d\t%d\t%d;;\n" x y z
  | And(x, y, Reg z) -> sprintf "and\t%d\t%d\t%d;;\n" x y z
  | And(x, y, Imm z) -> sprintf "andi\t%d\t%d\t%d;;\n" x y z
  | Or(x, y, Reg z) -> sprintf "or\t%d\t%d\t%d;;\n" x y z
  | Or(x, y, Imm z) -> sprintf "ori\t%d\t%d\t%d;;\n" x y z
  | Xor(x, y, Reg z) -> sprintf "xor\t%d\t%d\t%d;;\n" x y z
  | Xor(x, y, Imm z) -> sprintf "xori\t%d\t%d\t%d;;\n" x y z
  | Sll(x, y, Reg z) -> sprintf "sll\t%d\t%d\t%d;;\n" x y z
  | Sll(x, y, Imm z) -> sprintf "slli\t%d\t%d\t%d;;\n" x y z
  | Srl(x, y, Reg z) -> sprintf "srl\t%d\t%d\t%d;;\n" x y z
  | Srl(x, y, Imm z) -> sprintf "srl\t%d\t%d\t%d;;\n" x y z
  | Sra(x, y, Reg z) -> sprintf "sra\t%d\t%d\t%d;;\n" x y z
  | Sra(x, y, Imm z) -> sprintf "srai\t%d\t%d\t%d;;\n" x y z
  | Mul(x, y, Reg z) -> sprintf "mul\t%d\t%d\t%d;;\n" x y z
  | Mul(x, y, Imm z) -> sprintf "muli\t%d\t%d\t%d;;\n" x y z
  | Cat(x, y, Reg z) -> sprintf "cat\t%d\t%d\t%d;;\n" x y z
  | Cat(x, y, Imm z) -> sprintf "cati\t%d\t%d\t%d;;\n" x y z
  | Fmovr(x, y) -> sprintf "fmovr\t%d\t%d;;\n" x y
  | Ftor(x, y) -> sprintf "ftor\t%d\t%d;;\n" x y
  | Feq(x, y, z) -> sprintf "feq\t%d\t%d\t%d;;\n" x y z
  | Flt(x, y, z) -> sprintf "feq\t%d\t%d\t%d;;\n" x y z
  | Fadd(x, y, z, Straight) -> sprintf "fadd\t%d\t%d\t%d;;\n" x y z
  | Fadd(x, y, z, Negate) -> sprintf "faddn\t%d\t%d\t%d;;\n" x y z
  | Fadd(x, y, z, Plus) -> sprintf "faddp\t%d\t%d\t%d;;\n" x y z
  | Fadd(x, y, z, Minus) -> sprintf "faddm\t%d\t%d\t%d;;\n" x y z
  | Fsub(x, y, z, Straight) -> sprintf "fsub\t%d\t%d\t%d;;\n" x y z
  | Fsub(x, y, z, Negate) -> sprintf "fsubn\t%d\t%d\t%d;;\n" x y z
  | Fsub(x, y, z, Plus) -> sprintf "fsubp\t%d\t%d\t%d;;\n" x y z
  | Fsub(x, y, z, Minus) -> sprintf "fsubm\t%d\t%d\t%d;;\n" x y z
  | Fmul(x, y, z, Straight) -> sprintf "fmul\t%d\t%d\t%d;;\n" x y z
  | Fmul(x, y, z, Negate) -> sprintf "fmuln\t%d\t%d\t%d;;\n" x y z
  | Fmul(x, y, z, Plus) -> sprintf "fmulp\t%d\t%d\t%d;;\n" x y z
  | Fmul(x, y, z, Minus) -> sprintf "fmulm\t%d\t%d\t%d;;\n" x y z
  | Finv(x, y, Straight) -> sprintf "finv\t%d\t%d;;\n" x y
  | Finv(x, y, Negate) -> sprintf "finvn\t%d\t%d;;\n" x y
  | Finv(x, y, Plus) -> sprintf "finvp\t%d\t%d;;\n" x y
  | Finv(x, y, Minus) -> sprintf "finvm\t%d\t%d;;\n" x y
  | Fsqr(x, y, Straight) -> sprintf "fsqr\t%d\t%d;;\n" x y
  | Fsqr(x, y, Negate) -> sprintf "fsqrn\t%d\t%d;;\n" x y
  | Fsqr(x, y, Plus) -> sprintf "fsqrp\t%d\t%d;;\n" x y
  | Fsqr(x, y, Minus) -> sprintf "fsqrm\t%d\t%d;;\n" x y
  | Fmov(x, y, Straight) -> sprintf "fmov\t%d\t%d;;\n" x y
  | Fmov(x, y, Negate) -> sprintf "fmovn\t%d\t%d;;\n" x y
  | Fmov(x, y, Plus) -> sprintf "fmovp\t%d\t%d;;\n" x y
  | Fmov(x, y, Minus) -> sprintf "fmovm\t%d\t%d;;\n" x y
  | Rmovf(x, y, Straight) -> sprintf "rmovf\t%d\t%d;;\n" x y
  | Rmovf(x, y, Negate) -> sprintf "rmovfn\t%d\t%d;;\n" x y
  | Rmovf(x, y, Plus) -> sprintf "rmovfp\t%d\t%d;;\n" x y
  | Rmovf(x, y, Minus) -> sprintf "rmovfm\t%d\t%d;;\n" x y
  | Rtof(x, y, Straight) -> sprintf "rtof\t%d\t%d;;\n" x y
  | Rtof(x, y, Negate) -> sprintf "rtofn\t%d\t%d;;\n" x y
  | Rtof(x, y, Plus) -> sprintf "rtofp\t%d\t%d;;\n" x y
  | Rtof(x, y, Minus) -> sprintf "rtofm\t%d\t%d;;\n" x y
  | Ld(x, y, z) -> sprintf "ld\t%d\t%d\t%d;;\n" x y z
  | St(x, y, z) -> sprintf "st\t%d\t%d\t%d;;\n" x y z
  | Fld(x, y, z) -> sprintf "fld\t%d\t%d\t%d;;\n" x y z
  | Fst(x, y, z) -> sprintf "fst\t%d\t%d\t%d;;\n" x y z
  | Beq(x, y, z) -> sprintf "beq\t%d\t%d\t%s;;\n" x y z
  | Bne(x, y, z) -> sprintf "bne\t%d\t%d\t%s;;\n" x y z
  | Blt(x, y, z) -> sprintf "blt\t%d\t%d\t%s;;\n" x y z
  | Bgt(x, y, z) -> sprintf "bgt\t%d\t%d\t%s;;\n" x y z
  | Fbeq(x, y, z) -> sprintf "fbeq\t%d\t%d\t%s;;\n" x y z
  | Fbne(x, y, z) -> sprintf "fbne\t%d\t%d\t%s;;\n" x y z
  | Fblt(x, y, z) -> sprintf "fblt\t%d\t%d\t%s;;\n" x y z
  | Fbgt(x, y, z) -> sprintf "fbgt\t%d\t%d\t%s;;\n" x y z
  | Jmp(x, y, z) -> sprintf "jmp\t%d\t%d\t%s;;\n" x y z
  | Get(x) -> sprintf "get\t%d;;\n" x
  | Put(x) -> sprintf "put\t%d;;\n" x
  | Getb(x) -> sprintf "getb\t%d;;\n" x
  | Putb(x) -> sprintf "putb\t%d;;\n" x

let dump_label s = sprintf "%s:\n" s

let dump_comment s = sprintf "/* %s */\n" s
