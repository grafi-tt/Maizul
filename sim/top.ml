open Type

let count = ref (-1)

let channel =
  if Array.length Sys.argv < 2 then stdin
  else open_in Sys.argv.(1)
;;
let lexbuf = Lexing.from_channel channel
;;



(*命令をarrayにして環境とともに返す関数*)
let get_list lex =
  let rec loop (top,env) index =
    try
      let result =
	Parser.main Lexer.token lex in
      match result with
	| Toplabel (label) -> incr index ;
	  let new_env = (label, (!index)) :: env in
	  loop ((Toplabel (label))::top, new_env) index
	| Top (expr) -> incr index ;
	  loop ((Top (expr))::top, env) index
    with
	End_of_file -> (Array.of_list (List.rev top), env)
  in loop ([],[]) count
in get_list lexbuf
