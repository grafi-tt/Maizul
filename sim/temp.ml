let index  = ref 0

let ary = [|1;2;3;4;5|]
;;

let rec find l count sum  =
try
match l.(!count) with	 
	| x -> incr count ; let new_sum = sum + x in find l count new_sum 
with invalid_argumentwith -> sum 
in print_int (find ary index 0) 
