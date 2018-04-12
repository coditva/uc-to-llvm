%{
#include <llvm-c/Core.h>
#include <stdio.h>
#include <stdlib.h>
#include "symbol.h"

extern int  yylex();
extern int  yyerror(char *);
extern FILE *yyin;
static int returned = 0;

LLVMBuilderRef      builder;
LLVMModuleRef       module;
LLVMValueRef        main_func;
LLVMBasicBlockRef   curr;
LLVMBasicBlockRef   entry;
%}

%union {
    unsigned int        num;
    struct Symbol       *sym;
    LLVMValueRef        val;
    LLVMBasicBlockRef   blk;
}

%token<val> BREAK
            DO
            ELSE
            FOR
            IF
            RETURN
            WHILE

%right<val> '='
            '<'
            '>'
            '!'
            '$'
            '~'
            '('
            ')'

%left<val>  '+'
            '-'
            '/'
            '*'
            '%'
            '&'
            '|'
            '^'

%right<val> PA  /* += */
            NA  /* -= */
            TA  /* *= */
            DA  /* /= */
            MA  /* %= */
            AA  /* &= */
            XA  /* ^= */
            OA  /* |= */
            LA  /* <<= */
            RA  /* >>= */

%left<val>  OR  /* || */
            AN  /* && */
            EQ  /* == */
            NE  /* != */
            LE  /* <= */
            GE  /* >= */
            LS  /* << */
            RS  /* >> */
            PP  /* ++ */
            NN  /* -- */

%token<sym> ID

%token<num> INT8
            INT16
            INT32

%token<val> FLT

%token<val> STR

%type<val>  expression
%type<blk>  statement statements
%type<blk>  startthen startelse endif
%type<blk>  startloop endloop forinc loopbody


%%

statements  : statements statement
              { $$ = $2; }
            | /* empty */
              { $$ = LLVMValueAsBasicBlock(NULL); }
            ;

statement   : ';'
              { $$ = LLVMValueAsBasicBlock(NULL); }
            | expression ';'
              { $$ = LLVMValueAsBasicBlock($1); }
            | IF '(' expression ')' startthen statement ELSE startelse statement endif
              {
                LLVMPositionBuilderAtEnd(builder, entry);
                LLVMBuildCondBr(builder, $3, $5, $8);

                /* put branch instruction after completion of then, else blocks */
                LLVMPositionBuilderAtEnd(builder, $5);
                LLVMBuildBr(builder, $10);
                LLVMPositionBuilderAtEnd(builder, $8);
                LLVMBuildBr(builder, $10);

                LLVMPositionBuilderAtEnd(builder, $10);
                $$ = $10;
              }
            | IF '(' expression ')' startthen statement endif
              {
                LLVMPositionBuilderAtEnd(builder, entry);
                LLVMBuildCondBr(builder, $3, $5, $7);

                /* put branch intruction after completion of then block */
                LLVMPositionBuilderAtEnd(builder, $5);
                LLVMBuildBr(builder, $7);

                LLVMPositionBuilderAtEnd(builder, $7);
                $$ = $7;
              }
            | WHILE startloop '(' expression ')' loopbody statement endloop
              {
                /* jump to loop */
                LLVMPositionBuilderAtEnd(builder, entry);
                LLVMBuildBr(builder, $2);

                /* add condition */
                LLVMPositionBuilderAtEnd(builder, $2);
                LLVMBuildCondBr(builder, $4, $6, $8);

                /* check condition for while */
                LLVMPositionBuilderAtEnd(builder, $6);
                LLVMBuildBr(builder, $2);

                LLVMPositionBuilderAtEnd(builder, $8);
                $$ = $7;
              }
            | DO startloop statement WHILE '(' expression ')' ';' endloop
              {
                LLVMBuildCondBr(builder, $6, $2, $9);
                LLVMPositionBuilderAtEnd(builder, $9);
                $$ = $9;
              }
            | FOR '(' expression ';' expression ';' forinc expression ')'
                    startloop statement endloop
              {
                LLVMPositionBuilderAtEnd(builder, entry);
                LLVMBuildCondBr(builder, $5, $10, $12);

                /* put the increment at the end of while */
                LLVMPositionBuilderAtEnd(builder, $10);
                LLVMBuildBr(builder, $7);

                /* branch back to while from forinc */
                LLVMPositionBuilderAtEnd(builder, $7);
                LLVMBuildBr(builder, $10);

                /* check condition for loop */
                LLVMPositionBuilderAtEnd(builder, $10);
                LLVMBuildCondBr(builder, $5, $10, $12);

                LLVMPositionBuilderAtEnd(builder, $12);
                $$ = $12;
              }
            | RETURN expression ';'
              {
                /* cast retval to i32 */
                LLVMValueRef retval =
                    LLVMBuildSExt(builder, $2, LLVMInt32Type(), "retcast");

                LLVMValueRef ret = LLVMBuildRet(builder, retval);
                $$ = LLVMValueAsBasicBlock(ret);
                returned = 1;
              }
            | BREAK ';'
              { $$ = LLVMValueAsBasicBlock(NULL); }
            | '{' statements '}'
              { $$ = $2; }
            ;

