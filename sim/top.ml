open Type

let channel =
  if Array.length Sys.argv < 2
  then stdin
  else open_in Sys.argv.(1)

let lexbuf = Lexing.from_channel channel


(*命令をarrayにして環境とともに返す関数*)
let get_top _ =
  let rec loop index env exprs =
    try
      let result = Parser.main Lexer.token lexbuf in
      begin
          match result with
            | Toplabel label -> loop (index + 1) ((label, index) :: env) exprs
            | Top expr -> loop (index + 1) env (expr :: exprs)
      end
    with
      End_of_file -> (
          List.fold_left (fun env (label, expr) -> M.add label expr env) M.empty env,
          Array.of_list (List.rev exprs))
  in loop 0 [] []
