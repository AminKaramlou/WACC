%{

#include "astnode.h"
#include <cstdio>
#include <cstdlib>

extern int yylex();  /* Lexical analyser generated by flex */

void yyerror(const char *message) {  /* action on encountering an error */
  std::printf("Error: %s\n", message);
  std::exit(1); 
}
	
Program *ast;     /* Pointer to root of Abstract Syntax Tree */

%}

/* BISON DECLARATIONS  _--------------------------------------------------- */

/* Define all possible syntactic values */
/* %define api.value.type variant _ need if  proper C++ typing is used */

%union {
  int                     token;
  std::string         	  *string;
	int 									  intValue;
	char									  charValue;
  Program                 program;
  Identifier 		 		      id;
  Type                    type;
  Statement 		 		      statement;
  AssignLhs               assignlhs;
  AssignRhs               assignrhs;
  Expression     		      expression;
  ExpressionList 		     	exprlist;
  VariableList            varlist;
  VariableDeclaration     vardec;
  FunctionDeclaration     fundec;
  FunctionList            funlist;
}

%token <token>  BEGIN END IF THEN ELSE FI WHILE DO DONE SKIP FREE EXIT TRUE FALSE

%token <token>  IS RETURN CALL

%token <token> PAIR INT BOOL CHAR STRING NULL

%token <token>  ASSIGN LESSEQUALS LESS GREATEREQUALS GREATER EQUALS BANG  
%token <token>  NOTEQUALS PLUS MINUS STAR SLASH MODULO LOGAND LOGOR

%token <token>  LPAREN RPAREN LSQUARE RSQUARE SEMICOLON COMMA ERROR

%token <token> PRINT PRINTLN READ NEWPAIR FST SND LEN ORD CHR

%token <string> IDENTIFIER STRINGLIT

%token<charValue> CHARLIT

%token<intValue> INTEGER

%type <program>         program
%type <type>            type base_type array_type pair_type pair_elem_type
%type <statement>  		  statement statement_seq	
%type <assignlhs>       assign_lhs array_elem_lhs pair_elem_lhs
%type <assignrhs>       assign_rhs expr array_liter pair_elem_rhs
%type <expression> 			int_liter bool_liter char_liter str_liter
%type <expression>      pair_liter array_elem_exp
%type <exprlist>   			arg_list expr_list array_index
%type <varlist>    			param_list
%type <vardec>          param
%type <token>	     			unary_oper binary_oper int_sign
%type <fundec>     			function_declaration
%type <funlist>         func_list

/* Precedence of operators */
%left PLUS MINUS STAR SLASH MODULO LOGOR LOGAND LESS GREATER LESSEQUALS 
%left GREATEREQUALS NOTEQUALS EQUALS BANG LEN CHR ORD UMINUS UPLUS

/* Start symbol. If omitted will default to first non_terminal symbol */
%start program 
%%
program: 
    BEGIN func_list statement_seq END
		{ ast = new Program($2, $3) }
  ;
func_list:
	/* empty */ 
		{ $$ = new FunctionList(); }
	| func_list function_declaration
    { $1.push_back(&$2); }
  ;
function_declaration:
		type ident LPAREN RPAREN IS statement END
		{ $$ = new FunctionDeclaration($1, $<id>2, $6); }
	| type ident LPAREN param_list RPAREN IS statement END
		{ $$ = new FunctionDeclaration($1, $<id>2, $4, $7); }
    ;
param_list:
    param
		{ $$ = new VariableList();
			$$.push_back_(&$1); }
  | param_list COMMA param
		{ $1.push_back(&$3); }
    ;
param:
		type ident
		{ $$ = new VariableDeclaration($1, $<id>2); }
    ;
statement_seq:
		statement
		{ $$ = new StatSeq();
			$$->statements.push_back($1); }
	| statement_seq SEMICOLON statement
		{ $1->statements.push_back($3); }
    ;
statement:
    SKIP
		{ $$ = new SkipStatement(); }
  | RETURN expr
    { $$ = new ReturnStatement($2); }
  | type ident ASSIGN assign_rhs
		{ $$ = new VariableDeclaration($1, $<id>2, &$4); }
  | assign_lhs ASSIGN assign_rhs
		{ $$ = new Assignment($1, $3); }
  | READ assign_lhs
		{ $$ = new Read($2); }
  | FREE expr
		{ $$ = new FreeStatement($2); }
  | EXIT expr
		{ $$ = new ExitStatement($2); }
  | PRINT expr
		{ $$ = new PrintStatement($2); }
  | PRINTLN expr
		{ $$ = new PrintlnStatement($2); }
	| BEGIN statement_seq END
		{ $$ = new BeginStatement($2); }
  | IF expr THEN statement ELSE statement FI
		{ $$ = new IfStatement($2, $4, &$6);  }
  | WHILE expr DO statement DONE
		{ $$ = new WhileStatement($2, $4); }
/*  | statement_seq
		{ $$ = $1; }
*/	    ;	
assign_lhs:
		ident
		{ $$ = $<assignlhs>1; } 
  | array_elem_lhs
		{ $$ = $1; } 
	| pair_elem_lhs
		{ $$ = $1; } 
    ;
