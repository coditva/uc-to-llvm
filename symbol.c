#include <llvm-c/Core.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "datatypes.h"
#include "symbol.h"
#include "y.tab.h"

struct SymbolTableNode {
    struct SymbolTableNode *next;
    struct Symbol *data;
};

struct SymbolTable {
    struct SymbolTableNode *start;
    struct SymbolTableNode *end;
} symbols_list;


struct Symbol * symbol_lookup(const char *identifier)
{
    struct SymbolTableNode *node = symbols_list.start;
    while (node != NULL) {
        if (strcmp(node -> data -> identifier, identifier) == 0) {
            return node -> data;
        }
        node = node -> next;
    }
    return NULL;
}

struct Symbol * symbol_insert(const char *identifier, int token)
{
    struct SymbolTableNode *new = (struct SymbolTableNode *)
        malloc(sizeof(struct SymbolTableNode));
    new -> data = (struct Symbol *) malloc(sizeof(struct Symbol));
    new -> data -> identifier = strdup(identifier);
    new -> data -> token = token;
    new -> data -> value = NULL;
    new -> next = NULL;

    if (symbols_list.start == NULL) {
        symbols_list.start = new;
        symbols_list.end = new;
    } else {
        symbols_list.end -> next = new;
        symbols_list.end = new;
    }
    return new -> data;
}

void symbol_init()
{
    symbols_list.start = NULL;
    symbols_list.end = NULL;

    struct Symbol keywords[] = {
        { "while",  WHILE,  0 },
        { "break",  BREAK,  0 },
        { "do",     DO,     0 },
        { "if",     IF,     0 },
        { "else",   ELSE,   0 },
        { "for",    FOR,    0 },
        { "return", RETURN, 0 },
        { NULL },
    };
    int size = sizeof(keywords)/sizeof(struct Symbol);
    for (int i = 0; i < size - 1; i++) {
        symbol_insert(keywords[i].identifier, keywords[i].token);
    }
}

void symbol_destroy()
{
    struct SymbolTableNode *node = symbols_list.start, *temp;
    while (node != NULL) {
        temp = node;
        node = node -> next;
        free(temp -> data -> identifier);
        free(temp -> data);
        free(temp);
    }
}
