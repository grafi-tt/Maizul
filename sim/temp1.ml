let index = ref 0
;;

let env = [|("a",1);("b",2);("c",3);("d",4)|]
;;

let label = "b"
;;

let rec assoc env (*(string * int) array*) label index  =
	try
	match env.(!index) with
	| (lab, imm) -> incr index ; if  label = lab then imm else assoc env label index
	with invalid_argumentwith -> exit 0

in print_int (assoc env label index)
