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

/* BISON DECLARATIONS  ---------------------------------------------------- */

/* Define all possible syntactic values */
/* %define api.value.type variant - need if  proper C++ typing is used */

%union {
 // int                 token;
  std::string         	*string;
	int 									intValue;
	char									charValue;
 // identifier 		 		  *id;
 // StatementSeq 	 		  *statementseq;
 // Statement 		 		  *statement;
 // Expression     		  *expression;
 // ExpressionList 		 	*exprlist;
 // VariableList        *varlist;
 // VariableDeclaration *vardec;
 // FunctionDeclaration *fundec;
}

%token <token>  BEGIN END IF THEN ELSE FI WHILE DO DONE SKIP FREE EXIT TRUE FALSE

%token <token>  IS RETURN CALL

%token <token> PAIR INT BOOL CHAR STRING NULL

%token <token>  ASSIGN LESSEQUALS LESS GREATEREQUALS GREATER EQUALS BANG  
%token <token>  NOTEQUALS PLUS MINUS STAR SLASH MODULO LOGAND LOGOR

%token <token>  LPAREN RPAREN LSQUARE RSQUARE SEMICOLON COMMA ERROR

%token <token> PRINT PRINTLN READ NEWPAIR FST SND LEN ORD CHR

%token <string> IDENTIFIER STRINGLIT

%token<char> CHARLIT

%token<int> INTEGER

%type <id>	       			ident
%type <statementseq>    statement_seq  
%type <statement>  			statement begin_statement assign_statement  
%type <statement>  			if_statement while_statement 
%type <statement>  			repeat_statement read_statement write_statement
%type <expression> 			expression  number
%type <exprlist>   			actual_parameters
%type <varlist>    			formal_parameters
%type <token>	     			comparator
%type <vardec>	   			variable_declaration
%type <fundec>     			function_declaration


/* Precedence of operators */
%left PLUS MINUS STAR SLASH MODULO 

/* Start symbol. If omitted will default to first non-terminal symbol */
%start program 

%%
program: 
    BEGIN func_list statement_seq END
		{ ast = new Program($2, $3) }

func_list:
	/* empty */ 
		{ $$ = new FunctionDecList(); }
	| function_declaration 
		{ $$ = new FunctionDecList(); 
			$$->funcs.push_back(&$1); }
	| func_list function_declaration
		{ $1->funcs.push_back(&$2); }

function_declaration:
		type ident LPAREN RPAREN IS statement END
		{ $$ = new FunctionDeclaration($1, $2, $6); }
	| type ident LPAREN param_list RPAREN IS statement END
		{ $$ = new FunctionDeclaration($1, $2, $4, $7); }

param_list:
    param
		{ $$ = new VariableList();
			$$.push_back_(&$1); }
  | param_list COMMA param
		{ $1.push_back(&$3); }

param:
		type ident
		{ $$ = new VariableDeclaration($1, $2); }

statement_seq:
		statement
		{ $$ = new StatSeq();
			$$->statements.push_back($1); }
	| statement_seq SEMICOLON statement
		{ $1->statements.push_back($3); }

statement:
    SKIP
		{ $$ = new SkipStatement(); }
  | type ident ASSIGN assign-rhs
		{ $$ = new VariableDeclaration($1, $2, &$4); }
  | assign-lhs ASSIGN assign-rhs
		{ $$ = new Assignment($1, $3); }
  | READ assign-lhs
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
  | statement_seq
		{ $$ = $1; }
		
assign-lhs:
		ident
		{ $$ = $1; } 
  | array-elem
		{ $$ = $1; } 
	| pair-elem
		{ $$ = $1; } 

assign-rhs:
    expr
		{ $$ = $1; } 
  | array-liter
		{ $$ = $1; } 
  | NEWPAIR LPAREN expr COMMA expr RPAREN
		{ $$ = new NewPair($3, $5); } 
  | pair-elem
		{ $$ = $1; } 
	| CALL ident LPAREN RPAREN
		{ $$ = new FunctionCall($2); }
  | CALL ident LPAREN arg-list RPAREN
		{ $$ = new FunctionCall($2, $4); }

