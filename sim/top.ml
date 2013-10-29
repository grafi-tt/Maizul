open Type

let count = ref (-1)

let channel = 
  if Array.length Sys.argv < 2 then stdin 
  else open_in Sys.argv.(1) 
;;
let lexbuf = Lexing.from_channel channel
;;

let get_list l = 
  let rec loop env index =
    try 
      let result = 
	Parser.main Lexer.token l in
      match result with
	| Toplabel (label) -> 
	  incr index ; let new_env = (label, (!index)) :: env in 
		       (Toplabel (label)) :: loop new_env index 
	| Top (expr) -> 
	  incr index ; (Top (expr)) :: loop env index 
    with
	End_of_file -> [] 
  in loop [] count
in get_list lexbuf


