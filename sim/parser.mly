%{
  open Type
%}

%token EOL
%token SETL
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
%token <int> NUM
%token <string> LABEL

%start main
%type <Type.top> main

%%

main: top EOL { $1 }

top:
  | LABEL { Toplabel $1 }
  | expr  { Top $1 }

expr:
  | SETL  NUM LABEL { Setl ($2, $3) }
  | ADD   NUM NUM NUM { Add ($2, $3, Reg $4) }
  | ADDI  NUM NUM NUM { Add ($2, $3, Imm $4) }
  | SUB   NUM NUM NUM { Sub ($2, $3, Reg $4) }
  | SUBI  NUM NUM NUM { Sub ($2, $3, Imm $4) }
  | EQ    NUM NUM NUM { Eq  ($2, $3, Reg $4) }
  | EQI   NUM NUM NUM { Eq  ($2, $3, Imm $4) }
  | LT    NUM NUM NUM { Lt  ($2, $3, Reg $4) }
  | LTI   NUM NUM NUM { Lt  ($2, $3, Imm $4) }
  | AND   NUM NUM NUM { And ($2, $3, Reg $4) }
  | ANDI  NUM NUM NUM { And ($2, $3, Imm $4) }
  | OR    NUM NUM NUM { Or  ($2, $3, Reg $4) }
  | ORI   NUM NUM NUM { Or  ($2, $3, Imm $4) }
  | XOR   NUM NUM NUM { Xor ($2, $3, Reg $4) }
  | XORI  NUM NUM NUM { Xor ($2, $3, Imm $4) }
  | SLL   NUM NUM NUM { Sll ($2, $3, Reg $4) }
  | SLLI  NUM NUM NUM { Sll ($2, $3, Imm $4) }
  | SRL   NUM NUM NUM { Srl ($2, $3, Reg $4) }
  | SRLI  NUM NUM NUM { Srl ($2, $3, Imm $4) }
  | SRA   NUM NUM NUM { Sra ($2, $3, Reg $4) }
  | SRAI  NUM NUM NUM { Sra ($2, $3, Imm $4) }
  | CAT   NUM NUM NUM { Cat ($2, $3, Reg $4) }
  | CATI  NUM NUM NUM { Cat ($2, $3, Imm $4) }
  | MUL   NUM NUM NUM { Mul ($2, $3, Reg $4) }
  | MULI  NUM NUM NUM { Mul ($2, $3, Imm $4) }
  | FMOVR NUM NUM     { Fmovr ($2, $3) }
  | FTOR  NUM NUM     { Ftor  ($2, $3) }
  | FEQ   NUM NUM NUM { Feq   ($2, $3, $4) }
  | FLT   NUM NUM NUM { Flt   ($2, $3, $4) }
  | FADD  NUM NUM NUM { Fadd ($2, $3, $4, Straight) }
  | FADDN NUM NUM NUM { Fadd ($2, $3, $4, Negate) }
  | FADDP NUM NUM NUM { Fadd ($2, $3, $4, Plus) }
  | FADDM NUM NUM NUM { Fadd ($2, $3, $4, Minus) }
  | FSUB  NUM NUM NUM { Fsub ($2, $3, $4, Straight) }
  | FSUBN NUM NUM NUM { Fsub ($2, $3, $4, Negate) }
  | FSUBP NUM NUM NUM { Fsub ($2, $3, $4, Plus) }
  | FSUBM NUM NUM NUM { Fsub ($2, $3, $4, Minus) }
  | FMUL  NUM NUM NUM { Fmul ($2, $3, $4, Straight) }
  | FMULN NUM NUM NUM { Fmul ($2, $3, $4, Negate) }
  | FMULP NUM NUM NUM { Fmul ($2, $3, $4, Plus) }
  | FMULM NUM NUM NUM { Fmul ($2, $3, $4, Minus) }
  | FINV  NUM NUM     { Finv ($2, $3, Straight) }
  | FINVN NUM NUM     { Finv ($2, $3, Negate) }
  | FINVP NUM NUM     { Finv ($2, $3, Plus) }
  | FINVM NUM NUM     { Finv ($2, $3, Minus) }
  | FSQR  NUM NUM     { Fsqr ($2, $3, Straight) }
  | FSQRN NUM NUM     { Fsqr ($2, $3, Negate) }
  | FSQRP NUM NUM     { Fsqr ($2, $3, Plus) }
  | FSQRM NUM NUM     { Fsqr ($2, $3, Minus) }
  | FMOV  NUM NUM     { Fmov ($2, $3, Straight) }
  | FMOVN NUM NUM     { Fmov ($2, $3, Negate) }
  | FMOVP NUM NUM     { Fmov ($2, $3, Plus) }
  | FMOVM NUM NUM     { Fmov ($2, $3, Minus) }
  | LD    NUM NUM NUM { Ld  ($2, $3, $4) }
  | ST    NUM NUM NUM { St  ($2, $3, $4) }
  | FLD   NUM NUM NUM { Fld ($2, $3, $4) }
  | FST   NUM NUM NUM { Fst ($2, $3, $4) }
  | BEQ   NUM NUM LABEL { Beq  ($2, $3, $4) }
  | BNE   NUM NUM LABEL { Bne  ($2, $3, $4) }
  | BLT   NUM NUM LABEL { Blt  ($2, $3, $4) }
  | BGT   NUM NUM LABEL { Bgt  ($2, $3, $4) }
  | FBEQ  NUM NUM LABEL { Fbeq ($2, $3, $4) }
  | FBNE  NUM NUM LABEL { Fbne ($2, $3, $4) }
  | FBLT  NUM NUM LABEL { Fblt ($2, $3, $4) }
  | FBGT  NUM NUM LABEL { Fbgt ($2, $3, $4) }
  | JMP   NUM NUM LABEL { Jmp  ($2, $3, $4) }
