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
  | natural digit* as x { NUM (int_of_string x) } 
  | "addqu"     { ADDQU }
  | "addqui"    { ADDQUI } 
  | "subqu"     { SUBQU }
  | "subqui"    { SUBQUI }
  | "eq"        { EQ } 
  | "eqi"       { EQI } 
  | "lt"        { LESS } 
  | "lti"       { LESSI }
  | "xor"       { XOR } 
  | "xori"      { XORI } 
  | "and"       { AND } 
  | "andi"      { ANDI } 
  | "not"       { NOT } 
  | "or"        { OR } 
  | "ori"       { ORI } 
  | "ld"        { LD } 
  | "st"        { ST } 
  | "beq"       { BEQ } 
  | "bne"       { BNE } 
  | "blt"       { BLT } 
  | "j"         { J } 
  | "jl"        { JL } 
  | "nop"       { NOP } 
  | capital moji * as l  { LABEL l }  
  | eof         { raise End_of_file } 
  | "/*"        { comment lexbuf ; token lexbuf } 
  | _           { failwith "Unrecognized Character" } 
and comment = parse 
  | "*/"        { () }
  | "/*"        { comment lexbuf ; comment lexbuf }  
  | eof         { raise End_of_file } 
  | _           { comment lexbuf } 