assign_rhs:
    expr
		{ $<assingrhs>$ = $1; } 
  | array_liter
		{ $$ = $1; } 
  | NEWPAIR LPAREN expr COMMA expr RPAREN
		{ $$ = new NewPair($3, $5); } 
  | pair_elem_rhs
		{ $$ = $1; } 
	| CALL ident LPAREN RPAREN
		{ $$ = new FunctionCall($<id>2); }
  | CALL ident LPAREN arg_list RPAREN
		{ $$ = new FunctionCall($<id>2, $4); }
    ;
arg_list:
    expr
		{ $$ = new ExpressionList();
			$$.push_back($1); } 
  | arg_list COMMA expr 
		{ $1.push_back($3); }
    ;
pair_elem_rhs:
    FST expr
		{ $$ = new PairElem(true, $2); }
  | SND expr
		{ $$ = new PairElem(false, $2); }
    ;
pair_elem_lhs:
    FST expr
		{ $$ = new PairElem(true, $2); }
  | SND expr
		{ $$ = new PairElem(false, $2); }
    ;
type:
    base_type
		{ $$ = $1; }
  | array_type
		{ $$ = $1; }
  | pair_type
		{ $$ = $1; }
    ;
base_type:
    INT
		{ $$ = new IntegerType($1); }
  | BOOL
		{ $$ = new BoolType($1); }
  | CHAR
		{ $$ = new CharType($1); }
  | STRING
		{ $$ = new StringType($1); }
    ;
array_type:
  type LSQUARE RSQUARE
	{ $$ = new ArrayType($1); }
    ;
pair_type:
  PAIR LPAREN pair_elem_type COMMA pair_elem_type RPAREN
	{ $$ = new PairType($3, $5); }
    ;
pair_elem_type:
    base_type
		{ $$ = $1; }
  | array_type
		{ $$ = $1; }
  | PAIR
	  { $$ = new PairKeyword(); }
    ;
/* shift/reduce conflict at the ident and array_elem_exp, but handled by default
shifting */
expr:
    int_liter
		{ $$ = $1; }
  | bool_liter
		{ $$ = $1; }
  | char_liter 
		{ $$ = $1; }
  | str_liter
		{ $$ = $1; }
  | pair_liter
		{ $$ = $1; }
  | ident
		{ $$ = $<expression>1; }
  | array_elem_exp
		{ $$ = $1; }
  | unary_oper expr
		{ $$ = new UnaryOperator($1, $2); }
  | expr binary_oper expr
		{ $$ = new BinaryOperator($1, $2, $3); }
  | LPAREN expr RPAREN
	 	{ $$ = $2; }
    ;
unary_oper:
    BANG
		{ $$ = 1; }
  | LEN
		{ $$ = 3; }
  | ORD
		{ $$ = 4; }
  | CHR
		{ $$ = 2; }
    ;
binary_oper:
    STAR
		{ $$ = 17; }
  | SLASH
		{ $$ = 16; }
  | MODULO
		{ $$ = 13; }
  | PLUS 
		{ $$ = 15; }
  | MINUS
		{ $$ = 12; }
  | GREATER
		{ $$ = 6; }
  | GREATEREQUALS
		{ $$ = 7; }
  | LESS
		{ $$ = 8; }
  | LESSEQUALS
		{$$ = 9; }
  | EQUALS
		{ $$ = 5; }		
  | NOTEQUALS
		{ $$ = 14;}
  | LOGAND
		{ $$ = 10; }
  | LOGOR
		{ $$ = 11; } 
    ;
ident:
    IDENTIFIER
		{ $<id>$ = new Identifier($<string>1); } 
    ;
array_elem_exp:
    ident array_index
		{ $$ = new ArrayElem($<id>1, $2); }
    ;
array_elem_lhs:
    ident array_index
		{ $$ = new ArrayElem($<id>1, $2); }
    ;
array_index:
		LSQUARE expr RSQUARE
		{ $$ = new ExpressionList();
			$$.push_back($2); }
	| array_index LSQUARE expr RSQUARE
		{ $1.push_back($3); }
    ;
int_liter:
		int_sign INTEGER
		{ $$ = new Number($1 * $<intValue>2)}
    ;
int_sign:
		/* empty */
		{ $$ = 1; }
	|	PLUS %prec UPLUS
		{ $$ = 1; }
	| MINUS %prec UMINUS
		{ $$ = -1; }
    ;
bool_liter:
		TRUE		
		{ $$ = new Boolean(true); }
	| FALSE
		{ $$ = new Boolean(false); }
    ;
char_liter:
		CHARLIT
		{ $$ = new Char($<charValue>1); }
    ;
str_liter:
		STRINGLIT
		{ $$ = new String($<string>1); }
    ;
array_liter:
	RSQUARE expr_list LSQUARE
	{ $$ = new ArrayLiter($2); }
    ;
expr_list:
		expr
		{ $$ = new ExpressionList();
			$$.push_back($1); }
	| expr_list COMMA expr
		{ $1.push_back($3); }
    ;
pair_liter:
		NULL 
		{ $$ = new Null(); }
    ;
%%
