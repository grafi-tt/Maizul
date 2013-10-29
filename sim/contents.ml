exception Eval_error

open Type 

let count = ref 0

(*labelの環境envは (string * int) arrayの型なので連想リストっぽくintを返す関数をつくったが頭が悪い気がする*)
let rec array_assoc env label index = 
  try 
    match env.(!index) with
      | (lab,immi) ->
	incr index ; 
	if label = lab then immi else array_assoc env label index 
  with  invalid_argumentwith -> exit 0 

(*とりあえず作ったが、連想リストとほぼ変わらないので、とりあえずenvはリストにする*)


let add reg_env (x,y,z) =
  reg_env.(x) <- reg_env.(y) + reg_env.(z)  
    
let addi reg_env (x,y,z) = 
  reg_env.(x) <- reg_env.(y) + z
    
let sub reg_env (x,y,z) =
  reg_env.(x) <- reg_env.(y) - reg_env.(z)

let subi reg_env (x,y,z) =
  reg_env.(x) <- reg_env.(y) - z

let eq reg_env (x,y,z) =
  if reg_env.(y) = reg_env.(z) then 
    reg_env.(x) <- 1 
  else reg_env.(x) <- 0

let eqi reg_env (x,y,z) = 
  if reg_env.(y) = z then 
    reg_env.(x) <- 1 
  else reg_env.(x) <- 0

let less reg_env (x,y,z) = 
  if reg_env.(y) < reg_env.(z) then 
    reg_env.(x) <- 1
  else reg_env.(x) <- 0

let lessi reg_env (x,y,z) = 
  if reg_env.(y) < z then 
    reg_env.(x) <- 1
  else reg_env.(x) <- 0

let nor reg_env (x,y,z) = 
  reg_env.(x) <- lnot((reg_env.(y)) lor (reg_env.(z))) 

let nori reg_env (x,y,z) = 
  reg_env.(x) <- lnot((reg_env.(y)) lor z)

let eand reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y)) land ( reg_env.(z)) 

let eandi reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y) land z) 

let enot reg_env (x,y) = 
  reg_env.(x) <- lnot(reg_env.(y)) 

let eor reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y) lor reg_env.(z)) 

let eori reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y) lor z) 

let xor reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y) lxor reg_env.(z)) 

let xori reg_env (x,y,z) = 
  reg_env.(x) <- (reg_env.(y) lxor z) 

let ld memory_env reg_env (x,y,z) = 
  reg_env.(x) <- memory_env.(reg_env.(y) + z) 

let st memory_env reg_env (x,y,z) = 
  memory_env.(reg_env.(y) + z) <- reg_env.(x)

let rec eval env memory_env reg_env expr index=
  try 
    match expr.(!index) with
      | EAdd (x,y,z) -> incr index ;
	add reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EAddi (x,y,z) -> incr index ; 
	addi reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ESub (x,y,z) -> incr index ;
	sub reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ESubi (x,y,z) -> incr index ; 
	subi reg_env (x,y,z) ; eval env memory_env reg_env expr index 
      | Eq (x,y,z) -> incr index ; 
	eq reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | Eqi (x,y,z) -> incr index ; 
	eqi reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ELess (x,y,z) -> incr index ; 
	less reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ELessi (x,y,z) -> incr index ; 
	lessi reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ENor (x,y,z) -> incr index ; 
	nor reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ENori (x,y,z) -> incr index ; 
	nori reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EAnd (x,y,z) -> incr index ; 
	eand reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EAndi (x,y,z) -> incr index ; 
	eandi reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ENot (x,y) -> incr index ; 
	enot reg_env (x,y) ; eval env memory_env reg_env expr index
      | EOr (x,y,z) -> incr index ; 
	eor reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EOri (x,y,z) -> incr index ; 
	eori reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EXor (x,y,z) -> incr index ; 
	xor reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EXori (x,y,z) -> incr index ; 
	xori reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ELd (x,y,z) -> incr index ; 
	ld memory_env reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | ESt (x,y,z) -> incr index ; 
	st memory_env reg_env (x,y,z) ; eval env memory_env reg_env expr index
      | EBeq (x,y,z) -> incr index ;  
	if reg_env.(x) = reg_env.(y) then
	  (index := List.assoc z env ; eval env memory_env reg_env expr index)
	else eval env memory_env reg_env expr index
      | EBne (x,y,z) -> incr index ; 
	if reg_env.(x) <> reg_env.(y) then 
	  (index := List.assoc z env ; eval env memory_env reg_env expr index)
	else eval env memory_env reg_env expr index 
      | EBlt (x,y,z) -> incr index ;
	if reg_env.(x) < reg_env.(y) then 
	  (index := List.assoc z env ; eval env memory_env reg_env expr index)
	else eval env memory_env reg_env expr index
      | EJump (x,y,z) -> incr index;
	reg_env.(x) <- (!index) ; 
	(index := reg_env.(y) lor List.assoc z env)  ; 
	eval env memory_env reg_env expr index
      | Nop  -> incr index ;  eval env memory_env reg_env expr index 
  with invalid_argumentwith -> exit 0 
    
    
