module M : Map.S with type key = string

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

type top =
  | Toplabel of label
  | Top of expr

val dump_expr : expr -> string
val dump_label : label -> string
val dump_comment : string ->  string
