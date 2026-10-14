%{
#include "support.h"
%}

%define parse.error detailed
%define parse.lac full
%define parse.trace
%locations
%expect 0

%token VAR "var" FUNC "func" IF "if" ELSE "else"
%token WHILE "while" FOR "for" IN "in" STEP "step"
%token GUARD "guard" RETURN "return" MATCH "match" DEFAULT "default"
%token TRUE "true" FALSE "false" NULL_LIT "null"
%token ID_GLOBAL "identificador global" ID_LOCAL "identificador local"
%token ID_FUNCAO "nome de funcao"
%token INT_LITERAL "inteiro" FLOAT_LITERAL "decimal" STRING_LITERAL "string"
%token EQ "==" NE "!=" LE "<=" GE ">=" AND "&&" OR "||"
%token ARROW "=>" RANGE ".." INVALID "token lexico invalido"

%start programa

%%

/* Uma lista não vazia rejeita arquivos vazios. O Bison exige EOF ao aceitar. */
programa: itens_topo ;
itens_topo: item_topo | itens_topo item_topo ;
item_topo: decl_global | decl_funcao ;

decl_global: VAR ID_GLOBAL inicializacao_opcional ';' ;
inicializacao_opcional: %empty | '=' expressao ;
decl_funcao: FUNC ID_FUNCAO '(' parametros_opcionais ')' bloco ;
parametros_opcionais: %empty | parametros ;
parametros: ID_LOCAL | parametros ',' ID_LOCAL ;

/* Só blocos dentro de funções alcançam comandos; funções não são comandos. */
bloco: '{' comandos '}' ;
comandos: %empty | comandos comando ;
comando:
    decl_local
  | atribuicao
  | expressao ';'
  | RETURN expressao ';'
  | condicional
  | repeticao_while
  | repeticao_for
  | guarda
  | bloco
;
decl_local: VAR ID_LOCAL inicializacao_opcional ';' ;
atribuicao: identificador_variavel '=' expressao ';' ;
identificador_variavel: ID_LOCAL | ID_GLOBAL ;

/* Chaves obrigatórias eliminam o problema do dangling else. */
condicional: IF '(' expressao ')' bloco alternativa_opcional ;
alternativa_opcional: %empty | ELSE bloco ;
repeticao_while: WHILE '(' expressao ')' bloco ;
repeticao_for: FOR '(' ID_LOCAL IN expressao RANGE expressao passo_opcional ')' bloco ;
passo_opcional: %empty | STEP expressao ;
guarda: GUARD '(' expressao ')' ELSE RETURN expressao ';' ;

/* Cada nível só usa operandos de maior precedência; recursão à esquerda
   agrupa os operadores binários à esquerda. Não há avaliação. */
expressao: expressao_ou ;
expressao_ou: expressao_e | expressao_ou OR expressao_e ;
expressao_e: expressao_igualdade | expressao_e AND expressao_igualdade ;
expressao_igualdade:
    expressao_relacional
  | expressao_igualdade EQ expressao_relacional
  | expressao_igualdade NE expressao_relacional
;
expressao_relacional:
    expressao_aditiva
  | expressao_relacional '<' expressao_aditiva
  | expressao_relacional LE expressao_aditiva
  | expressao_relacional '>' expressao_aditiva
  | expressao_relacional GE expressao_aditiva
;
expressao_aditiva:
    expressao_multiplicativa
  | expressao_aditiva '+' expressao_multiplicativa
  | expressao_aditiva '-' expressao_multiplicativa
;
expressao_multiplicativa:
    expressao_unaria
  | expressao_multiplicativa '*' expressao_unaria
  | expressao_multiplicativa '/' expressao_unaria
  | expressao_multiplicativa '%' expressao_unaria
;
expressao_unaria:
    expressao_primaria
  | '!' expressao_unaria
  | '-' expressao_unaria
;
expressao_primaria:
    literal
  | identificador_variavel
  | chamada_funcao
  | '(' expressao ')'
  | expressao_match
;
chamada_funcao: ID_FUNCAO '(' argumentos_opcionais ')' ;
argumentos_opcionais: %empty | argumentos ;
argumentos: expressao | argumentos ',' expressao ;

/* Pelo menos um caso literal e exatamente um default ao final. */
expressao_match:
    MATCH '(' expressao ')' '{' casos_match ',' DEFAULT ARROW expressao virgula_opcional '}'
;
casos_match: caso_match | casos_match ',' caso_match ;
caso_match: literal_caso ARROW expressao ;
literal_caso: literal | '-' INT_LITERAL | '-' FLOAT_LITERAL ;
virgula_opcional: %empty | ',' ;
literal: INT_LITERAL | FLOAT_LITERAL | STRING_LITERAL | TRUE | FALSE | NULL_LIT ;

%%

void yyerror(const char *message)
{
    if (lexical_error) return; /* Preservar o diagnóstico específico do lexer. */
    fprintf(stderr, "Erro sintatico na linha %d, proximo de ", yylloc.first_line);
    print_lexeme(stderr, yytext, yyleng);
    fprintf(stderr, ": %s.\n", message);
}
