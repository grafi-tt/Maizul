{
  open Parser
}

let natural = ['1' - '9'] ['0' - '9']* | '0'
let digit = '-'? natural
let tag = ['1' '2']? ['0' - '9'] | '3' ['0' '1']
let moji = ['a' - 'z' 'A' - 'Z' '0' - '9' '_' '.' '-']

rule token = parse
  | [' ' '\t' '\n']+ { token lexbuf }
  | ";"        { DELIM }
  | (moji+ as l) ':' { LABEL l }
  | 'r' (tag as x) { OPR (`Reg (int_of_string x)) }
  | 'f' (tag as x) { OPR (`FReg (int_of_string x)) }
  | (moji+ as l) "@t" { OPR (`TextLabel l) }
  | (moji+ as l) "@d" { OPR (`DataLabel l) }
  | digit as d { OPR (`Imm (int_of_string d)) }
  | 'w' (natural as n) { WORD_VAL (int_of_string n) }
  | ".text" { TEXT_SECTION }
  | ".data" { DATA_SECTION }
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
  | "fadd"      { FADD }
  | "faddn"     { FADDN }
  | "faddp"     { FADDP }
  | "faddm"     { FADDM }
  | "fsub"      { FSUB }
  | "fsubn"     { FSUBN }
  | "fsubp"     { FSUBP }
  | "fsubm"     { FSUBM }
  | "fmul"      { FMUL }
  | "fmuln"     { FMULN }
  | "fmulp"     { FMULP }
  | "fmulm"     { FMULM }
  | "finv"      { FINV }
  | "finvn"     { FINVN }
  | "finvp"     { FINVP }
  | "finvm"     { FINVM }
  | "fsqr"      { FSQR }
  | "fsqrn"     { FSQRN }
  | "fsqrp"     { FSQRP }
  | "fsqrm"     { FSQRM }
  | "fmov"      { FMOV }
  | "fmovn"     { FMOVN }
  | "fmovp"     { FMOVP }
  | "fmovm"     { FMOVM }
  | "fflr"      { FFLR }
  | "fflrn"     { FFLRN }
  | "fflrp"     { FFLRP }
  | "fflrm"     { FFLRM }
  | "rtof"      { RTOF }
  | "rtofn"     { RTOFN }
  | "rtofp"     { RTOFP }
  | "rtofm"     { RTOFM }
  | "ftorx"     { FTORX }
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
  | "jmpc"      { JMPC }
  | "jmpr"      { JMPR }
  | "get"       { GET }
  | "put"       { PUT }
  | "getb"      { GETB }
  | "putb"      { PUTB }
  | "word"      { WORD }
  | eof         { raise End_of_file }
  | "/*"        { comment lexbuf ; token lexbuf }
  | _           { failwith "Unrecognized Character" }
and comment = parse
  | "*/"        { () }
  | "/*"        { comment lexbuf ; comment lexbuf }
  | eof         { raise End_of_file }
  | _           { comment lexbuf }
