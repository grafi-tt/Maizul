type token =
  | EOL
  | COMM
  | COL
  | J
  | JL
  | NOP
  | BEQ
  | BNE
  | BLT
  | EQ
  | EQI
  | LESS
  | LESSI
  | ADDQU
  | ADDQUI
  | SUBQU
  | SUBQUI
  | AND
  | ANDI
  | OR
  | ORI
  | XOR
  | XORI
  | LD
  | ST
  | NOT
  | IMMI of (int)
  | LABEL of (string)
  | NUM of (int)

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Type.top
