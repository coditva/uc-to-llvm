%{
#include <llvm-c/Core.h>
#include "datatypes.h"
#include "y.tab.h"
#include "symbol.h"

static int install_id();
static int install_int();
extern int yyerror(char *);
%}

%option noyywrap
%option yylineno

digit           [0-9]
alpha           [a-zA-Z_]
id              {alpha}({alpha}|{digit})*
int             {digit}+
token           [!$%&()*+,\-./:;<=>?\[\]^{|}~]

%%
[ \t\v\n\f\r]   /* skip whitespace */
"//".*[\n]      /* skip comments */
{id}    		{
                    yylval.sym = symbol_lookup(yytext);
                    if (!yylval.sym) yylval.sym = symbol_insert(yytext, ID);
                    return yylval.sym -> token;
                }
{int}   		{
                    sscanf(yytext, "%u", &yylval.num);
                    return INT;
                }
"+="  			{ return PA; }
"-="  			{ return NA; }
"*="  			{ return TA; }
"/="  			{ return DA; }
"%="  			{ return MA; }
"&="  			{ return AA; }
"^="  			{ return XA; }
"|="  			{ return OA; }
"<<=" 			{ return LA; }
">>=" 			{ return RA; }
"||"  			{ return OR; }
"&&"  			{ return AN; }
"=="  			{ return EQ; }
"!="  			{ return NE; }
"<="  			{ return LE; }
">="  			{ return GE; }
"<<"  			{ return LS; }
">>"  			{ return RS; }
"++"  			{ return PP; }
"--"  			{ return NN; }
{token}         { return yytext[0]; }
.               { yyerror("Unknown character found"); }
%%
