type value = VInt of int | Nop | VLabel of string 

and reg = VReg of int 

and adrs = VAdrs of int

and expr = 
  | EConst of value 
  | ELabel of string 
  | EAdd of reg * reg * reg
  | EAddi of reg * reg * value  
  | ESub of reg * reg * reg
  | ESubi of reg * reg * int 
  | Eq of reg * reg * reg 
  | Eqi of reg * reg * int 
  | ELess of reg * reg * reg
  | ELessi of reg * reg * int 
  | ENor of reg * reg * reg
  | ENori of reg * reg * int 
  | EAnd of reg * reg * reg 
  | EAndi of reg * reg * int 
  | EOr of reg * reg * reg
  | EOri of reg * reg * int 
  | ELd of reg * adrs
  | ESt of reg * adrs
  | EBeq of reg * reg * string
  | EBne of reg * reg * string
  | EBlt of reg * reg * string
  | EJump of adrs
  | EJumpi of string 
 
and num = 
  | ENum of int 

 
exception No_type_error
