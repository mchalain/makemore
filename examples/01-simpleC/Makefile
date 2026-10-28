# this include must be present into the first Makefile
# and may be in all others
include ../../scripts.mk

bin-y+=helloworld
helloworld_CFLAGS+=-DMESSAGE=\"world\"

bin-y+=foobar
foobar_SOURCES+=helloworld.c

CLANG?=y
subdir-$(CLANG)+=clang.mk
