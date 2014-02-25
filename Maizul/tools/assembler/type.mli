exception Invalid_adressing

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

type env
type mem_env

type word = int
type sign = Straight | Negate | Plus | Minus
type hint = Jump | Call | Return

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
  | Fflr of freg * freg * sign
  | Rtof of freg * reg * sign
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
  | Jmp of reg * reg * text_imm * hint
  | Get  of reg
  | Put  of reg
  | Getb of reg
  | Putb of reg

val reg : opr -> reg
val freg : opr -> freg
val reg_imm : opr -> reg_imm
val text_imm : opr -> text_imm
val data_imm : opr -> data_imm

type mem_expr =
  | Word of word

type top =
  | TopText
  | TopData
  | Toplabel of _label
  | Top of expr
  | TopMem of mem_expr

val dump_text_mode : string
val dump_data_mode : string
val dump_label : _label -> string
val dump_comment : string ->  string
val dump_expr : expr -> string
val dump_mem_expr : mem_expr -> string

val construct_env : (_label * int) list -> env
val construct_mem_env : (_label * int) list -> mem_env
val find_env : text_label -> env -> int
val find_mem_env : data_label -> mem_env -> int
