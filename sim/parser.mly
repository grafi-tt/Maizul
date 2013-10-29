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
%token AND ANDI OR ORI XOR XORI 
%token LD ST
%token NOT 
%token <int> IMMI
%token NOP
%token <string> LABEL
%token <int> NUM 

%start main 
%type <Type.top> main 

%% 

main: 
top EOL { $1 }
; 

top:
  | LABEL COL     { Toplabel $1 } 
  | expr          { Top $1 } 

expr:
  | ADDQU NUM NUM NUM { EAdd ($2,$3,$4) }
  | ADDQUI NUM NUM IMMI  { EAddi ($2,$3,$4) } 
  | SUBQU NUM NUM NUM  { ESub ($2, $3, $4) } 
  | SUBQUI NUM NUM IMMI { ESubi ($2, $3, $4) } 
  | EQ NUM NUM NUM { Eq ($2, $3, $4) } 
  | EQI NUM NUM IMMI  { Eqi ($2,$3, $4) } 
  | LESS NUM NUM NUM { ELess ($2,$3,$4) } 
  | LESSI NUM NUM IMMI  { ELessi ($2,$3,$4) }
  | AND NUM NUM NUM { EAnd ($2, $3,$4) }
  | ANDI NUM NUM IMMI { EAndi ($2, $3,$4) }
  | XOR NUM NUM NUM { EXor ($2, $3, $4) }
  | XORI NUM NUM NUM { EXori ($2, $3, $4) }  
  | OR NUM NUM NUM { EOr ($2, $3, $4) } 
  | ORI NUM NUM IMMI { EOri ($2, $3, $4) } 
  | LD NUM NUM IMMI { ELd ($2,$3,$4) } 
  | ST NUM NUM IMMI { ESt ($2,$3,$4) } 
  | BEQ NUM NUM LABEL { EBeq ($2, $3, $4) } 
  | BNE NUM NUM LABEL { EBne ($2, $3, $4) }
  | BLT NUM NUM LABEL { EBlt ($2, $3, $4) } 
  | J NUM NUM LABEL{ EJump ($2, $3, $4) } 
  | NOP   { Nop } 
;

