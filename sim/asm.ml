open Type
open Print

type some_reg = [`Reg of _reg | `FReg of _reg]

let limit_16bit = function
  | d when -0x8000 <= d && d < 0x8000 -> d land 0xFFFF
  | _ -> raise (Invalid_argument "too large immediate")

let split_32bit = function
  | d when -0x80000000 <= d && d < 0x100000000 -> ((d lor -(d land 0x80000000)) asr 16, (d land 0xFFFF) lor -(d land 0x8000))
  | _ -> raise (Invalid_argument "too large memory word")

let change_alu env menv alucode (`Reg d) a b =
  match (a :> some_reg), (b :> opr) with
    | `Reg a, `Reg b -> (0b010000 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor alucode
    | `Reg a, `Imm b -> (alucode lsl 26) lor (a lsl 21) lor (d lsl 16) lor (limit_16bit b)
    | `Reg a, (`TextLabel _ as b) -> (alucode lsl 26) lor (a lsl 21) lor (d lsl 16) lor (limit_16bit (find_env b env))
    | `Reg a, (`DataLabel _ as b) -> (alucode lsl 26) lor (a lsl 21) lor (d lsl 16) lor (limit_16bit (find_mem_env b menv))
    | `FReg a, `FReg b -> (0b010001 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor alucode
    | _ -> raise (Invalid_argument "invalid source of alu")

let change_fpu fpucode (`FReg d) a b sign =
  let funct = match sign with
    | Straight -> 0b00
    | Negate -> 0b01
    | Plus -> 0b10
    | Minus -> 0b11
  in match (a :> some_reg), (b :> some_reg) with
    | `Reg a, `Reg b -> (0b011000 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor (funct lsl 4) lor fpucode
    | `FReg a, `FReg b -> (0b011001 lsl 26) lor (a lsl 21) lor (b lsl 16) lor (d lsl 11) lor (funct lsl 4) lor fpucode
    | _ -> raise (Invalid_argument "invalid source of fpu")

let change_generic env menv opcode x y imm =
  match x with `Reg x | `FReg x ->
  match y with `Reg y | `FReg y ->
  let imm = match imm with
    | `TextLabel _ as l -> find_env l env
    | `DataLabel _ as l -> find_mem_env l menv
    | `Imm i -> i
  in (opcode lsl 26) lor (x lsl 21) lor (y lsl 16) lor (limit_16bit imm)

(* TODO: FPU op *)
let change env menv = function
  | Add (d, a, b) -> change_alu env menv 0b0000 d a b
  | Sub (d, a, b) -> change_alu env menv 0b0001 d a b
  | Eq  (d, a, b) -> change_alu env menv 0b0010 d a b
  | Lt  (d, a, b) -> change_alu env menv 0b0011 d a b
  | And (d, a, b) -> change_alu env menv 0b0100 d a b
  | Or  (d, a, b) -> change_alu env menv 0b0101 d a b
  | Xor (d, a, b) -> change_alu env menv 0b0110 d a b
  | Sll (d, a, b) -> change_alu env menv 0b0111 d a b
  | Srl (d, a, b) -> change_alu env menv 0b1000 d a b
  | Sra (d, a, b) -> change_alu env menv 0b1001 d a b
  | Cat (d, a, b) -> change_alu env menv 0b1010 d a b
  | Mul (d, a, b) -> change_alu env menv 0b1011 d a b
  | Fmovr (d, a)    -> change_alu env menv 0b1100 d a (`FReg 0)
  | Ftor  (d, a)    -> change_alu env menv 0b1101 d a (`FReg 0)
  | Feq   (d, a, b) -> change_alu env menv 0b1110 d a b
  | Flt   (d, a, b) -> change_alu env menv 0b1111 d a b
  | Ld  (v, m, d) -> change_generic env menv 0b100000 m v d
  | St  (v, m, d) -> change_generic env menv 0b100001 m v d
  | Fld (v, m, d) -> change_generic env menv 0b101000 m v d
  | Fst (v, m, d) -> change_generic env menv 0b101001 m v d
  | Fadd (d, a, b, sign) -> change_fpu 0b0000 d a b sign
  | Fsub (d, a, b, sign) -> change_fpu 0b0001 d a b sign
  | Fmul (d, a, b, sign) -> change_fpu 0b0010 d a b sign
  | Finv (d, a, sign) -> change_fpu 0b0011 d a (`FReg 0) sign
  | Fsqr (d, a, sign) -> change_fpu 0b0100 d a (`FReg 0) sign
  | Fmov (d, a, sign) -> change_fpu 0b0101 d a (`FReg 0) sign
  | Rmovf (d, a, sign) -> change_fpu 0b0110 d a (`Reg 0) sign
  | Rtof  (d, a, sign) -> change_fpu 0b0111 d a (`Reg 0) sign
  | Beq  (a, b, label) -> change_generic env menv 0b110000 a b label
  | Bne  (a, b, label) -> change_generic env menv 0b110001 a b label
  | Blt  (a, b, label) -> change_generic env menv 0b110010 a b label
  | Bgt  (a, b, label) -> change_generic env menv 0b110011 a b label
  | Fbeq (a, b, label) -> change_generic env menv 0b111000 a b label
  | Fbne (a, b, label) -> change_generic env menv 0b111001 a b label
  | Fblt (a, b, label) -> change_generic env menv 0b111010 a b label
  | Fbgt (a, b, label) -> change_generic env menv 0b111011 a b label
  | Jmp  (l, t, label) -> change_generic env menv 0b010100 t l label
  | Get  (y) -> change_generic env menv 0b010010 (`Reg 0) y (`Imm 0b00)
  | Put  (x) -> change_generic env menv 0b010010 x (`Reg 0) (`Imm 0b01)
  | Getb (y) -> change_generic env menv 0b010010 (`Reg 0) y (`Imm 0b10)
  | Putb (x) -> change_generic env menv 0b010010 x (`Reg 0) (`Imm 0b11)

let change_data_section ary =
  let expAry = Array.make (Array.length ary * 3) (Add (`Reg 0, `Reg 0, `Reg 0)) in
  Array.iteri (fun i (Word w) ->
    let h, l = split_32bit w in
    expAry.(i * 3) <- Or (`Reg 1, `Reg 0, `Imm l);
    expAry.(i * 3 + 1) <- Cat (`Reg 1, `Reg 1, `Imm h);
    expAry.(i * 3 + 2) <- St (`Reg 1, `Reg 0, `Imm i);
  ) ary;
  expAry

let compile env exprs menv mexprs = Array.map (change env menv) (Array.append (change_data_section mexprs) exprs)
