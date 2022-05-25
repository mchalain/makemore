hostbin-y+=hostfoo
hostfoo_SOURCES+=foo.c
hostfoo_LIBS+=hostbar
hostfoo_LDFLAGS+=-L$(hostbuilddir)lib
