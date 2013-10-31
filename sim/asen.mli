open Type

val change : addr M.t -> expr -> int
val compile : addr M.t -> expr array -> int array
