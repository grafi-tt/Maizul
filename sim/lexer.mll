{
  open Parser
}

let natural = ['1' - '9']
let digit = ['0' - '9']
let tag = ['1' '2']? ['0' - '9'] | '3' ['0' '1']
let minimoji = ['a' - 'z']
let capital = ['A' - 'Z']
let moji = ['a' - 'z' 'A' - 'Z' '0' - '9' '_']

rule token = parse
  | [' ' '\t' '\n']* { token lexbuf }
  | ";;"        { EOL }
  | (moji+ as l) ':' { LABEL l }
  | 'r' (tag as x) { OPR (`Reg (int_of_string x)) }
  | 'f' (tag as x) { OPR (`FReg (int_of_string x)) }
  | (moji + as l) "@t" { OPR (`TextLabel l) }
  | (moji + as l) "@d" { OPR (`DataLabel l) }
  | "add"       { ADD }
  | "sub"       { SUB }
  | "eq"        { EQ }
  | "lt"        { LT }
  | "and"       { AND }
  | "or"        { OR }
  | "xor"       { XOR }
  | "sll"       { SLL }
  | "srl"       { SRL }
  | "sra"       { SRA }
  | "cat"       { CAT }
  | "mul"       { MUL }
  | "fmovr"     { FMOVR }
  | "ftor"      { FTOR }
  | "feq"       { FEQ }
  | "flt"       { FLT }
  | "ld"        { LD }
  | "st"        { ST }
  | "fld"       { FLD }
  | "fst"       { FST }
  | "beq"       { BEQ }
  | "bne"       { BNE }
  | "blt"       { BLT }
  | "bgt"       { BGT }
  | "fbeq"      { FBEQ }
  | "fbne"      { FBNE }
  | "fblt"      { FBLT }
  | "fbgt"      { FBGT }
  | "jmp"       { JMP }
  | eof         { raise End_of_file }
  | "/*"        { comment lexbuf ; token lexbuf }
  | _           { failwith "Unrecognized Character" }
and comment = parse
  | "*/"        { () }
  | "/*"        { comment lexbuf ; comment lexbuf }
  | eof         { raise End_of_file }
  | _           { comment lexbuf }
