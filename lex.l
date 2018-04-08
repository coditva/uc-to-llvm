%{
#include "y.tab.h"
#include "datatypes.h"
%}

%option noyywrap

digit           [0-9]
alpha           [a-zA-Z_]
id              {alpha}({alpha}|{digit})*
int             {digit}+

%%

[ \t\v\n\f\r]   /* skip whitespace */

";"     		{ return SEMICOLON; }

{id}    		{ return ID; }
{int}   		{ return INT8; }

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

%%
