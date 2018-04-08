%{
#include <stdio.h>
#include "util.h"

extern int yylex();
extern int yyerror(char *);
%}

%union {
    int             num;
    struct Symbol   *sym;
}

%token  <sym>   BREAK
                DO
                ELSE
                FOR
                IF
                RETURN
                WHILE

%right          '='
                '<'
                '>'
                '!'
                '$'
                '~'

%left           '+'
                '-'
                '/'
                '*'
                '%'
                '&'
                '|'
                '^'

%right          PA  /* += */
                NA  /* -= */
                TA  /* *= */
                DA  /* /= */
                MA  /* %= */
                AA  /* &= */
                XA  /* ^= */
                OA  /* |= */
                LA  /* <<= */
                RA  /* >>= */

%left           OR  /* || */
                AN  /* && */
                EQ  /* == */
                NE  /* != */
                LE  /* <= */
                GE  /* >= */
                LS  /* << */
                RS  /* >> */
                PP  /* ++ */
                NN  /* -- */

%token  <sym>   ID

%token  <num>   INT8
                INT16
                INT32

%token  <flt>   FLT

%token  <str>   STR


%%

statements      : statements statement
                | /* empty */
                ;

statement       : ';'
                | expression ';'
                | IF '(' expression ')' statement ELSE statement
                | IF '(' expression ')' statement
                | WHILE '(' expression ')' statement
                | DO statement WHILE '(' expression ')' ';'
                | FOR '(' expression ';' expression ';' expression ')' statement
                | RETURN expression ';'
                | BREAK ';'
                | '{' statements '}'
                ;

expression      : ID '=' expression
                | ID PA  expression
                | ID NA  expression
                | ID TA  expression
                | ID DA  expression
                | ID MA  expression
                | ID AA  expression
                | ID XA  expression
                | ID OA  expression
                | ID LA  expression
                | ID RA  expression
                | expression OR  expression
                | expression AN  expression
                | expression '|' expression
                | expression '^' expression
                | expression '&' expression
                | expression EQ  expression
                | expression NE  expression
                | expression '<' expression
                | expression '>' expression
                | expression LE  expression
                | expression GE  expression
                | expression LS  expression
                | expression RS  expression
                | expression '+' expression
                | expression '-' expression
                | expression '*' expression
                | expression '/' expression
                | expression '%' expression
                | '!' expression
                | '~' expression
                | '+' expression %prec '!' /* '+' at same precedence level as '!' */
                | '-' expression %prec '!' /* '-' at same precedence level as '!' */
                | '(' expression ')'
                | '$' INT8
                | PP ID
                | NN ID
                | ID PP
                | ID NN
                | ID
                | INT8
                | INT16
                | INT32
                | FLT
                | STR
                ;

%%

int main(int argc, char *argv[])
{
    yyparse();
    return 0;
}

int yyerror(char *message) {
    error (message, E_LEX);
    return 0;
}
