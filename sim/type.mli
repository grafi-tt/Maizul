module M : Map.S with type key = string

type label = string
type reg = int
type addr = int
type imm = int
type regimm = Reg of reg | Imm of imm
type sign = Straight | Negate | Plus | Minus

type expr =
  | Add of reg * reg * regimm
  | Sub of reg * reg * regimm
  | Eq of reg * reg * regimm
  | Lt of reg * reg * regimm
  | And of reg * reg * regimm
  | Or of reg * reg * regimm
  | Xor of reg * reg * regimm
  | Sll of reg * reg * regimm
  | Srl of reg * reg * regimm
  | Sra of reg * reg * regimm
  | Mul of reg * reg * regimm
  | Cat of reg * reg * regimm
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
  | Bgte of reg * reg * label
  | Fbeq of reg * reg * label
  | Fbne of reg * reg * label
  | Fblt of reg * reg * label
  | Fbgte of reg * reg * label
  | Jmp of reg * reg * label

type top =
  | Toplabel of label
  | Top of expr
