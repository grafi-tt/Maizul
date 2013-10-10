%{
  open Type
%}

%token <int> INT 
%token <int> NUM 
%token <string> LABEL
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


%start main 
%type <Type.expr> main 

%% 

main: 
expr EOL { $1 }
; 

expr:
  | INT       { EConst (VInt $1) }
  | LABEL COL     { ELabel ($1) } 
  | ADDQU num num num { EAdd ($2, $3, $4) }
  | ADDQUI num num expr  { EAddi ($2, $3, $4) } 
  | SUBQU num num num  { ESub ($2, $3, $4) } 
  | SUBQUI num num expr { ESubi ($2, $3, $4) } 
  | EQ num num num { Eq ($2, $3, $4) } 
  | EQI num num expr  { Eqi ($2. $3, $4) } 
  | LESS num num num { ELess ($2, $3, $4) } 
  | LESSI num num expr  { ELessi ($2, $3, $4) }
  | NOR num num num { ENor ($2, $3, $4) } 
  | NORI num num expr { ENori ($2, $3, $4) } 
  | AND num num num { EAnd ($2, $3, $4) }
  | ANDI num num expr { EAndi ($2, $3, $4) }
  | NOT num num { ENot ($2, $3) } 
  | OR num num num { EOr ($2, $3, $4) } 
  | ORI num num expr { EOri ($2, $3, $4) } 
  | LD num num { ELd ($2, $3) } 
  | ST num num { ESt ($2, $3) } 
  | BEQ num num expr { EBeq ($2, $3, $4) } 
  | BNE num num expr { EBne ($2, $3, $4) }
  | BLT num num expr { EBlt ($2, $3, $4) } 
  | J num { EJump ($2) } 
  | JL  { EJumpl ($2) } 
  | NOP { EConst (Nop) } 
;


num:
  | NUM { ENum ($1) }  
