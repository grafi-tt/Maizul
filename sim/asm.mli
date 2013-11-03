open Type

val change : env ->  mem_env -> expr -> int
val compile : env -> expr array -> mem_env -> mem_expr array -> int array
