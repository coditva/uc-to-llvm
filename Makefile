PROGRAM 		= uc

CC 				= gcc
CC_FLAGS 		= -Wall -Wno-unused-function -Wno-format-overflow -Wpedantic -O -g
CC_LFLAGS		= -lfl `llvm-config --ldflags --system-libs --libs core`
CC_LEX			= lex
CC_YACC 		= yacc
YFLAGS 			= -d

SRCS 			= y.tab.c lex.yy.c symbol.c
OBJS 			= y.tab.o lex.yy.o symbol.o
INCLUDE_DIR		= .

.PHONY: 		all test


all: 			${PROGRAM}

.c.o: 			${SRCS}
				${CC} ${CC_FLAGS} -c $*.c -o $@

y.tab.c: 		parse.y
				${CC_YACC} ${YFLAGS} $<

lex.yy.c: 		lex.l
				${CC_LEX} $<

${PROGRAM}:		${OBJS} Makefile
				${CC} ${C_FLAGS} -I${INCLUDE_DIR} -o $@ ${OBJS} ${CC_LFLAGS}

test: 			all
				./test.sh
				rm -r a.ll a.bc

clean:
				rm -f ${OBJS} *.o ${PROGRAM} y.* lex.yy.* *.ll *.bc
