%{
#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <stdlib.h>
#include <stdbool.h>
#include "hw3.h"

int yylex();
void yyerror (const char *s);

NODE * makeExpr3(int row, int column, int line);
NODE * makeExpr1(int line);
void dimensionerror(int line);
void sizeerror(int line);

extern int line;  
%}


%union {
 NODE * node;
}


%token tINTTYPE tINTVECTORTYPE tINTMATRIXTYPE tREALTYPE tREALVECTORTYPE tREALMATRIXTYPE tTRANSPOSE tIDENT tDOTPROD tINTNUM tREALNUM tIF tENDIF tAND tOR tGT tLT tGTE tLTE tNE tEQ 

%type <node> vectorLit;
%type <node> matrixLit;
%type <node> value;
%type <node> row;
%type <node> rows;
%type <node> transpose;
%type <node> expr;


%left '='
%left tOR
%left tAND
%left tEQ tNE
%left tLTE tGTE tLT tGT
%left '+' '-'
%left '*' '/'
%left tDOTPROD
%left '(' ')'
%left tTRANSPOSE

%start prog

%%


prog:  stmtlst
;
stmtlst: stmtlst stmt 
       | stmt
;
stmt: decl
    | asgn
    | if   
;
decl: type vars '=' expr ';'
;
asgn: tIDENT '=' expr ';'
;
if: tIF '(' bool ')' stmtlst tENDIF
;
type: tINTTYPE
    | tINTVECTORTYPE
    | tINTMATRIXTYPE
    | tREALTYPE
    | tREALVECTORTYPE    
    | tREALMATRIXTYPE
;
vars: vars ',' tIDENT
    | tIDENT
;
expr: value                              
    | vectorLit                    
    | matrixLit                       
    | expr '*' expr                { if(!($1->column == $3->row))                              { dimensionerror(line); } }  
    | expr '/' expr                { if(!($1->column == $3->row && $3->row == $3->column))     { dimensionerror(line); } } 
    | expr '+' expr                { if(!($1->row == $3->row && $1->column == $3->column))     { dimensionerror(line); } }                      
    | expr '-' expr 	           { if(!($1->row == $3->row && $1->column == $3->column))       { dimensionerror(line); } } 
    | expr tDOTPROD expr           { if(!($1->row==1 && $3->row==1 && $1->column == $3->column)) { dimensionerror(line); } } 
    | transpose                         
;    
transpose: tTRANSPOSE '(' expr ')' { $$ = makeExpr3($3->column, $3->row, line);  }
;
vectorLit: '[' row ']'             { $$ = makeExpr3(1,$2->column,line);          }
;
row: row ',' value                 { $$ = makeExpr3($1->row,$1->column+1,line);  } 
   | value                            
;
matrixLit: '[' rows ']'            { $$ = makeExpr3($2->row, $2->column, line);  }      
;
rows: row ';' row                  { if($1->column != $3->column)                  { sizeerror(line); } }    
    | rows ';' row                 { $$ = makeExpr3($1->row+1,$1->column, line);  
                                     if($1->column != $3->column)                  { sizeerror(line); } }        
; 
value: tINTNUM                     { $$ = makeExpr1(line); }        
     | tREALNUM                    { $$ = makeExpr1(line); }       
;
bool: comp
    | bool tAND bool
    | bool tOR bool
;
comp: tIDENT relation tIDENT
;
relation: tGT
	| tLT
	| tGTE
        | tLTE
	| tEQ
	| tNE
;
%%

void yyerror (const char *s) 
{
	printf ("%s\n", s); 
}

void dimensionerror(int line)
{
        printf("ERROR 2: %d dimension mismatch\n",line);
        exit(0);
}

void sizeerror(int line)
{
        printf("ERROR 1: %d inconsistent matrix size\n",line);
        exit(0);
}


NODE * makeExpr1(int line)
{
  NODE * ret = (NODE *)malloc (sizeof(NODE)); 
  ret->row = 1;
  ret->column = 1;
  ret->line = line;
  return (ret);
}

NODE * makeExpr3(int row, int column, int line)
{
  NODE * ret = (NODE *)malloc (sizeof(NODE)); 
  ret->row = row;
  ret->column = column;
  ret->line = line;
  return (ret);
}

int main ()
{

   if (yyparse()) {
   // parse error
       printf("ERROR\n");
       return 1;
   }
   else {
   // successful parsing
      printf("OK\n");
      return 0;
   }
}