arg-list:
    expr
		{ $$ = new ExpressionList();
			$$.push_back($1); } 
  | arg-list COMMA expr 
		{ $1.push_back($3); }

pair-elem:
    FST expr
		{ $$ = new PairElem(true, $2); }
  | SND expr
		{ $$ = new PairElem(false, $2); }

type:
    base-type
		{ $$ = $1; }
  | array-type
		{ $$ = $1; }
  | pair-type
		{ $$ = $1; }

base-type:
    INT
		{ $$ = new IntegerType($1); }
  | BOOL
		{ $$ = new BoolType($1); }
  | CHAR
		{ $$ = new CharType($1); }
  | STRING
		{ $$ = new StringType($1); }

array-type:
  type LSQUARE RSQUARE
	{ $$ = new ArrayType($1); }

pair-type:
  PAIR LPAREN pair-elem-type COMMA pair-elem-type RPAREN
	{ $$ = new PairType($3, $5); }

pair-elem-type:
    base-type
		{ $$ = $1; }
  | array-type
		{ $$ = $1; }
  | PAIR
	{ $$ = new PairKeyword(); }

expr:
    int-liter
		{ $$ = $1; }
  | bool-liter
		{ $$ = $1; }
  | char-liter 
		{ $$ = $1; }
  | str-liter
		{ $$ = $1; }
  | pair-liter
		{ $$ = $1; }
  | ident
		{ $$ = $1; }
  | array-elem
		{ $$ = $1; }
  | unary-oper expr
		{ $$ = new UnaryOperator($1, $2); }
  | expr binary-oper expr
		{ $$ = new BinaryOperator($1, $2, $3); }
  | LPAREN expr RPAREN
	 	{ $$ = $2; }

unary-oper:
    BANG
		{ $$ = 1; }
  | MINUS
		{ $$ = 4; }
  | LEN
		{ $$ = 3; }
  | ORD
		{ $$ = 5; }
  | CHR
		{ $$ = 2; }

binary-oper:
    STAR
		{ $$ = 18; }
  | SLASH
		{ $$ = 17; }
  | MODULO
		{ $$ = 14; }
  | PLUS 
		{ $$ = 16; }
  | MINUS
		{ $$ = 13; }
  | GREATER
		{ $$ = 7; }
  | GREATEREQUALS
		{ $$ = 8; }
  | LESS
		{ $$ = 9; }
  | LESSEQUALS
		{$$ = 10; }
  | EQUALS
		{ $$ = 6; }		
  | NOTEQUALS
		{ $$ = 15;}
  | LOGAND
		{ $$ = 11; }
  | LOGOR
		{ $$ = 12; } 

ident:
    IDENTIFIER
		{ $$ = new Identifier($<string>1); } 

array-elem:
    ident array-index
		{ $$ = new ArrayElem($1, $2); }

array-index:
		LSQUARE expr RSQUARE
		{ $$ = new ExpressionList();
			$$.push_back($2); }
	| array-index LSQUARE expr RSQUARE
		{ $1.push_back($3); }

int-liter:
		int-sign INTEGER
		{ $$ = new Number($1 * $<intValue>2)}

int-sign:
		/* empty */
		{ $$ = 1; }
	|	PLUS
		{ $$ = 1; }
	| MINUS
		{ $$ = -1; }

bool-liter:
		TRUE		
		{ $$ = new Boolean(true); }
	| FALSE
		{ $$ = new Boolean(false); }

char-liter:
		CHARLIT
		{ $$ = new Char($<charValue>1); }

str-liter:
		STRINGLIT
		{ $$ = new String($<string>1); }

array-liter:
	RSQUARE expr-list LSQUARE
	{ $$ = new ArrayLiter($2); }

expr-list:
		expr
		{ $$ = new ExpressionList();
			$$.push_back($1); }
	| expr-list COMMA expr
		{ $1.push_back($3); }

pair-liter:
		NULL 
		{ $$ = new Null(); }

%%
