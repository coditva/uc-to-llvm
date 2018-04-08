#include <stdio.h>
#include <stdlib.h>
#include "util.h"

/**
 * Print error message and exit with the code
 */
void error(char *message, ErrorCode code)
{
    fprintf(stderr, "Error %d: %s\n", code, message);
    exit(code);
}
