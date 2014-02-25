open Type

exception Invalid_section

let channel =
  if Array.length Sys.argv < 2
  then stdin
  else open_in Sys.argv.(1)

let lexbuf = Lexing.from_channel channel

type section = Text | Data
type state = {
  section : section;
  ix : int;
  env : (_label * int) list;
  exprs : expr list;
  mix : int;
  menv : (_label * int) list;
  mexprs : mem_expr list;
}

(*命令をarrayにして環境とともに返す関数*)
let get_top _ =
  let rec loop st =
    try
      let result = Parser.main Lexer.token lexbuf in
      match st.section, result with
        | Text, Toplabel label -> loop { st with env = (label, st.ix) :: st.env }
        | Data, Toplabel label -> loop { st with menv = (label, st.mix) :: st.menv }
        | Text, Top expr -> loop { st with ix = st.ix + 1; exprs = expr :: st.exprs }
        | Data, TopMem mexpr -> loop {st with mix = st.mix + 1; mexprs = mexpr :: st.mexprs }
        | _, TopText -> loop { st with section = Text }
        | _, TopData -> loop { st with section = Data }
        | _, _ -> raise Invalid_section
    with
      End_of_file -> (
          construct_env st.env,
          Array.of_list (List.rev st.exprs),
          construct_mem_env st.menv,
          Array.of_list (List.rev st.mexprs))
  in loop { section = Text; ix = 0; env = []; exprs = []; mix = 0; menv = []; mexprs = [] }
