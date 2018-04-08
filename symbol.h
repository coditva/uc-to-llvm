#ifndef SYMBOL_H
#define SYMBOL_H

#include "datatypes.h"

void symbol_init();
void symbol_destroy();
struct Symbol * symbol_lookup(const char *);
struct Symbol * symbol_insert(const char *, int);

#endif /* end of include guard: SYMBOL_H */
