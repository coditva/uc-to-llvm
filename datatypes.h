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
	LLVMValueRef value;
};

#endif /* end of include guard: DATATYPES_H */
