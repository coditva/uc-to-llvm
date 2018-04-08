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
    new -> next = NULL;
    return new -> data;
}

void symbol_init()
{
    symbols_list.start = NULL;
    symbols_list.end = NULL;

    struct Symbol keywords[] = {
        { "while",  WHILE },
        { "break",  BREAK },
        { "do",     DO },
        { "if",     IF },
        { "else",   ELSE },
        { "for",    FOR },
        { "return", RETURN },
        { NULL },
    }, *keyword;
    for (keyword = keywords; keyword; ++keyword) {
        symbol_insert(keyword -> identifier, keyword -> token);
    }
}

void symbol_destroy()
{
    struct SymbolTableNode *node = symbols_list.start, *temp;
    while (node != NULL) {
        temp = node;
        free(temp);
        node = node -> next;
    }
}
