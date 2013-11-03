open Printf

exception Invalid_adressing

module M = Map.Make(String)

type _reg = int
type _imm = int
type _label = string
type opr = [`Reg of _reg | `FReg of _reg | `Imm of _imm | `TextLabel of _label | `DataLabel of _label]
type reg = [`Reg of _reg]
type freg = [`FReg of _reg]
type imm = [`Imm of _imm]
type text_label = [`TextLabel of _label]
type data_label = [`DataLabel of _label]
type reg_imm = [`Reg of _reg | `Imm of _imm | `TextLabel of _label | `DataLabel of _label]
type text_imm = [`Imm of _imm | `TextLabel of _label]
type data_imm = [`Imm of _imm | `DataLabel of _label]

type env = int M.t
type mem_env = int M.t

type word = int
type sign = Straight | Negate | Plus | Minus

type expr =
  | Add of reg * reg * reg_imm
  | Sub of reg * reg * reg_imm
  | Eq  of reg * reg * reg_imm
  | Lt  of reg * reg * reg_imm
  | And of reg * reg * reg_imm
  | Or  of reg * reg * reg_imm
  | Xor of reg * reg * reg_imm
  | Sll of reg * reg * reg_imm
  | Srl of reg * reg * reg_imm
  | Sra of reg * reg * reg_imm
  | Mul of reg * reg * reg_imm
  | Cat of reg * reg * reg_imm
  | Fmovr of reg * freg
  | Ftor  of reg * freg
  | Feq of reg * freg * freg
  | Flt of reg * freg * freg
  | Fadd of freg * freg * freg * sign
  | Fsub of freg * freg * freg * sign
  | Fmul of freg * freg * freg * sign
  | Finv of freg * freg * sign
  | Fsqr of freg * freg * sign
  | Fmov of freg * freg * sign
  | Rmovf of freg * reg * sign
  | Rtof  of freg * reg * sign
  | Ld  of reg * reg * data_imm
  | St  of reg * reg * data_imm
  | Fld of freg * reg * data_imm
  | Fst of freg * reg * data_imm
  | Beq  of reg * reg * text_imm
  | Bne  of reg * reg * text_imm
  | Blt  of reg * reg * text_imm
  | Bgt  of reg * reg * text_imm
  | Fbeq of freg * freg * text_imm
  | Fbne of freg * freg * text_imm
  | Fblt of freg * freg * text_imm
  | Fbgt of freg * freg * text_imm
  | Jmp of reg * reg * text_imm
  | Get  of reg
  | Put  of reg
  | Getb of reg
  | Putb of reg

let reg = function #reg as x -> x | _ -> raise Invalid_adressing
let freg = function #freg as x -> x | _ -> raise Invalid_adressing
let reg_imm = function #reg_imm as x -> x | _ -> raise Invalid_adressing
let text_imm = function #text_imm as x -> x | _ -> raise Invalid_adressing
let data_imm = function #data_imm as x -> x | _ -> raise Invalid_adressing

type mem_expr =
  | Word of word

type top =
  | TopText
  | TopData
  | Toplabel of _label
  | Top of expr
  | TopMem of mem_expr

