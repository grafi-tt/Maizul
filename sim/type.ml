type nop = Nop 
type label = string
type reg = int
type addr = int
type imm8 = int



type top = 
  | Toplabel of label 
  | Top of expr

and expr = 
  | EAdd of reg * reg * reg
  | EAddi of reg * reg * imm8  
  | ESub of reg * reg * reg
  | ESubi of reg * reg * imm8
  | Eq of reg * reg * reg 
  | Eqi of reg * reg * imm8 
  | ELess of reg * reg * reg
  | ELessi of reg * reg * imm8 
  | ENor of reg * reg * reg
  | ENori of reg * reg * imm8
  | EAnd of reg * reg * reg 
  | EAndi of reg * reg * imm8
  | ENot of reg * reg 
  | EOr of reg * reg * reg
  | EOri of reg * reg * imm8
  | EXor of reg * reg * reg
  | EXori of reg * reg * imm8 
  | ELd of reg * addr * imm8
  | ESt of reg * addr * imm8 
  | EBeq of reg * reg * label
  | EBne of reg * reg * label
  | EBlt of reg * reg * label
  | EJump of reg * reg * label 
  | Nop 

exception No_type_error
