type nop = Nop 


type expr = 
  | ELabel of string
  | EAdd of int * int * int
  | EAddi of int * int * int  
  | ESub of int * int * int
  | ESubi of int * int * int
  | Eq of int * int * int 
  | Eqi of int * int * int 
  | ELess of int * int * int
  | ELessi of int * int * int 
  | ENor of int * int * int
  | ENori of int * int * int
  | EAnd of int * int * int 
  | EAndi of int * int * int
  | ENot of int * int 
  | EOr of int * int * int
  | EOri of int * int * int 
  | ELd of int * int 
  | ESt of int * int
  | EBeq of int * int * string 
  | EBne of int * int * string
  | EBlt of int * int * string
  | EJump of int
  | EJumpl of string 
  | Nop 

exception No_type_error
