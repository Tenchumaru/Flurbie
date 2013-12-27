%{
#include <cctype>
#include <cstdlib>
#include <cstring>
#include "parser.h"
#include "scanner.h"
#ifdef DEBUG
#	define DBOUT(v) (printf(" '%s':%d ", yytext, (v)), (v))
#else
#	define DBOUT(v) (v)
#endif
#pragma warning(push)
#pragma warning(disable: 4127 4996)

extern int pc_index;
%}

ws      [\r\t\v ]+
rem     ;.*
reg1    r[012]?[0-9]
reg2    r3[01]
id      [_a-z][_0-9a-z]*
hex     $[0-9a-f]+
num     [0-9]+

%%
{ws}    |
{rem}   ;
{hex}   { yylval.value= strtoul(yytext + 1, nullptr, 16); return DBOUT(VALUE); }
{num}   { yylval.value= strtoul(yytext, nullptr, 0); return DBOUT(VALUE); }
addc    { yylval.value=  1 << 23; return DBOUT(OP); }
nand    { yylval.value=  9 << 23; return DBOUT(OP); }
subb    { yylval.value=  3 << 23; return DBOUT(OP); }
udiv    { yylval.value=  7 << 23; return DBOUT(OP); }
umul    { yylval.value=  5 << 23; return DBOUT(OP); }
xnor    { yylval.value= 13 << 23; return DBOUT(OP); }
add     { yylval.value=  0 << 23; return DBOUT(OP); }
and     { yylval.value=  8 << 23; return DBOUT(OP); }
div     { yylval.value=  6 << 23; return DBOUT(OP); }
mul     { yylval.value=  4 << 23; return DBOUT(OP); }
nor     { yylval.value= 11 << 23; return DBOUT(OP); }
sub     { yylval.value=  2 << 23; return DBOUT(OP); }
xor     { yylval.value= 12 << 23; return DBOUT(OP); }
or      { yylval.value= 10 << 23; return DBOUT(OP); }
ldi     { yylval.value= LDI; return DBOUT(OP); }
xorih   { yylval.value= XORIH; return DBOUT(OP); }
ld      { yylval.value= LD; return DBOUT(OP); }
st      { yylval.value= ST; return DBOUT(OP); }
int     { return DBOUT(INT); }
nop     { return DBOUT(NOP); }
cx      { yylval.value= CX; return DBOUT(SOP); }
pc      { yylval.value= pc_index; return DBOUT(REG); }
{reg1}  |
{reg2}  { yylval.value= atoi(yytext + 1); return DBOUT(REG); }
{id}    { yylval.id= _strdup(yytext); return DBOUT(ID); }
">>>"   return DBOUT(ASR);
"<<"    return DBOUT(SHL);
">>"    return DBOUT(LSR);
\n      return DBOUT('\n');
.       return DBOUT(tolower(yytext[0]));
%%
#pragma warning(pop)

int yywrap() {
	return 1;
}

#pragma warning(disable: 4505)
