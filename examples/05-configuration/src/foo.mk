bin-y+=foo
foo_SOURCES+=foo.c
foo_LIBS+=bar
foo_CFLAGS+=-I$(srcdir)lib
foo_LDFLAGS+=-L$(builddir)lib
