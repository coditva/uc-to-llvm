PROGRAM 		= uc

CC 				= gcc
CC_FLAGS 		= -Wall -Wno-unused-function -Wno-format-overflow -Wpedantic -g
CC_LFLAGS		= -lfl
CC_LEX			= lex
CC_YACC 		= yacc
YFLAGS 			= -d

SRCS 			= y.tab.c lex.yy.c util.c symbol.c
OBJS 			= y.tab.o lex.yy.o util.o symbol.o
INCLUDE_DIR		= .

.PHONY: 		all test


all: 			${PROGRAM}

.c.o: 			${SRCS}
				${CC} ${CC_FLAGS} -c $*.c -o $@ -O ${CC_LFLAGS}

y.tab.c: 		parse.y
				${CC_YACC} ${YFLAGS} $<

lex.yy.c: 		lex.l
				${CC_LEX} $<

${PROGRAM}:		${OBJS}
				${CC} ${C_FLAGS} -I${INCLUDE_DIR} -o $@ ${OBJS}

test: 			all
				./test.sh

clean:
				rm -f ${OBJS} *.o ${PROGRAM} y.* lex.yy.*
