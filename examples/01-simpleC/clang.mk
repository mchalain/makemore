CC=clang

bin-y+=helloworld2
helloworld2_SOURCES+=helloworld.c
helloworld_CFLAGS+=-DMESSAGE=\"clang\"
