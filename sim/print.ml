(*バイナリの機械語を標準出力するための関数*) 

(*数字を受け取りバイナリに直してリストでもつ関数*)
let bin num =  
  let rec f n l = 
    if n <= 1 then n :: l 
    else let r = n mod 2 in let new_l = r :: l in f (n/2) new_l 
  in f num [] 

let rec print l = 
  match l with
    | [] -> () 
    | x :: xs -> print_int x; print xs

let print_binary number = (print (bin number))