let dump_opr = function
  | `Reg tag -> "r" ^ string_of_int tag
  | `FReg tag -> "f" ^ string_of_int tag
  | `Imm imm -> string_of_int imm
  | `TextLabel label -> label ^ "@t"
  | `DataLabel label -> label ^ "@d"

let dump_generic1 name a =
  sprintf "%s;\n" (dump_opr a)

let dump_generic2 name a b =
  sprintf "%s\t%s;\n" (dump_opr a) (dump_opr b)

let dump_generic3 name a b c =
  sprintf "%s\t%s\t%s;\n" (dump_opr a) (dump_opr b) (dump_opr c)

let dump_text_mode = ".text\n"
let dump_data_mode = ".data\n"
let dump_label label = label ^ ":\n"
let dump_comment comment = "/*" ^ comment ^ "*/\n"

let dump_expr = function
  | Add (x, y, z) -> dump_generic3 "add" x y z
  | Sub (x, y, z) -> dump_generic3 "sub" x y z
  | Eq  (x, y, z) -> dump_generic3 "eq"  x y z
  | Lt  (x, y, z) -> dump_generic3 "lt"  x y z
  | And (x, y, z) -> dump_generic3 "and" x y z
  | Or  (x, y, z) -> dump_generic3 "or"  x y z
  | Xor (x, y, z) -> dump_generic3 "xor" x y z
  | Sll (x, y, z) -> dump_generic3 "sll" x y z
  | Srl (x, y, z) -> dump_generic3 "srl" x y z
  | Sra (x, y, z) -> dump_generic3 "sra" x y z
  | Mul (x, y, z) -> dump_generic3 "mul" x y z
  | Cat (x, y, z) -> dump_generic3 "cat" x y z
  | Fmovr (x, y) -> dump_generic2 "fmovr" x y
  | Ftor  (x, y) -> dump_generic2 "ftor"  x y
  | Feq (x, y, z) -> dump_generic3 "feq" x y z
  | Flt (x, y, z) -> dump_generic3 "feq" x y z
  | Fadd (x, y, z, Straight) -> dump_generic3 "fadd"  x y z
  | Fadd (x, y, z, Negate)   -> dump_generic3 "faddn" x y z
  | Fadd (x, y, z, Plus)     -> dump_generic3 "faddp" x y z
  | Fadd (x, y, z, Minus)    -> dump_generic3 "faddm" x y z
  | Fsub (x, y, z, Straight) -> dump_generic3 "fsub"  x y z
  | Fsub (x, y, z, Negate)   -> dump_generic3 "fsubn" x y z
  | Fsub (x, y, z, Plus)     -> dump_generic3 "fsubp" x y z
  | Fsub (x, y, z, Minus)    -> dump_generic3 "fsubm" x y z
  | Fmul (x, y, z, Straight) -> dump_generic3 "fmul"  x y z
  | Fmul (x, y, z, Negate)   -> dump_generic3 "fmuln" x y z
  | Fmul (x, y, z, Plus)     -> dump_generic3 "fmulp" x y z
  | Fmul (x, y, z, Minus)    -> dump_generic3 "fmulm" x y z
  | Finv (x, y, Straight)  -> dump_generic2 "finv"   x y
  | Finv (x, y, Negate)    -> dump_generic2 "finvn"  x y
  | Finv (x, y, Plus)      -> dump_generic2 "finvp"  x y
  | Finv (x, y, Minus)     -> dump_generic2 "finvm"  x y
  | Fsqr (x, y, Straight)  -> dump_generic2 "fsqr"   x y
  | Fsqr (x, y, Negate)    -> dump_generic2 "fsqrn"  x y
  | Fsqr (x, y, Plus)      -> dump_generic2 "fsqrp"  x y
  | Fsqr (x, y, Minus)     -> dump_generic2 "fsqrm"  x y
  | Fmov (x, y, Straight)  -> dump_generic2 "fmov"   x y
  | Fmov (x, y, Negate)    -> dump_generic2 "fmovn"  x y
  | Fmov (x, y, Plus)      -> dump_generic2 "fmovp"  x y
  | Fmov (x, y, Minus)     -> dump_generic2 "fmovm"  x y
  | Rmovf (x, y, Straight) -> dump_generic2 "rmovf"  x y
  | Rmovf (x, y, Negate)   -> dump_generic2 "rmovfn" x y
  | Rmovf (x, y, Plus)     -> dump_generic2 "rmovfp" x y
  | Rmovf (x, y, Minus)    -> dump_generic2 "rmovfm" x y
  | Rtof  (x, y, Straight) -> dump_generic2 "rtof"   x y
  | Rtof  (x, y, Negate)   -> dump_generic2 "rtofn"  x y
  | Rtof  (x, y, Plus)     -> dump_generic2 "rtofp"  x y
  | Rtof  (x, y, Minus)    -> dump_generic2 "rtofm"  x y
  | Ld  (x, y, z) -> dump_generic3 "ld"  x y z
  | St  (x, y, z) -> dump_generic3 "st"  x y z
  | Fld (x, y, z) -> dump_generic3 "fld" x y z
  | Fst (x, y, z) -> dump_generic3 "fst" x y z
  | Beq  (x, y, z) -> dump_generic3 "beq"  x y z
  | Bne  (x, y, z) -> dump_generic3 "bne"  x y z
  | Blt  (x, y, z) -> dump_generic3 "blt"  x y z
  | Bgt  (x, y, z) -> dump_generic3 "bgt"  x y z
  | Fbeq (x, y, z) -> dump_generic3 "fbeq" x y z
  | Fbne (x, y, z) -> dump_generic3 "fbne" x y z
  | Fblt (x, y, z) -> dump_generic3 "fblt" x y z
  | Fbgt (x, y, z) -> dump_generic3 "fbgt" x y z
  | Jmp  (x, y, z) -> dump_generic3 "jmp"  x y z
  | Get  (x) -> dump_generic1 "get"  x
  | Put  (x) -> dump_generic1 "put"  x
  | Getb (x) -> dump_generic1 "getb" x
  | Putb (x) -> dump_generic1 "putb" x

let dump_mem_expr = function
  | Word word -> "w" ^ string_of_int word

let construct_env = List.fold_left (fun env (l, i) -> M.add l i env) M.empty
let construct_mem_env = List.fold_left (fun env (l, i) -> M.add l i env) M.empty
let find_env (`TextLabel l) = M.find l
let find_mem_env (`DataLabel l) = M.find l
