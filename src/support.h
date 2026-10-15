#ifndef CPLUS_SUPPORT_H
#define CPLUS_SUPPORT_H

#include <stdio.h>

extern FILE *yyin;
extern char *yytext;
extern int yyleng;
extern int yylineno;
extern int lexical_error;

int yylex(void);
int yylex_destroy(void);
void yyerror(const char *message);
void print_lexeme(FILE *stream, const char *text, int length);
const char *token_name(int token);

#endif
