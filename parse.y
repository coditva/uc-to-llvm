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
    LLVMBasicBlockRef    blk;
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

%token  <sym>   ID

%token  <num>   INT8
                INT16
                INT32

%token  <val>   FLT

%token  <val>   STR

%type   <val>   expression
%type   <blk>   statement statements


%%

statements      : statements statement
                | /* empty */
                ;

statement       : ';'
                    { $$ = NULL; }
                | expression ';'
                    { $$ = $1; }
                | IF '(' expression ')' statement ELSE statement
                    { $$ = LLVMBuildCondBr(builder, $3, $5, $7); }
                | IF '(' expression ')' statement
                    { $$ = LLVMBuildCondBr(builder, $3, $5, NULL); }
                | WHILE '(' expression ')' statement
                | DO statement WHILE '(' expression ')' ';'
                | FOR '(' expression ';' expression ';' expression ')' statement
                | RETURN expression ';'
                    { $$ = LLVMBuildRet(builder, $2); }
                | BREAK ';'
                | '{' statements '}'
                ;

expression      : ID '=' expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (!sym) { sym = symbol_insert($1 -> identifier, ID); }
                      sym -> value = $3;
                      $$ = LLVMBuildLoad(builder, $3, "assn");
                    }
                | ID PA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildAdd(builder, sym -> value, $3, "addinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID NA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildSub(builder, sym -> value, $3, "subinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID TA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildMul(builder, sym -> value, $3, "mulinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID DA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildUDiv(builder, sym -> value, $3, "divinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID MA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildURem(builder, sym -> value, $3, "modinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID AA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildAnd(builder, sym -> value, $3, "andinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID XA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildXor(builder, sym -> value, $3, "xorinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID OA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildOr(builder, sym -> value, $3, "orinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID LA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildShl(builder, sym -> value, $3, "lshinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
                | ID RA  expression
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        sym -> value = LLVMBuildLShr(builder, sym -> value, $3, "rshinc");
                      } else {
                        yyerror("Symbol not defined");
                      }
                    }
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
                    { struct Symbol *sym = symbol_lookup($1 -> identifier);
                      if (sym) {
                        $$ = sym -> value;
                      } else {
                        yyerror("Not defined");
                      }
                    }
                | INT8
                    { $$ = LLVMConstInt(LLVMInt8Type(), $1, 0); }
                | INT16
                    { $$ = LLVMConstInt(LLVMInt16Type(), $1, 0); }
                | INT32
                    { $$ = LLVMConstInt(LLVMInt32Type(), $1, 0); }
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
