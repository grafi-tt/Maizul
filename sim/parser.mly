%{
  open Type
%}


%token EOL
%token COMM COL 
%token J JL 
%token NOP
%token BEQ BNE BLT
%token EQ EQI LESS LESSI   
%token ADDQU ADDQUI SUBQU SUBQUI 
%token AND ANDI OR ORI NOR NORI
%token LD ST
%token NOT 
%token <int> IMMI
%token NOP
%token <string> LABEL
%token <int> NUM 

%start main 
%type <Type.expr> main 

%% 

main: 
expr EOL { $1 }
; 

expr:
  | LABEL COL     { ELabel ($1) } 
  | ADDQU NUM NUM NUM { EAdd ($2,$3,$4) }
  | ADDQUI NUM NUM IMMI  { EAddi ($2,$3,$4) } 
  | SUBQU NUM NUM NUM  { ESub ($2, $3, $4) } 
  | SUBQUI NUM NUM IMMI { ESubi ($2, $3, $4) } 
  | EQ NUM NUM NUM { Eq ($2, $3, $4) } 
  | EQI NUM NUM IMMI  { Eqi ($2,$3, $4) } 
  | LESS NUM NUM NUM { ELess ($2,$3,$4) } 
  | LESSI NUM NUM IMMI  { ELessi ($2,$3,$4) }
  | NOR NUM NUM NUM { ENor ($2, $3, $4) } 
  | NORI NUM NUM IMMI { ENori ($2,$3, $4) } 
  | AND NUM NUM NUM { EAnd ($2, $3,$4) }
  | ANDI NUM NUM IMMI { EAndi ($2, $3,$4) }
  | NOT NUM NUM { ENot ($2, $3) } 
  | OR NUM NUM NUM { EOr ($2, $3, $4) } 
  | ORI NUM NUM IMMI { EOri ($2, $3, $4) } 
  | LD NUM NUM { ELd ($2,$3) } 
  | ST NUM NUM { ESt ($2,$3) } 
  | BEQ NUM NUM LABEL { EBeq ($2, $3, $4) } 
  | BNE NUM NUM LABEL { EBne ($2, $3, $4) }
  | BLT NUM NUM LABEL { EBlt ($2, $3, $4) } 
  | J NUM { EJump ($2) } 
  | JL LABEL { EJumpl ($2) } 
  | NOP   { Nop } 
;
