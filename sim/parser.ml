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

open Parsing;;
# 2 "parser.mly"
  open Type
# 36 "parser.ml"
let yytransl_const = [|
  257 (* EOL *);
  258 (* COMM *);
  259 (* COL *);
  260 (* J *);
  261 (* JL *);
  262 (* NOP *);
  263 (* BEQ *);
  264 (* BNE *);
  265 (* BLT *);
  266 (* EQ *);
  267 (* EQI *);
  268 (* LESS *);
  269 (* LESSI *);
  270 (* ADDQU *);
  271 (* ADDQUI *);
  272 (* SUBQU *);
  273 (* SUBQUI *);
  274 (* AND *);
  275 (* ANDI *);
  276 (* OR *);
  277 (* ORI *);
  278 (* XOR *);
  279 (* XORI *);
  280 (* LD *);
  281 (* ST *);
  282 (* NOT *);
    0|]

let yytransl_block = [|
  283 (* IMMI *);
  284 (* LABEL *);
  285 (* NUM *);
    0|]

let yylhs = "\255\255\
\001\000\002\000\002\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\000\000"

let yylen = "\002\000\
\002\000\002\000\001\000\004\000\004\000\004\000\004\000\004\000\
\004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
\004\000\004\000\004\000\004\000\004\000\004\000\004\000\001\000\
\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\024\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\025\000\000\000\003\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\002\000\
\001\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\023\000\020\000\021\000\
\022\000\008\000\009\000\010\000\011\000\004\000\005\000\006\000\
\007\000\012\000\013\000\016\000\017\000\014\000\015\000\018\000\
\019\000"

let yydgoto = "\002\000\
\025\000\026\000\027\000"

let yysindex = "\021\000\
\252\254\000\000\228\254\000\000\250\254\253\254\254\254\255\254\
\000\255\001\255\002\255\003\255\004\255\005\255\006\255\007\255\
\008\255\009\255\010\255\011\255\012\255\013\255\014\255\022\255\
\000\000\043\255\000\000\016\255\017\255\018\255\019\255\020\255\
\021\255\023\255\024\255\025\255\026\255\027\255\028\255\029\255\
\030\255\031\255\032\255\033\255\034\255\035\255\036\255\000\000\
\000\000\038\255\039\255\040\255\041\255\042\255\045\255\044\255\
\047\255\046\255\049\255\048\255\051\255\050\255\053\255\052\255\
\055\255\054\255\056\255\058\255\059\255\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000"

let yygindex = "\000\000\
\000\000\000\000\000\000"

let yytablesize = 87
let yytable = "\003\000\
\028\000\004\000\005\000\006\000\007\000\008\000\009\000\010\000\
\011\000\012\000\013\000\014\000\015\000\016\000\017\000\018\000\
\019\000\020\000\021\000\022\000\023\000\001\000\029\000\024\000\
\048\000\030\000\031\000\032\000\033\000\034\000\035\000\036\000\
\037\000\038\000\039\000\040\000\041\000\042\000\043\000\044\000\
\045\000\046\000\047\000\049\000\050\000\051\000\052\000\053\000\
\054\000\055\000\000\000\056\000\057\000\058\000\059\000\060\000\
\061\000\062\000\063\000\064\000\065\000\066\000\067\000\068\000\
\069\000\070\000\071\000\072\000\073\000\000\000\074\000\075\000\
\076\000\077\000\078\000\079\000\080\000\081\000\082\000\083\000\
\084\000\085\000\086\000\000\000\087\000\088\000\089\000"

let yycheck = "\004\001\
\029\001\006\001\007\001\008\001\009\001\010\001\011\001\012\001\
\013\001\014\001\015\001\016\001\017\001\018\001\019\001\020\001\
\021\001\022\001\023\001\024\001\025\001\001\000\029\001\028\001\
\003\001\029\001\029\001\029\001\029\001\029\001\029\001\029\001\
\029\001\029\001\029\001\029\001\029\001\029\001\029\001\029\001\
\029\001\029\001\029\001\001\001\029\001\029\001\029\001\029\001\
\029\001\029\001\255\255\029\001\029\001\029\001\029\001\029\001\
\029\001\029\001\029\001\029\001\029\001\029\001\029\001\029\001\
\029\001\028\001\028\001\028\001\028\001\255\255\029\001\027\001\
\029\001\027\001\029\001\027\001\029\001\027\001\029\001\027\001\
\029\001\027\001\029\001\255\255\029\001\028\001\028\001"

let yynames_const = "\
  EOL\000\
  COMM\000\
  COL\000\
  J\000\
  JL\000\
  NOP\000\
  BEQ\000\
  BNE\000\
  BLT\000\
  EQ\000\
  EQI\000\
  LESS\000\
  LESSI\000\
  ADDQU\000\
  ADDQUI\000\
  SUBQU\000\
  SUBQUI\000\
  AND\000\
  ANDI\000\
  OR\000\
  ORI\000\
  XOR\000\
  XORI\000\
  LD\000\
  ST\000\
  NOT\000\
  "

let yynames_block = "\
  IMMI\000\
  LABEL\000\
  NUM\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'top) in
    Obj.repr(
# 27 "parser.mly"
        ( _1 )
# 201 "parser.ml"
               : Type.top))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : string) in
    Obj.repr(
# 31 "parser.mly"
                  ( Toplabel _1 )
# 208 "parser.ml"
               : 'top))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 32 "parser.mly"
                  ( Top _1 )
# 215 "parser.ml"
               : 'top))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 35 "parser.mly"
                      ( EAdd (_2,_3,_4) )
# 224 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 36 "parser.mly"
                         ( EAddi (_2,_3,_4) )
# 233 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 37 "parser.mly"
                       ( ESub (_2, _3, _4) )
# 242 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 38 "parser.mly"
                        ( ESubi (_2, _3, _4) )
# 251 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 39 "parser.mly"
                   ( Eq (_2, _3, _4) )
# 260 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 40 "parser.mly"
                      ( Eqi (_2,_3, _4) )
# 269 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 41 "parser.mly"
                     ( ELess (_2,_3,_4) )
# 278 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 42 "parser.mly"
                        ( ELessi (_2,_3,_4) )
# 287 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 43 "parser.mly"
                    ( EAnd (_2, _3,_4) )
# 296 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 44 "parser.mly"
                      ( EAndi (_2, _3,_4) )
# 305 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 45 "parser.mly"
                    ( EXor (_2, _3, _4) )
# 314 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 46 "parser.mly"
                     ( EXori (_2, _3, _4) )
# 323 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 47 "parser.mly"
                   ( EOr (_2, _3, _4) )
# 332 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 48 "parser.mly"
                     ( EOri (_2, _3, _4) )
# 341 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 49 "parser.mly"
                     ( ELd (_2,_3,_4) )
# 350 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 50 "parser.mly"
                     ( ESt (_2,_3,_4) )
# 359 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 51 "parser.mly"
                      ( EBeq (_2, _3, _4) )
# 368 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 52 "parser.mly"
                      ( EBne (_2, _3, _4) )
# 377 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 53 "parser.mly"
                      ( EBlt (_2, _3, _4) )
# 386 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 54 "parser.mly"
                   ( EJump (_2, _3, _4) )
# 395 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 55 "parser.mly"
          ( Nop )
# 401 "parser.ml"
               : 'expr))
(* Entry main *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let main (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Type.top)
