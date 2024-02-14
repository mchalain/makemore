package=foo
version=0.1

include ../../scripts.mk

# simple binary installed to <prefix_exec>/bin directory
bin-y+=foo
foo_SOURCES+=foo.c
foo_SOURCES+=barloader.c
foo_LIBS+=bar
foo_LIBS+=dl
foo_CFLAGS-$(DEBUG)+=-g -DDEBUG

# dynamic library installed to <prexic_exec>/lib
lib-y+=bar
bar_SOURCES+=bar.c
bar_CFLAGS+=-DTYPE=\"target\"
bar_CFLAGS-$(DEBUG)+=-g -DDEBUG

# simple binary for super user installed to <prefix_exec>/sbin directory
sbin-y+=superfoo
superfoo_SOURCES+=foo.c
superfoo_SOURCES+=barloader.c
superfoo_LIBS+=bar
superfoo_LIBS+=dl

# static library installed to <prexic_exec>/lib
slib-y+=bar

# dynamic module installed to <prexic_exec>/lib/foo
modules-y+=bar

# simple binary build with HOSTCC instead CC and not installed
# need to call : make hosttools
hostbin-y+=hostfoo
hostfoo_SOURCES+=foo.c
hostfoo_LIBS=hostbar

# static library build with HOSTCC instead CC and not installed
# need to call : make hosttools
hostslib-y+=hostbar
hostbar_SOURCES+=bar.c
hostbar_CFLAGS+=-DTYPE=\"host\"

