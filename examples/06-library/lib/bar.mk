lib-y+=bar
bar_SOURCES+=bar.c
bar_CFLAGS-y+=-DTYPE=\"target\"
bar_HEADERS+=bar.h

slib-$(STATIC)+=bar

pkgconfig-y+=bar
bar_DESC="simple sample library"
