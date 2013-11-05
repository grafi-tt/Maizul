exception Eval_error

open Type

let get_regimm regimm reg_env =
  match regimm with
    | Reg t -> reg_env.(t)
    | Imm n -> n
      
  (*let put_reg x v reg_env =
    if x != 0
    then reg_env.(x) <- v 
    e lse ()
  *) 
      

let put_reg reg_env reg_num value = 
  if reg_num != 0 
  then reg_env.(reg_num) <- value
  else ()
  
let add reg_env (x,y,z) =
  let v = reg_env.(y) + get_regimm z reg_env
  in put_reg reg_env x v 

let sub reg_env (x,y,z) =
  let v = reg_env.(y) - get_regimm z reg_env
  in put_reg reg_env x v

let eq reg_env (x,y,z) =
  if reg_env.(y) = get_regimm z reg_env
  then put_reg reg_env x 1
  else put_reg reg_env x 0

let lt reg_env (x,y,z) =
  if reg_env.(y) < get_regimm z reg_env
  then put_reg reg_env x 1
  else put_reg reg_env x 0 

let eand reg_env (x,y,z) =
  let v = reg_env.(y) land get_regimm z reg_env
  in put_reg reg_env x v

let eor reg_env (x,y,z) =
  let v = reg_env.(y) lor get_regimm z reg_env
  in put_reg reg_env x v

let xor reg_env (x,y,z) =
  let v = reg_env.(y) lxor get_regimm z reg_env
  in put_reg reg_env x v

let ld memory_env reg_env (x,y,z) =
  let v = memory_env.(reg_env.(y) + z)
  in put_reg reg_env x v

let st memory_env reg_env (x,y,z) =
  memory_env.(reg_env.(y) + z) <- reg_env.(x)

let exec memory_env reg_env env prog =
  let rec eval index =
    let next = index + 1 in
    try
      match prog.(index) with
        | Add (x,y,z) ->
          add reg_env (x,y,z) ; eval next
        | Sub (x,y,z) ->
          sub reg_env (x,y,z) ; eval next
        | Eq (x,y,z) ->
          eq reg_env (x,y,z) ; eval next
        | Lt (x,y,z) ->
          lt reg_env (x,y,z) ; eval next
        | And (x,y,z) ->
          eand reg_env (x,y,z) ; eval next
        | Or (x,y,z) ->
          eor reg_env (x,y,z) ; eval next
        | Xor (x,y,z) ->
          xor reg_env (x,y,z) ; eval next
        | Ld (x,y,z) ->
          ld memory_env reg_env (x,y,z) ; eval next
        | St (x,y,z) ->
          st memory_env reg_env (x,y,z) ; eval next
        | Beq (x,y,z) ->
          if reg_env.(x) = reg_env.(y)
          then eval (M.find z env)
          else eval next
        | Bne (x,y,z) ->
          if reg_env.(x) <> reg_env.(y)
          then eval (M.find z env)
          else eval next
        | Blt (x,y,z) ->
          if reg_env.(x) < reg_env.(y)
          then eval (M.find z env)
          else eval next
        | Jmp (x,y,z) ->
          reg_env.(x) <- next ; eval (reg_env.(y) lor M.find z env)
    with invalid_argumentwith -> exit 0
  in eval 0