expression  : ID '=' expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (!sym) yyerror("Symbol not found");
                if (!sym -> value) {
                    sym -> value = LLVMBuildAlloca(builder, LLVMTypeOf($3),
                            $1 -> identifier);
                }
                $$ = LLVMBuildStore(builder, $3, sym -> value);
              }
            | ID PA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym && sym -> value) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildAdd(builder, val, $3, "addinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID NA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildSub(builder, val, $3, "subinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID TA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildMul(builder, val, $3, "mulinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID DA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildSDiv(builder, val, $3, "divinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID MA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildSRem(builder, val, $3, "modinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID AA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildAnd(builder, val, $3, "andinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID XA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildXor(builder, val, $3, "andinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID OA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildOr(builder, val, $3, "orinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID LA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildShl(builder, val, $3, "lshinc"),
                            sym -> value);
                    $$ = sym -> value;
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID RA  expression
              {
                struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMBuildStore(builder,
                            LLVMBuildLShr(builder, val, $3, "rshinc"),
                            sym -> value);
                    $$ = sym -> value;
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
              { $$ = LLVMBuildICmp(builder, LLVMIntEQ, $1, $3, "compeq"); }
            | expression NE  expression
              { $$ = LLVMBuildICmp(builder, LLVMIntNE, $1, $3, "compne"); }
            | expression '<' expression
              { $$ = LLVMBuildICmp(builder, LLVMIntSGT, $1, $3, "compgt"); }
            | expression '>' expression
              { $$ = LLVMBuildICmp(builder, LLVMIntSLT, $1, $3, "complt"); }
            | expression LE  expression
              { $$ = LLVMBuildICmp(builder, LLVMIntSLE, $1, $3, "comple"); }
            | expression GE  expression
              { $$ = LLVMBuildICmp(builder, LLVMIntSGE, $1, $3, "compge"); }
            | expression LS  expression
              { $$ = LLVMBuildShl(builder, $1, $3, "shl"); }
            | expression RS  expression
              { $$ = LLVMBuildLShr(builder, $1, $3, "shr"); }
            | expression '+' expression
              { $$ = LLVMBuildAdd(builder, $1, $3, "add"); }
            | expression '-' expression
              { $$ = LLVMBuildSub(builder, $1, $3, "sub"); }
            | expression '*' expression
              { $$ = LLVMBuildMul(builder, $1, $3, "mul"); }
            | expression '/' expression
              { $$ = LLVMBuildSDiv(builder, $1, $3, "div"); }
            | expression '%' expression
              { $$ = LLVMBuildSRem(builder, $1, $3, "mod"); }
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
              {
                /* TODO: implement this */
                /*$$ = LLVMBuildAlloca(builder, LLVMInt8Type(), "load");*/
                /*LLVMBuildStore(builder, LLVMConstInt(LLVMInt8Type(), 0, 0), $$);*/
                $$ = LLVMConstInt(LLVMInt8Type(), 1, 0);
              }
            | PP ID
              { struct Symbol *sym = symbol_lookup($2 -> identifier);
                if (sym) {
                    LLVMValueRef val1 = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMValueRef val2 = LLVMConstInt(LLVMInt8Type(), 1, 0);
                    $$ = LLVMBuildAdd(builder, val1, val2, "postdec");
                    LLVMBuildStore(builder, $$, sym -> value);
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | NN ID
              { struct Symbol *sym = symbol_lookup($2 -> identifier);
                if (sym) {
                    LLVMValueRef val1 = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMValueRef val2 = LLVMConstInt(LLVMInt8Type(), 1, 0);
                    $$ = LLVMBuildSub(builder, val1, val2, "postdec");
                    LLVMBuildStore(builder, $$, sym -> value);
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID PP
              { struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val1 = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMValueRef val2 = LLVMConstInt(LLVMInt8Type(), 1, 0);
                    $$ = LLVMBuildAdd(builder, val1, val2, "postdec");
                    LLVMBuildStore(builder, $$, sym -> value);
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID NN
              { struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym) {
                    LLVMValueRef val1 = LLVMBuildLoad(builder, sym -> value,
                            "load");
                    LLVMValueRef val2 = LLVMConstInt(LLVMInt8Type(), 1, 0);
                    $$ = LLVMBuildSub(builder, val1, val2, "postdec");
                    LLVMBuildStore(builder, $$, sym -> value);
                } else {
                    yyerror("Symbol not defined");
                }
              }
            | ID
              { struct Symbol *sym = symbol_lookup($1 -> identifier);
                if (sym && sym -> value) {
                    $$ = LLVMBuildLoad(builder, sym -> value, "load");
                } else {
                    yyerror("Symbol not defined");
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

startthen   : /* empty */
              {
                $$ = LLVMAppendBasicBlock(main_func, "then");
                LLVMPositionBuilderAtEnd(builder, $$);
              }
            ;
startelse   : /* empty */
              {
                $$ = LLVMAppendBasicBlock(main_func, "else");
                LLVMPositionBuilderAtEnd(builder, $$);
              }
            ;
endif       : /* empty */
              { $$ = LLVMAppendBasicBlock(main_func, "endif"); }
            ;
startloop  : /* empty */
              {
                $$ = LLVMAppendBasicBlock(main_func, "loop");
                LLVMPositionBuilderAtEnd(builder, $$);
              }
            ;
endloop    : /* empty */
              { $$ = LLVMAppendBasicBlock(main_func, "endloop"); }
            ;
forinc      : /* empty */
              {
                $$ = LLVMAppendBasicBlock(main_func, "forinc");
                LLVMPositionBuilderAtEnd(builder, $$);
              }
            ;
loopbody    : /* empty */
              {
                $$ = LLVMAppendBasicBlock(main_func, "loopbody");
                LLVMPositionBuilderAtEnd(builder, $$);
              }
            ;

%%

int main(int argc, char *argv[])
{
    char filename[] = "a.ll";
    if (argc > 1) {
        if (!(yyin = fopen(argv[1], "r"))) {
            fprintf(stderr, "Error: %s\n", "Cannot open file");
            return 1;
        }

        /* initialize symbol table */
        symbol_init();

        /* create top level module */
        module = LLVMModuleCreateWithName("main");

        /* add a main function */
        // TODO: add a argv type
        LLVMTypeRef params_type[] = {LLVMInt32Type()};
        LLVMTypeRef ret_type = LLVMFunctionType(LLVMInt32Type(), params_type, 1, 0);
        main_func = LLVMAddFunction(module, "main", ret_type);

        /* add entry */
        entry = LLVMAppendBasicBlock(main_func, "entry");

        /* add builder */
        builder = LLVMCreateBuilder();
        LLVMPositionBuilderAtEnd(builder, entry);

        /* begin parsing */
        yyparse();

        /* add return if not present */
        if (!returned) {
            LLVMBuildRet(builder, LLVMConstInt(LLVMInt32Type(), 1, 0));
        }
         
        /* print to file */
        LLVMDumpModule(module);
        LLVMPrintModuleToFile(module, filename, NULL);

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
