#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include "parser.tab.h"
#include "support.h"

/* Escapar controles mantém cada diagnóstico/token em uma única linha. */
void print_lexeme(FILE *stream, const char *text, int length)
{
    if (!text || length == 0) {
        fputs("<EOF>", stream);
        return;
    }
    fputc('"', stream);
    for (int i = 0; i < length; ++i) {
        unsigned char ch = (unsigned char) text[i];
        switch (ch) {
            case '\n': fputs("\\n", stream); break;
            case '\r': fputs("\\r", stream); break;
            case '\t': fputs("\\t", stream); break;
            case '\\': fputs("\\\\", stream); break;
            case '"': fputs("\\\"", stream); break;
            default:
                if (ch < 32 || ch == 127) fprintf(stream, "\\x%02X", ch);
                else fputc(ch, stream);
        }
    }
    fputc('"', stream);
}

const char *token_name(int token)
{
    switch (token) {
#define TOKEN_NAME(t) case t: return #t
        TOKEN_NAME(VAR); TOKEN_NAME(FUNC); TOKEN_NAME(IF); TOKEN_NAME(ELSE);
        TOKEN_NAME(WHILE); TOKEN_NAME(FOR); TOKEN_NAME(IN); TOKEN_NAME(STEP);
        TOKEN_NAME(GUARD); TOKEN_NAME(RETURN); TOKEN_NAME(MATCH); TOKEN_NAME(DEFAULT);
        TOKEN_NAME(TRUE); TOKEN_NAME(FALSE); TOKEN_NAME(NULL_LIT);
        TOKEN_NAME(ID_GLOBAL); TOKEN_NAME(ID_LOCAL); TOKEN_NAME(ID_FUNCAO);
        TOKEN_NAME(INT_LITERAL); TOKEN_NAME(FLOAT_LITERAL); TOKEN_NAME(STRING_LITERAL);
        TOKEN_NAME(EQ); TOKEN_NAME(NE); TOKEN_NAME(LE); TOKEN_NAME(GE);
        TOKEN_NAME(AND); TOKEN_NAME(OR); TOKEN_NAME(ARROW); TOKEN_NAME(RANGE);
#undef TOKEN_NAME
        case '=': return "ASSIGN";
        case '+': return "PLUS";
        case '-': return "MINUS";
        case '*': return "STAR";
        case '/': return "SLASH";
        case '%': return "MOD";
        case '<': return "LT";
        case '>': return "GT";
        case '!': return "NOT";
        case '(': return "LPAREN";
        case ')': return "RPAREN";
        case '{': return "LBRACE";
        case '}': return "RBRACE";
        case ',': return "COMMA";
        case ';': return "SEMICOLON";
        default: return "INVALID";
    }
}

static void usage(FILE *stream)
{
    fputs("Uso: cplus arquivo.cplus\n"
          "     cplus --tokens arquivo.cplus\n"
          "     cplus --help\n", stream);
}

int main(int argc, char **argv)
{
    int tokens_only = 0;
    const char *path;
    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        usage(stdout);
        return 0;
    }
    if (argc == 3 && strcmp(argv[1], "--tokens") == 0) {
        tokens_only = 1;
        path = argv[2];
    } else if (argc == 2 && argv[1][0] != '-') {
        path = argv[1];
    } else {
        usage(stderr);
        return 3;
    }

    struct stat info;
    if (stat(path, &info) != 0) {
        fprintf(stderr, "Erro de arquivo: %s: ", path);
        perror(NULL);
        return 3;
    }
    if (!S_ISREG(info.st_mode)) {
        fprintf(stderr, "Erro de arquivo: '%s' nao e um arquivo regular.\n", path);
        return 3;
    }
    yyin = fopen(path, "rb");
    if (!yyin) {
        fprintf(stderr, "Erro de arquivo: %s: ", path);
        perror(NULL);
        return 3;
    }

    int result = 0;
    if (tokens_only) {
        int token;
        while ((token = yylex()) != 0 && !lexical_error) {
            printf("%d\t%s\t", yylloc.first_line, token_name(token));
            print_lexeme(stdout, yytext, yyleng);
            putchar('\n');
        }
    } else {
        const char *trace = getenv("CPLUS_TRACE");
        yydebug = trace && strcmp(trace, "1") == 0;
        result = yyparse();
    }
    int input_error = ferror(yyin);
    fclose(yyin);
    yylex_destroy();

    if (input_error) {
        fputs("Erro de arquivo: falha durante a leitura.\n", stderr);
        return 3;
    }
    if (lexical_error) return 1;
    if (result != 0) return 2;
    if (!tokens_only) {
        puts("Analise lexica concluida.\n"
             "Analise sintatica concluida.\n"
             "Programa reconhecido com sucesso.");
    }
    return 0;
}
