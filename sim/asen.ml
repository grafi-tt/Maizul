open Type
open Print

module M =
  Map.Make ( 
    struct 
      type t = Type.label
      let compare = Pervasives.compare
    end )
    
let count = ref (-1)

let change env = function 
  | EAdd (x,y,z) -> 
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 0
  | EAddi (x,y,z) -> 
    (x lsl 21) lor (y lsl 16) lor z
  | ESub (x,y,z) ->
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 1
  | ESubi (x,y,z) -> 
    (1 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | Eq (x,y,z) ->
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 2
  | Eqi (x,y,z) ->
    (2 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | ELess (x,y,z) -> 
    (16 lsl 26) lor (z lsl 21) lor (y lsl 16) lor (z lsl 11) lor 3
  | ELessi (x,y,z) -> 
    (3 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | EOr (x,y,z) -> 
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 5
  | EOri (x,y,z) -> 
    (5 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | EAnd (x,y,z) -> 
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 4
  | EAndi (x,y,z) -> 
    (4 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | EXor (x,y,z) -> 
    (16 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (z lsl 11) lor 6
  | EXori (x,y,z) -> 
    (6 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | ELd (x,y,z) -> 
    (32 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | ESt (x,y,z) ->
    (33 lsl 26) lor (x lsl 21) lor (y lsl 16) lor z
  | EBeq (x,y,z) -> 
    (48 lsl 26) lor (x lsl 21) lor (y lsl 16) lor ((M.find z env) lsl 11) 
  | EBne (x,y,z) -> 
    (49 lsl 26) lor (x lsl 21) lor (y lsl 16) lor ((M.find z env) lsl 11) 
  | EBlt (x,y,z) -> 
    (50 lsl 26) lor (x lsl 21) lor (y lsl 16) lor ((M.find z env) lsl 11) 
  | EJump (x,y,z) -> 
    (20 lsl 26) lor (x lsl 21) lor (y lsl 16) lor (M.find z env)  

let rec g env top_expr = 
  match top_expr with
  | (Toplabel label) :: xs -> 
    if M.mem label env then g env xs
    else incr count ; let new_env = M.add label (!count) env in g new_env xs  
  | (Top expr) :: xs -> print_binary(change env expr) ; g env xs  
  | [] -> ()
    
    
let f top = (g M.empty top) 
