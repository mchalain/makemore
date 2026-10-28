# if this file is not the first Makefile
# change the srcdir directory
srcdir:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))/

package=foo
version=0.2

include ../../scripts.mk

pkgconfig-y+=$(package)
subdir-y+=lib
subdir-y+=src
sysconf-y+=foo.conf

