let _ =
  let (env, exprs) = Top.get_top() in
  let insts = Asen.compile env exprs in
  Array.iter Print.print_binary insts
