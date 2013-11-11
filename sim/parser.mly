%{
  open Type
%}

%token DELIM
%token TEXT_SECTION DATA_SECTION
%token ADD ADDI SUB SUBI
%token EQ EQI LT LTI
%token AND ANDI OR ORI XOR XORI
%token SLL SLLI SRL SRLI SRA SRAI
%token CAT CATI MUL MULI
%token FMOVR FTOR FEQ FLT
%token FADD FADDN FADDP FADDM FSUB FSUBN FSUBP FSUBM FMUL FMULN FMULP FMULM
%token FINV FINVN FINVP FINVM FSQR FSQRN FSQRP FSQRM FMOV FMOVN FMOVP FMOVM
%token RMOVF RMOVFN RMOVFP RMOVFM RTOF RTOFN RTOFP RTOFM
%token LD ST FLD FST
%token BEQ BNE BLT BGT FBEQ FBNE FBLT FBGT
%token JMP
%token GET PUT GETB PUTB
%token WORD
%token <int> WORD_VAL
%token <Type.opr> OPR
%token <Type._label> LABEL

%start main
%type <Type.top> main

%%

main:
  | LABEL { Toplabel $1 }
  | expr DELIM { Top $1 }
  | mem_expr DELIM { TopMem $1 }
  | TEXT_SECTION { TopText }
  | DATA_SECTION { TopData }

expr:
  | ADD   OPR OPR OPR { Add (reg $2, reg $3, reg_imm $4) }
  | SUB   OPR OPR OPR { Sub (reg $2, reg $3, reg_imm $4) }
  | EQ    OPR OPR OPR { Eq  (reg $2, reg $3, reg_imm $4) }
  | LT    OPR OPR OPR { Lt  (reg $2, reg $3, reg_imm $4) }
  | AND   OPR OPR OPR { And (reg $2, reg $3, reg_imm $4) }
  | OR    OPR OPR OPR { Or  (reg $2, reg $3, reg_imm $4) }
  | XOR   OPR OPR OPR { Xor (reg $2, reg $3, reg_imm $4) }
  | SLL   OPR OPR OPR { Sll (reg $2, reg $3, reg_imm $4) }
  | SRL   OPR OPR OPR { Srl (reg $2, reg $3, reg_imm $4) }
  | SRA   OPR OPR OPR { Sra (reg $2, reg $3, reg_imm $4) }
  | CAT   OPR OPR OPR { Cat (reg $2, reg $3, reg_imm $4) }
  | MUL   OPR OPR OPR { Mul (reg $2, reg $3, reg_imm $4) }
  | FMOVR OPR OPR     { Fmovr (reg $2, freg $3) }
  | FTOR  OPR OPR     { Ftor  (reg $2, freg $3) }
  | FEQ   OPR OPR OPR { Feq   (reg $2, freg $3, freg $4) }
  | FLT   OPR OPR OPR { Flt   (reg $2, freg $3, freg $4) }
  | FADD  OPR OPR OPR { Fadd (freg $2, freg $3, freg $4, Straight) }
  | FADDN OPR OPR OPR { Fadd (freg $2, freg $3, freg $4, Negate) }
  | FADDP OPR OPR OPR { Fadd (freg $2, freg $3, freg $4, Plus) }
  | FADDM OPR OPR OPR { Fadd (freg $2, freg $3, freg $4, Minus) }
  | FSUB  OPR OPR OPR { Fsub (freg $2, freg $3, freg $4, Straight) }
  | FSUBN OPR OPR OPR { Fsub (freg $2, freg $3, freg $4, Negate) }
  | FSUBP OPR OPR OPR { Fsub (freg $2, freg $3, freg $4, Plus) }
  | FSUBM OPR OPR OPR { Fsub (freg $2, freg $3, freg $4, Minus) }
  | FMUL  OPR OPR OPR { Fmul (freg $2, freg $3, freg $4, Straight) }
  | FMULN OPR OPR OPR { Fmul (freg $2, freg $3, freg $4, Negate) }
  | FMULP OPR OPR OPR { Fmul (freg $2, freg $3, freg $4, Plus) }
  | FMULM OPR OPR OPR { Fmul (freg $2, freg $3, freg $4, Minus) }
  | FINV  OPR OPR     { Finv (freg $2, freg $3, Straight) }
  | FINVN OPR OPR     { Finv (freg $2, freg $3, Negate) }
  | FINVP OPR OPR     { Finv (freg $2, freg $3, Plus) }
  | FINVM OPR OPR     { Finv (freg $2, freg $3, Minus) }
  | FSQR  OPR OPR     { Fsqr (freg $2, freg $3, Straight) }
  | FSQRN OPR OPR     { Fsqr (freg $2, freg $3, Negate) }
  | FSQRP OPR OPR     { Fsqr (freg $2, freg $3, Plus) }
  | FSQRM OPR OPR     { Fsqr (freg $2, freg $3, Minus) }
  | FMOV  OPR OPR     { Fmov (freg $2, freg $3, Straight) }
  | FMOVN OPR OPR     { Fmov (freg $2, freg $3, Negate) }
  | FMOVP OPR OPR     { Fmov (freg $2, freg $3, Plus) }
  | FMOVM OPR OPR     { Fmov (freg $2, freg $3, Minus) }
  | RMOVF  OPR OPR    { Rmovf (freg $2, reg $3, Straight) }
  | RMOVFN OPR OPR    { Rmovf (freg $2, reg $3, Negate) }
  | RMOVFP OPR OPR    { Rmovf (freg $2, reg $3, Plus) }
  | RMOVFM OPR OPR    { Rmovf (freg $2, reg $3, Minus) }
  | RTOF   OPR OPR    { Rtof  (freg $2, reg $3, Straight) }
  | RTOFN  OPR OPR    { Rtof  (freg $2, reg $3, Negate) }
  | RTOFP  OPR OPR    { Rtof  (freg $2, reg $3, Plus) }
  | RTOFM  OPR OPR    { Rtof  (freg $2, reg $3, Minus) }
  | LD    OPR OPR OPR { Ld  (reg $2, reg $3, data_imm $4) }
  | ST    OPR OPR OPR { St  (reg $2, reg $3, data_imm $4) }
  | FLD   OPR OPR OPR { Fld (freg $2, reg $3, data_imm $4) }
  | FST   OPR OPR OPR { Fst (freg $2, reg $3, data_imm $4) }
  | BEQ   OPR OPR OPR { Beq  (reg $2, reg $3, text_imm $4) }
  | BNE   OPR OPR OPR { Bne  (reg $2, reg $3, text_imm $4) }
  | BLT   OPR OPR OPR { Blt  (reg $2, reg $3, text_imm $4) }
  | BGT   OPR OPR OPR { Bgt  (reg $2, reg $3, text_imm $4) }
  | FBEQ  OPR OPR OPR { Fbeq (freg $2, freg $3, text_imm $4) }
  | FBNE  OPR OPR OPR { Fbne (freg $2, freg $3, text_imm $4) }
  | FBLT  OPR OPR OPR { Fblt (freg $2, freg $3, text_imm $4) }
  | FBGT  OPR OPR OPR { Fbgt (freg $2, freg $3, text_imm $4) }
  | JMP   OPR OPR OPR { Jmp  (reg $2, reg $3, text_imm $4) }
  | PUT   OPR         { Put  (reg $2) }
  | GET   OPR         { Get  (reg $2) }
  | PUTB  OPR         { Putb (reg $2) }
  | GETB  OPR         { Getb (reg $2) }

mem_expr:
  | WORD WORD_VAL { Word $2 }
