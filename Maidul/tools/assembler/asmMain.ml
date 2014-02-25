let _ =
  let (env, exprs, menv, mexprs) = Top.get_top() in
  let insts = Asm.compile env exprs menv mexprs in
  Array.iter Print.print_binary insts
