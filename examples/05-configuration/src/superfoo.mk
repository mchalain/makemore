sbin-y+=superfoo
superfoo_SOURCES+=foo.c
superfoo_LIBS+=bar
superfoo_CFLAGS+=-I../lib
superfoo_LDFLAGS+=-L../lib

