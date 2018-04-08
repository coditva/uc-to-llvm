%{
#include <stdio.h>
#include <stdlib.h>
#include "symbol.h"

extern int yylex();
extern int yyerror(char *);
extern FILE *yyin;
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
    if (argc > 1) {
        if (!(yyin = fopen(argv[1], "r"))) {
            fprintf(stderr, "Error: %s\n", "Cannot open file");
            return 1;
        }
        symbol_init();
        yyparse();
        symbol_destroy();
    } else {
        fprintf(stderr, "Usage: %s FILENAME\n", argv[0]);
        return 1;
    }
    return 0;
}

int yyerror(char *message) {
    fprintf(stderr, "Error: %s\n", message);
    exit(1);
}
