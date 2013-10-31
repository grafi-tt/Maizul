{
  open Parser
}

let natural = ['1' - '9']
let digit = ['0' - '9']
let minimoji = ['a' - 'z']
let capital = ['A' - 'Z']
let moji = ['a' - 'z' 'A' - 'Z' '0' - '9']

rule token = parse
  | [' ' '\t' '\n']* { token lexbuf }
  | ","         { COMM }
  | ":"         { COL }
  | ";;"        { EOL }
  | digit* as x { NUM (int_of_string x) }
  | "add"       { ADD }
  | "addi"      { ADDI }
  | "sub"       { SUB }
  | "subi"      { SUBI }
  | "eq"        { EQ }
  | "eqi"       { EQI }
  | "lt"        { LT }
  | "lti"       { LTI }
  | "and"       { AND }
  | "andi"      { ANDI }
  | "or"        { OR }
  | "ori"       { ORI }
  | "xor"       { XOR }
  | "xori"      { XORI }
  | "sll"       { SLL }
  | "slli"      { SLLI }
  | "srl"       { SRL }
  | "srli"      { SRLI }
  | "sra"       { SRA }
  | "srai"      { SRAI }
  | "cat"       { CAT }
  | "cati"      { CATI }
  | "mul"       { MUL }
  | "muli"      { MULI }
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
  | "bgte"      { BGTE }
  | "jmp"       { JMP }
  | capital moji * as l  { LABEL l }
  | eof         { raise End_of_file }
  | "/*"        { comment lexbuf ; token lexbuf }
  | _           { failwith "Unrecognized Character" }
and comment = parse
  | "*/"        { () }
  | "/*"        { comment lexbuf ; comment lexbuf }
  | eof         { raise End_of_file }
  | _           { comment lexbuf }
