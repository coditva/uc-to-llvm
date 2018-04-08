#ifndef DATATYPES_H
#define DATATYPES_H


/**
 * Stucture for an entry in the symbol table
 */
struct Symbol
{
    char *identifier;
	int  token;
	int  localvar;
};


/**
 * Enum of all error codes
 */
typedef enum {
    E_NONE,
    E_INCOMPLETE,
    E_LEX,
} ErrorCode;

#endif /* end of include guard: DATATYPES_H */
