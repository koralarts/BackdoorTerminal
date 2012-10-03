GCC = gcc
FLAGS = -Wall
LUA = -I/usr/include/lua5.1 -llua5.1 -lm

attacker:
	$(GCC) $(FLAGS) -o terminal attacker.c $(LUA)
