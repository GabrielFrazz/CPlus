CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -O2
CPPFLAGS = -Isrc -Ibuild
BISONFLAGS = -Wall -Wcounterexamples -Werror --report=all

.PHONY: all test clean
all: cplus

build:
	mkdir -p build

# Regra agrupada: ambos os arquivos são produzidos pela mesma chamada (Make >= 4.3).
build/parser.tab.c build/parser.tab.h &: src/parser.y | build
	$(BISON) $(BISONFLAGS) --defines=build/parser.tab.h -o build/parser.tab.c $<

build/lex.yy.c: src/lexer.l build/parser.tab.h | build
	$(FLEX) -o $@ $<

cplus: build/parser.tab.c build/lex.yy.c src/main.c src/support.h
	$(CC) $(CPPFLAGS) $(CFLAGS) build/parser.tab.c build/lex.yy.c src/main.c $(LDFLAGS) -o $@

test: cplus
	bash tests/run_tests.sh

# Somente artefatos gerados conhecidos; nunca apaga fontes ou documentação.
clean:
	rm -f cplus cplus.exe build/parser.tab.c build/parser.tab.h build/parser.output build/lex.yy.c
