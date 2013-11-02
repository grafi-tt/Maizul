open Type
open Print

let change_alu alucode d a = function
  | Reg b -> (0b010000 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor alucode
  | Imm b -> (alucode lsl 26) lor (a lsl 21) lor (d lsl 16) lor b

let change_aluf alucode d a b = (0b010001 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor alucode

let change_generic opcode x y imm = (opcode lsl 26) lor (x lsl 21) lor (y lsl 16) lor imm

(* TODO: FPU op *)
let change env = function
  | Setl (d, label) -> change_generic 0b000101 0 d (M.find label env)
  | Add (d, a, b) -> change_alu 0b0000 d a b
  | Sub (d, a, b) -> change_alu 0b0001 d a b
  | Eq  (d, a, b) -> change_alu 0b0010 d a b
  | Lt  (d, a, b) -> change_alu 0b0011 d a b
  | And (d, a, b) -> change_alu 0b0100 d a b
  | Or  (d, a, b) -> change_alu 0b0101 d a b
  | Xor (d, a, b) -> change_alu 0b0110 d a b
  | Sll (d, a, b) -> change_alu 0b0111 d a b
  | Srl (d, a, b) -> change_alu 0b1000 d a b
  | Sra (d, a, b) -> change_alu 0b1001 d a b
  | Cat (d, a, b) -> change_alu 0b1010 d a b
  | Mul (d, a, b) -> change_alu 0b1011 d a b
  | Fmovr (d, a)    -> change_aluf 0b1100 d a 0
  | Ftor  (d, a)    -> change_aluf 0b1101 d a 0
  | Feq   (d, a, b) -> change_aluf 0b1110 d a b
  | Flt   (d, a, b) -> change_aluf 0b1111 d a b
  | Ld  (v, m, d) -> change_generic 0b100000 m v d
  | St  (v, m, d) -> change_generic 0b100001 m v d
  | Fld (v, m, d) -> change_generic 0b101000 m v d
  | Fst (v, m, d) -> change_generic 0b101001 m v d
  | Beq  (a, b, label) -> change_generic 0b110000 a b (M.find label env)
  | Bne  (a, b, label) -> change_generic 0b110001 a b (M.find label env)
  | Blt  (a, b, label) -> change_generic 0b110010 a b (M.find label env)
  | Bgt  (a, b, label) -> change_generic 0b110011 a b (M.find label env)
  | Fbeq (a, b, label) -> change_generic 0b111000 a b (M.find label env)
  | Fbne (a, b, label) -> change_generic 0b111001 a b (M.find label env)
  | Fblt (a, b, label) -> change_generic 0b111010 a b (M.find label env)
  | Fbgt (a, b, label) -> change_generic 0b111011 a b (M.find label env)
  | Jmp  (l, t, label) -> change_generic 0b010100 t l (M.find label env)

let compile env exprs = Array.map (change env) exprs
