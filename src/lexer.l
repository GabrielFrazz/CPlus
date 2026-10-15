%option noyywrap nodefault yylineno nounput noinput never-interactive
%x STR COMMENT

%{
#include "parser.tab.h"
#include "support.h"

int lexical_error = 0;
static int opening_line = 1;
static int fail_lexically(const char *message, int line);

#define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line = yylineno;
%}

DIGIT       [0-9]
FUNCTION    [a-z]+[A-Z][a-zA-Z0-9_]*
GLOBAL      [A-Z][A-Z0-9_]*
LOCAL       [a-z][a-z0-9_]*
WORD        [A-Za-z0-9_]+

%%

[ \t\r\n]+                {}
"//"[^\r\n]*              {}
"/*"                      { opening_line = yylineno; BEGIN(COMMENT); }
<COMMENT>"*/"             { BEGIN(INITIAL); }
<COMMENT>[^*\n]+          {}
<COMMENT>"*"              {}
<COMMENT>\n               {}
<COMMENT><<EOF>>          { return fail_lexically("comentario nao fechado", opening_line); }

\"                        { opening_line = yylineno; BEGIN(STR); yymore(); }
<STR>[^"\\\r\n]+          { yymore(); }
<STR>\\[\\"ntr]           { yymore(); }
<STR>\"                   {
                              BEGIN(INITIAL);
                              yylloc.first_line = opening_line;
                              return STRING_LITERAL;
                          }
<STR>\\[^\\"ntr\r\n]      { return fail_lexically("escape invalido na string", opening_line); }
<STR>\\                   { return fail_lexically("escape incompleto na string", opening_line); }
<STR>[\r\n]               { return fail_lexically("quebra de linha literal na string", opening_line); }
<STR><<EOF>>              { return fail_lexically("string nao fechada", opening_line); }

"var"                     { return VAR; }
"func"                    { return FUNC; }
"if"                      { return IF; }
"else"                    { return ELSE; }
"while"                   { return WHILE; }
"for"                     { return FOR; }
"in"                      { return IN; }
"step"                    { return STEP; }
"guard"                   { return GUARD; }
"return"                  { return RETURN; }
"match"                   { return MATCH; }
"default"                 { return DEFAULT; }
"true"                    { return TRUE; }
"false"                   { return FALSE; }
"null"                    { return NULL_LIT; }
"break"|"continue"|"defer" { return fail_lexically("palavra reservada para recurso nao suportado", yylineno); }

{DIGIT}+\.{DIGIT}+        { return FLOAT_LITERAL; }
{DIGIT}+                  { return INT_LITERAL; }
{FUNCTION}                { return ID_FUNCAO; }
{GLOBAL}                  { return ID_GLOBAL; }
{LOCAL}                   { return ID_LOCAL; }
{WORD}                    { return fail_lexically("identificador ou numero malformado", yylineno); }

"++"|"--"|"|>"            { return fail_lexically("operador nao suportado", yylineno); }
"=="                      { return EQ; }
"!="                      { return NE; }
"<="                      { return LE; }
">="                      { return GE; }
"&&"                      { return AND; }
"||"                      { return OR; }
"=>"                      { return ARROW; }
".."                      { return RANGE; }
[=+*/%<>!(){};,\-]        { return (unsigned char) yytext[0]; }

.                         { return fail_lexically("caractere inesperado", yylineno); }
<<EOF>>                   { yylloc.first_line = yylloc.last_line = yylineno; return 0; }

%%

static int fail_lexically(const char *message, int line)
{
    lexical_error = 1;
    yylloc.first_line = line;
    fprintf(stderr, "Erro lexico na linha %d: %s; proximo de ", line, message);
    print_lexeme(stderr, yytext, yyleng);
    fputs(".\n", stderr);
    return INVALID;
}
