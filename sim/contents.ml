exception Eval_error

open Type 

let value_to_int x = 
  match x with
    | VInt x -> x 
    | _ -> raise Eval_error

let valut_to_bool x = 
  match x with
    | VBool x -> x 
    | _ -> raise Eval_error

let add x y z = 
  x = VInt ((value_to_int y) + (value_to_int z))

let sub x y z = 
  x = VInt ((value_to_int y) + (value_to_int z))

let equal x y z = 
  if ((value_to_int y) = (value_to_int z)) then 
    x = VInt 1
  else x = VInt 0

let less x y z = 
  if ((value_to_int y) < (value_to_int z)) then
    x = Vint 1
  else x = VInt 0

let nor x y z = 
  x = VInt (lnot((value_to_int y) lor (value_to_int z)))

let _and x y z = 
  x = VInt ((value_to_int y) land (value_to_int z))

let _not x y = 
  x = VInt (lnot(value_to_int y))

let _or x y z = 
  x = VInt ((value_to_int y) lor (value_to_int z))


let rec eval env reg_env expr = 
  match expr with
    | ECosnt a -> a 
    | EVar a -> List.assoc a env
    | EReg a -> List.assoc a reg_en
