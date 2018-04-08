%{
#include <llvm-c/Core.h>
#include <stdio.h>
#include <stdlib.h>
#include "symbol.h"

extern int yylex();
extern int yyerror(char *);
extern FILE *yyin;

LLVMBuilderRef builder;
%}

%union {
    unsigned int    num;
    struct Symbol   *sym;
    LLVMValueRef    val;
}

%token  <val>   BREAK
                DO
                ELSE
                FOR
                IF
                RETURN
                WHILE

%right  <val>   '='
                '<'
                '>'
                '!'
                '$'
                '~'
                '('
                ')'

%left   <val>   '+'
                '-'
                '/'
                '*'
                '%'
                '&'
                '|'
                '^'

%right  <val>   PA  /* += */
                NA  /* -= */
                TA  /* *= */
                DA  /* /= */
                MA  /* %= */
                AA  /* &= */
                XA  /* ^= */
                OA  /* |= */
                LA  /* <<= */
                RA  /* >>= */

%left   <val>   OR  /* || */
                AN  /* && */
                EQ  /* == */
                NE  /* != */
                LE  /* <= */
                GE  /* >= */
                LS  /* << */
                RS  /* >> */
                PP  /* ++ */
                NN  /* -- */

%token  <val>   ID

%token  <val>   INT8
                INT16
                INT32

%token  <val>   FLT

%token  <val>   STR

%type   <val>   expression


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
                    { LLVMBuildRet(builder, $2); }
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
                    { $$ = LLVMBuildOr(builder, $1, $3, "or"); }
                | expression '^' expression
                    { $$ = LLVMBuildXor(builder, $1, $3, "xor"); }
                | expression '&' expression
                    { $$ = LLVMBuildAnd(builder, $1, $3, "and"); }
                | expression EQ  expression
                | expression NE  expression
                | expression '<' expression
                | expression '>' expression
                | expression LE  expression
                | expression GE  expression
                | expression LS  expression
                | expression RS  expression
                | expression '+' expression
                    { $$ = LLVMBuildAdd(builder, $1, $3, "add"); }
                | expression '-' expression
                    { $$ = LLVMBuildSub(builder, $1, $3, "sub"); }
                | expression '*' expression
                    { $$ = LLVMBuildMul(builder, $1, $3, "mul"); }
                | expression '/' expression
                    { $$ = LLVMBuildUDiv(builder, $1, $3, "div"); }
                | expression '%' expression
                    { $$ = LLVMBuildURem(builder, $1, $3, "rem"); }
                | '!' expression
                    { $$ = LLVMBuildNot(builder, $2, "not"); }
                | '~' expression
                    { $$ = LLVMBuildNot(builder, $2, "not"); }
                | '+' expression %prec '!' /* '+' at same precedence level as '!' */
                    { $$ = $2; }
                | '-' expression %prec '!' /* '-' at same precedence level as '!' */
                    { $$ = LLVMBuildNeg(builder, $2, "neg"); }
                | '(' expression ')'
                    { $$ = $2; }
                | '$' INT8
                    { $$ = LLVMBuildAlloca(builder, LLVMInt32Type(), "var"); }
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

        /* initialize symbol table */
        symbol_init();

        /* create top level module */
        LLVMModuleRef module = LLVMModuleCreateWithName("top");

        /* add a main function */
        // TODO: add a argv type
        LLVMTypeRef params_type[] = {LLVMInt32Type()};
        LLVMTypeRef ret_type = LLVMFunctionType(LLVMInt32Type(), params_type, 1, 0);
        LLVMValueRef main_func = LLVMAddFunction(module, "main", ret_type);

        /* add entry */
        LLVMBasicBlockRef basic_block = LLVMAppendBasicBlock(main_func, "entry");

        /* add builder */
        builder = LLVMCreateBuilder();
        LLVMPositionBuilderAtEnd(builder, basic_block);

        /* begin parsing */
        yyparse();

        LLVMDumpModule(module);

        /* cleanup llvm */
        LLVMDisposeBuilder(builder);
        LLVMDisposeModule(module);

        /* destroy the symbol table */
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
