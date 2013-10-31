let _ =
  let memory_env = Array.make 65536 0 in
  let reg_env = Array.make 32 0 in
  let (env, exprs) = Top.get_top() in
  Eval.exec memory_env reg_env env exprs
