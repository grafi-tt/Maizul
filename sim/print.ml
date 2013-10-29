exception Num_error

(*バイナリの機械語を標準出力するための関数*) 

(*数字を受け取りバイナリに直してリストでもつ関数*)
let bin num =  
  let rec f n l = 
    if n <= 1 then n :: l 
    else let r = n mod 2 in let new_l = r :: l in f (n/2) new_l 
  in f num [] 

(*32bit命令なので32要素のリストに直す関数*)
let make_32 l =
  let count = 32 - List.length l in
  if count < 0 then
    raise Num_error
  else
  let rec sub_make_32 ls index = 
    if index < count then 
      sub_make_32 (0::ls) (index+1) 
    else ls
  in sub_make_32 l 0
  

let rec print l = 
  match l with
    | [] -> () 
    | x :: xs -> print_int x; print xs

let print_binary number = (print (make_32(bin number)))
