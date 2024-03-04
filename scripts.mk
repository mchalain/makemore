MAKEFLAGS+=--no-print-directory
ifeq ($(inside_makemore),)
makemore?=$(realpath $(word 2,$(MAKEFILE_LIST)))
export makemore
file?=$(notdir $(firstword $(MAKEFILE_LIST)))
inside_makemore:=yes

package:=$(package:"%"=%)
version:=$(version:"%"=%)
version_m=$(firstword $(subst ., ,$(version)))
export package
export version

##
# debug tools
##
V=0
ifeq ($(V),1)
quiet=
Q=
else
quiet=quiet_
Q=@
endif
echo-cmd = $(if $($(quiet)cmd_$(1)), echo '  $($(quiet)cmd_$(1))';)
cmd = $(if $(quiet),$(echo-cmd)) $(cmd_$(1))
qcmd = $(cmd_$(1))

define newline

endef

##
# file extention definition
bin-ext=
slib-ext=a
dlib-ext=so
makefile-ext=mk

##
# make file with targets definition
##
bin-y:=
sbin-y:=
lib-y:=
slib-y:=
modules-y:=
include-y:=
data-y:=
doc-y:=
hostbin-y:=

srcdir?=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
export srcdir

#ifneq ($(findstring -arch,$(CFLAGS)),)
#ARCH=$(shell echo $(CFLAGS) 2>&1 | $(AWK) 'BEGIN {FS="[- ]"} {print $$2}')
#buildpath=$(join $(srcdir),$(ARCH))
#endif
ifneq ($(BUILDDIR),)
  buildpath:=$(if $(findstring ./,$(dir $(BUILDDIR:%/=%))),$(PWD)/)$(BUILDDIR:%/=%)/
  builddir:=$(buildpath)
else
  builddir:=$(srcdir)
endif
ifneq ($(CROSS_COMPILE),)
  buildpath:=$(builddir)$(CROSS_COMPILE:%-=%)/
endif

# internal configuration to install HEADERS file or not
DEVINSTALL?=y
# CONFIG could define LD CC or/and CFLAGS
# CONFIG must be included before "Commands for build and link"
# all config paths must be fix otherwise their generation
# is required yet during cleaning
DEFCONFIG?=$(srcdir)defconfig
VERSIONFILE:=$(builddir)version.h
CONFIGFILE:=$(builddir)config.h
CONFIG:=$(builddir).config
PATHCACHE:=$(builddir).pathcache

ifneq ($(wildcard $(CONFIG)),)
  include $(CONFIG)
# define all unset variable as variable defined as n
  $(foreach config,$(shell cat $(CONFIG) | awk '/^. .* is not set/{print $$2}'),$(eval $(config)=n))
endif
ifneq ($(wildcard $(PATHCACHE)),)
  include $(PATHCACHE)
endif

ifneq ($(buildpath),)
  objdir:=$(buildpath)$(cwdir)
else
  objdir:=
endif
hostbuilddir:=$(builddir)host/
hostobjdir:=$(hostbuilddir)$(cwdir)

ifneq ($(file),)
  include $(file)
endif

PATH:=$(value PATH):$(hostobjdir)
TMPDIR:=/tmp
TESTFILE:=makemore_test
##
# default Macros for installation
##
# not set variable if not into the build step
AWK?=awk
GREP?=grep
RM?=rm -f
MKDIR?=mkdir -p
LN?=ln -f -s
INSTALL?=install
INSTALL_PROGRAM?=$(INSTALL) -D
INSTALL_DATA?=$(INSTALL) -m 644 -D
PKGCONFIG?=pkg-config
LESS?=lex
YACC?=yacc
MOC?=moc$(QT:%=-%)
UIC?=uic$(QT:%=-%)

TOOLCHAIN?=
CROSS_COMPILE?=

ifeq ($(CC),cc)
  CC:=$(realpath $(shell which $(CC)))
endif

HOSTCC=gcc
HOSTCXX=g++
# if gcc, prefer to use directly gcc for ld
HOSTLD=gcc
HOSTAR=ar
HOSTRANLIB=ranlib
HOSTCFLAGS=
HOSTLDFLAGS=
HOSTSTRIP=strip
HOST_COMPILE:=$(shell LANG=C $(HOSTCC) -dumpmachine | $(AWK) -F- '{print $$1}')
HOSTCCVERSION:=$(shell $(HOSTCC) -\#\#\#  2>&1 | $(GREP) -i " version ")

ifneq ($(CROSS_COMPILE),)
  CC=$(CROSS_COMPILE)gcc
endif
ifneq ($(CC),)
  CCVERSION:=$(shell $(CC) -\#\#\#  2>&1 | $(GREP) -i " version ")
  ARCH:=$(shell LANG=C $(CC) -dumpmachine | $(AWK) -F- '{print $$1}')
endif

ifeq ($(HOST_COMPILE),$(ARCH))
  CC?=$(HOSTCC)
  CFLAGS?=
  CXX?=$(HOSTCXX)
  CXXFLAGS?=
  LD?=$(HOSTLD)
  LDFLAGS?=
  AR?=$(HOSTAR)
  RANLIB?=$(HOSTRANLIB)
  STRIP?=$(HOSTSTRIP)
else
  TOOLCHAIN?=$(dir $(dir $(realpath $(shell which $(CC)))))
endif

ifneq ($(TOOLCHAIN),)
  export PATH:=$(TOOLCHAIN):$(TOOLCHAIN)/bin:$(PATH)
endif

ifneq ($(dir $(CC)),./)
  TARGETPREFIX=
else
  ifneq ($(CROSS_COMPILE),)
    ifeq ($(findstring $(CROSS_COMPILE),$(CC)),)
      TARGETPREFIX=$(CROSS_COMPILE:%-=%)-
    endif
  else
    TARGETPREFIX=
  endif
endif
TARGETCC:=$(TARGETPREFIX)$(CC)
TARGETLD:=$(TARGETPREFIX)$(LD)
TARGETAS:=$(TARGETPREFIX)$(AS)
TARGETCXX:=$(TARGETPREFIX)$(CXX)
TARGETAR:=$(TARGETPREFIX)$(AR)
TARGETRANLIB:=$(TARGETPREFIX)$(RANLIB)
TARGETSTRIP:=$(TARGETPREFIX)$(STRIP)

ifeq ($(findstring gcc,$(TARGETCC)),gcc)
  SYSROOT?=$(shell $(TARGETCC) -print-sysroot)
endif

ifeq ($(destdir),)
  destdir:=$(abspath $(DESTDIR))
  export destdir
endif

ifneq ($(CROSS_COMPILE),)
  destdir?=$(sysroot)
endif

ifneq ($(SYSROOT),)
  sysroot:=$(patsubst "%",%,$(SYSROOT:%/=%))
endif

ifneq ($(sysroot),)
  SYSROOT_CFLAGS+=--sysroot=$(sysroot)
  SYSROOT_CFLAGS+=-isysroot $(sysroot)
  SYSROOT_LDFLAGS+=--sysroot=$(sysroot)
  ifneq ($(strip $(includedir)),)
    SYSROOT_CFLAGS+=-I$(sysroot)$(strip $(includedir))
  endif
  ifneq ($(strip $(libdir)),)
    RPATHFLAGS+=-Wl,-rpath,$(strip $(libdir))
    SYSROOT_LDFLAGS+=-L$(sysroot)$(strip $(libdir))
  endif
  ifneq ($(strip $(pkglibdir)),)
    RPATHFLAGS+=-Wl,-rpath,$(strip $(pkglibdir))
    SYSROOT_LDFLAGS+=-L$(sysroot)$(strip $(pkglibdir))
  endif
  PKG_CONFIG_PATH=""
  PKG_CONFIG_SYSROOT_DIR=$(sysroot)
  export PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_DIR
endif

ifneq ($(destdir),)
  SYSROOT_CFLAGS+=-I$(destdir)$(strip $(includedir))
  SYSROOT_LDFLAGS+=-L$(destdir)$(strip $(libdir))
  SYSROOT_LDFLAGS+=-L$(destdir)$(strip $(pkglibdir))
endif

ARCH?=$(shell LANG=C $(TARGETCC) -dumpmachine | awk -F- '{print $$1}')
ifeq ($(libdir),)
  SYSTEM?=$(shell $(TARGETCC) -dumpmachine)
  LONG_BIT?=$(shell LANG=C getconf LONG_BIT)
  ifneq ($(wildcard $(sysroot)/lib/$(SYSTEM)),)
    libsuffix?=/$(SYSTEM)
   else
     ifneq ($(wildcard $(sysroot)/lib$(LONG_BIT)),)
       libsuffix?=$(LONG_BIT)
    endif
  endif
endif

O?=2
ifneq ($(PREFIX),)
  prefix:=$(PREFIX)
endif
prefix?=/usr/local
prefix:=$(patsubst "%",%,$(prefix:%/=%))
exec_prefix?=$(prefix)
program_prefix?=
library_prefix?=lib
bindir?=$(exec_prefix)/bin
sbindir?=$(exec_prefix)/sbin
libexecdir?=$(exec_prefix)/libexec/$(package)
datarootdir?=$(prefix)/share/
datadir?=$(datarootdir)/$(package)
libdir?=$(strip $(exec_prefix)/lib$(libsuffix))
sysconfdir?=$(prefix)/etc
includedir?=$(prefix)/include
pkgdatadir?=$(datadir)
pkglibdir?=$(libdir)/$(package)
localstatedir?=$(prefix)/var
docdir?=$(datarootdir)/doc/$(package)
infodir?=$(datarootdir)/info
localedir?=$(datarootdir)/locale
mandir?=$(datarootdir)/man
PATHES=prefix exec_prefix library_prefix bindir sbindir libexecdir libdir sysconfdir includedir datadir pkgdatadir pkglibdir localstatedir docdir builddir
ifneq ($(TOOLCHAIN),)
  PATHES+=TOOLCHAIN
endif
ifneq ($(SYSROOT),)
  PATHES+=SYSROOT
endif
ifneq ($(CROSS_COMPILE),)
  PATHES+=CROSS_COMPILE
endif
export $(PATHES)

INTERN_CFLAGS=-I.
INTERN_CXXFLAGS=-I.
ifneq ($(srcdir),)
INTERN_CFLAGS+=-I$(srcdir)
INTERN_CXXFLAGS+=-I$(srcdir)
endif
ifneq ($(objdir),)
INTERN_CFLAGS+=-I$(objdir)
INTERN_CXXFLAGS+=-I$(objdir)
endif
ifneq ($(wildcard $(VERSIONFILE)),)
INTERN_CFLAGS+=-include $(VERSIONFILE)
endif
ifneq ($(wildcard $(CONFIGFILE)),)
INTERN_CFLAGS+=-include $(CONFIGFILE)
endif
INTERN_LIBS=c

# Update LDFLAGS for each directory containing at least one library.
# The LDFLAGS must be available for all binaries of the project.
ifneq ($(lib-t) $(slib-y),)
INTERN_LDFLAGS+=-L.
ifneq ($(objdir),)
INTERN_LDFLAGS+=-L$(objdir)
endif
INTERN_LDFLAGS:=$(sort $(INTERN_LDFLAGS))
export INTERN_LDFLAGS
endif

ifneq ($(hostslib-y),)
ifneq ($(hostobjdir),)
HOSTLDFLAGS+=-L$(hostobjdir)
HOSTLDFLAGS:=$(sort $(HOSTLDFLAGS))
export HOSTLDFLAGS
endif
endif

CFLAGS+=-O$(O)

##
# objects recipes generation
##
define notass
$(patsubst %.s,%,$(patsubst %.S,%,$1))
endef
define notc
$(patsubst %.c,%,$(patsubst %.cpp,%,$(patsubst %.c++,%,$(patsubst %.cc,%,$1))))
endef
define notext
$(call notass,$(call notc,$1))
endef

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$($(t)_GENERATED-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_SOURCES+=$($(t)_SOURCES-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(if $($(t)_SOURCES),,$(if $(wildcard $(src)$(t).c),$(eval $(t)_SOURCES+=$(t).c))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(if $($(t)_SOURCES),,$(if $(wildcard $(src)$(t).cpp),$(eval $(t)_SOURCES+=$(t).cpp))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(if $(findstring .cpp, $(notdir $($(t)_SOURCES))), $(eval $(t)_LIBS+=stdc++)))

## lex sources substituded to lexer.c files for targets
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.l,%.lexer.c,$(filter %.l,$($(t)_SOURCES)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_SOURCES:=$(filter-out %.l,$($(t)_SOURCES))))

## yacc sources substituded to tab.c files for targets
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.y,%.tab.c,$(filter %.y,$($(t)_SOURCES)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_SOURCES:=$(filter-out %.y,$($(t)_SOURCES))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)-objs+=$(addsuffix .o,$(call notext,$($(t)_GENERATED)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)-objs+=$(addsuffix .o,$(call notext,$($(t)_SOURCES)))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(if $($(t)-objs),,$(eval $(t)-objs+=$(t))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_CFLAGS:=$($(t)_CFLAGS) $($(t)_CFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_CXXFLAGS:=$($(t)_CXXFLAGS) $($(t)_CXXFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LDFLAGS:=$($(t)_LDFLAGS) $($(t)_LDFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LIBS:=$($(t)_LIBS) $($(t)_LIBS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LIBRARY:=$($(t)_LIBRARY) $($(t)_LIBRARY-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_MOCFLAGS:=$($(t)_MOCFLAGS) $($(t)_MOCFLAGS-y)))

$(foreach t,$(slib-y) $(lib-y),$(eval include-y+=$($(t)_HEADERS)))

define cmd_pkgconfig
	$(shell PKG_CONFIG_PATH=$(sysroot)/usr/lib/pkg-config:$(builddir) $(PKGCONFIG) --silence-errors $(2) $(1))
endef
# LIBRARY may contain libraries name to check
# The name may terminate with {<version>} informations like LIBRARY+=usb{1.0}
# The LIBRARY values use pkg-config to update CFLAGS, LDFLAGS and LIBS
# After LIBS contains all libraries name to link
$(foreach l,$(LIBRARY),$(eval CFLAGS+=$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst }, ,$(l)))), --cflags) ) )
$(foreach l,$(LIBRARY),$(eval LDFLAGS+=$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst }, ,$(l)))), --libs-only-L) ) )
$(foreach l,$(LIBRARY),$(eval LIBS+=$(subst -l,,$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst }, ,$(l)))), --libs-only-l)) ) )
$(eval LIBS:=$(sort $(LIBS)))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_CFLAGS+=$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst }, ,$(l)))),--cflags))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_LDFLAGS+=$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst }, ,$(l)))),--libs-only-L))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_LIBS+=$(subst -l,,$(call cmd_pkgconfig,$(firstword $(subst {, ,$(subst },,$(l)))),--libs-only-l)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(eval $(t)_LIBS:=$(sort $($(t)_LIBS))))

# set the CFLAGS of each source file
# if the source file name and binary name are exactly the same, a loop occures and the CFLAGS grows
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $(call notext,$($(t)_SOURCES)),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CFLAGS+=$($(t)_CFLAGS)))))
#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CFLAGS+=$($(t)_CFLAGS)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $(call notext,$($(t)_GENERATED)),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CFLAGS+=$($(t)_CFLAGS)))))
#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_GENERATED),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CFLAGS+=$($(t)_CFLAGS)))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $(call notext,$($(t)_SOURCES)),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CXXFLAGS+=$($(t)_CXXFLAGS)))))
#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CXXFLAGS+=$($(t)_CXXFLAGS)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $(call notext,$($(t)_GENERATED)),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CXXFLAGS+=$($(t)_CXXFLAGS)))))
#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, ($(t)_GENERATED),$(if $(findstring @$(s)@,@$(t)@),,$(eval $(s)_CXXFLAGS+=$($(t)_CXXFLAGS)))))

$(foreach t,$(lib-y),$(eval $(t)_LDFLAGS+=-Wl,-soname,lib$(t).so$(version_m:%=.%)))
$(foreach t,$(lib-y),$(eval $(t)_LDFLAGS+=-Wl,-soname,lib$(t).so))
#$(foreach t,$(modules-y),$(eval $(t)_LDFLAGS+=-Wl,-soname,$(t).so$(version_m:%=.%)))

# The Dynamic_Loader library (libdl) allows to load external libraries.
# If this libraries has to link to the binary functions,
# this binary has to export the symbol with -rdynamic flag
$(foreach t,$(bin-y) $(sbin-y),$(if $(findstring dl, $($(t)_LIBS) $(LIBS)),$(eval $(t)_LDFLAGS+=-rdynamic)))

##
# subdir generation
##

#create subproject
$(foreach t,$(subdir-y),$(eval $(t)_CONFIGURE+=$($(t)_CONFIGURE-y)))
$(foreach t,$(subdir-y),$(if $($(t)_CONFIGURE), $(eval subdir-project+=$(t))))
subdir-y:=$(filter-out $(subdir-project),$(subdir-y))

#append Makefile to each directory and only directory subdir
subdir-target:=$(foreach sdir,$(subdir-y),$(if $(filter-out %$(makefile-ext:%=.%), $(filter-out %Makefile, $(sdir))),$(wildcard $(addsuffix /Makefile,$(sdir:%/.=%))),$(wildcard $(sdir))))

##
# targets recipes generation
##

objs-target:=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(addprefix $(objdir),$($(t)_GENERATED)))
objs-target+=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(addprefix $(objdir),    $($(t)-objs)))
objs-target+=$(foreach t, $(sysconf-y) $(data-y),$(addprefix $(objdir),$($(t)_GENERATED)))
hostobjs-target:=$(foreach t, $(hostbin-y) $(hostslib-y),                    $(addprefix $(hostobjdir),$($(t)_GENERATED))	$(addprefix $(hostobjdir),$($(t)-objs)))

lib-check-target:=$(sort $(LIBRARY:%=check_%) $(sort $(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_LIBRARY:%=check_%))))

ifeq (STATIC,y)
lib-static-target:=$(addprefix $(objdir),$(addsuffix $(slib-ext:%=.%),$(addprefix $(library_prefix),$(slib-y) $(lib-y))))
else
lib-static-target:=$(addprefix $(objdir),$(addsuffix $(slib-ext:%=.%),$(addprefix $(library_prefix),$(slib-y))))
lib-dynamic-target:=$(addprefix $(objdir),$(addsuffix $(dlib-ext:%=.%),$(addprefix $(library_prefix),$(lib-y))))
endif
modules-target:=$(addprefix $(objdir),$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
bin-target:=$(addprefix $(objdir),$(addprefix $(program_prefix),$(addsuffix $(bin-ext:%=.%),$(bin-y) $(sbin-y))))
hostslib-target:=$(addprefix $(hostobjdir),$(addsuffix $(slib-ext:%=.%),$(addprefix lib,$(hostslib-y))))
hostbin-target:=$(addprefix $(hostobjdir),$(addsuffix $(bin-ext:%=.%),$(hostbin-y)))

data-target:=$(sort $(data-y))

pkgconfig-target:=$(foreach pkgconfig,$(sort $(pkgconfig-y)),$(addprefix $(builddir),$(addsuffix .pc,$(pkgconfig))))
$(foreach l,$(pkgconfig-y),$(eval $(l)_LIBS+=$(l:lib%=%)))
$(foreach l,$(pkgconfig-y),$(eval $(l)_LIBS+=$($(l)_LIBS-y)))
$(foreach l,$(lib-y) $(slib-y), $(foreach pc, $($(l)_PKGCONFIG), $(eval $(pc)_LIBS+=$(l))))

clean-target:=

targets+=$(lib-dynamic-target)
targets+=$(modules-target)
targets+=$(lib-static-target)
targets+=$(bin-target)
targets+=$(pkgconfig-target)

hook-target:=$(hook-$(action:_%=%)) $(hook-$(action:_%=%)-y)

###############################################################################
# scripts extensions
##
ifneq ($(wildcard $(dir $(makemore))scripts/download.mk),)
  include $(dir $(makemore))scripts/download.mk
endif

ifneq ($(wildcard $(dir $(makemore))scripts/gcov.mk),)
  include $(dir $(makemore))scripts/gcov.mk
endif

ifneq ($(wildcard $(dir $(makemore))scripts/qt.mk),)
  include $(dir $(makemore))scripts/qt.mk
endif

##
# install recipes generation
##
ifneq ($(CROSS_COMPILE),)
  destdir?=$(sysroot)
endif

sysconf-install:=$(addprefix $(destdir)$(sysconfdir:%/=%)/,$(sysconf-y))
data-install:=$(addprefix $(destdir)$(datadir:%/=%)/,$(data-target))
doc-install:=$(addprefix $(destdir)$(docdir:%/=%)/,$(doc-y))
include-install:=$(addprefix $(destdir)$(includedir:%/=%)/,$(include-y))
lib-static-install:=$(addprefix $(destdir)$(libdir:%/=%)/,$(addsuffix $(slib-ext:%=.%),$(addprefix lib,$(slib-y))))
lib-dynamic-install:=$(addprefix $(destdir)$(libdir:%/=%)/,$(addsuffix $(version:%=.%),$(addsuffix $(dlib-ext:%=.%),$(addprefix lib,$(lib-y)))))
modules-install:=$(addprefix $(destdir)$(pkglibdir:%/=%)/,$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
pkgconfig-install:=$(addprefix $(destdir)$(libdir:%/=%)/pkgconfig/,$(addsuffix .pc,$(sort $(pkgconfig-y))))

$(foreach t,$(bin-y),$(if $(findstring libexec,$($(t)_INSTALL)),$(eval libexec-y+=$(t))))
$(foreach t,$(bin-y),$(if $(findstring sbin,$($(t)_INSTALL)),$(eval sbin-y+=$(t))))
bin-install:=$(addprefix $(destdir)$(bindir:%/=%)/,$(addprefix $(program_prefix),$(addsuffix $(bin-ext:%=.%),$(filter-out $(libexec-y) $(sbin-y),$(bin-y)))))
sbin-install:=$(addprefix $(destdir)$(sbindir:%/=%)/,$(addprefix $(program_prefix),$(addsuffix $(bin-ext:%=.%),$(sbin-y))))
libexec-install:=$(addprefix $(destdir)$(libexecdir:%/=%)/,$(addprefix $(program_prefix),$(addsuffix $(bin-ext:%=.%),$(libexec-y))))

install:=
dev-install-y:=
dev-install-$(DEVINSTALL)+=$(lib-static-install)
install+=$(lib-dynamic-install)
install+=$(lib-link-install)
install+=$(modules-install)
install+=$(data-install)
install+=$(sysconf-install)
dev-install-$(DEVINSTALL)+=$(include-install)
install+=$(bin-install)
install+=$(sbin-install)
install+=$(libexec-install)
dev-install-$(DEVINSTALL)+=$(pkgconfig-install)

###############################################################################
# main entries
##
action:=_build
build:=$(action) -f $(makemore) file
.DEFAULT_GOAL:=build
.PHONY: _build _install _clean _distclean _check _hostbuild
.PHONY: build install clean distclean check hosttools
build: $(builddir) default_action

_info:
	@:

_hostbuild: action:=_hostbuild
_hostbuild: build:=$(action) -f $(makemore) file
_hostbuild: _info $(subdir-target) $(hostobjdir) $(hostslib-target) $(hostbin-target) _hook
	@:

_build: _info $(download-target) $(gitclone-target) $(objdir) $(subdir-project) $(subdir-target) $(doc-y) $(targets) _hook
	@:

_install: action:=_install
_install: build:=$(action) -f $(makemore) file
_install: _info $(install) $(dev-install-y) $(subdir-target) _hook
	@:

_clean: action:=_clean
_clean: build:=$(action) -f $(makemore) file
_clean: _info $(subdir-target) _clean_objs _clean_targets _clean_objdirs _hook
	@:

_clean_targets:
	@$(call cmd,clean,$(wildcard $(clean-target)))
	@$(call cmd,clean,$(wildcard $(targets)))
	@$(call cmd,clean,$(wildcard $(hostslib-target)))
	@$(call cmd,clean,$(wildcard $(hostbin-target)))

_clean_objs:
	@$(call cmd,clean,$(wildcard $(objs-target)))
	@$(call cmd,clean,$(wildcard $(hostobjs-target)))

_clean_objdirs:
	@$(if $(target-objs),$(call cmd,clean_dir,$(realpath $(filter-out $(srcdir)$(cwdir),$(objdir)))))
	@$(if $(target-hostobjs),$(call cmd,clean_dir,$(wildcard $(realpath $(hostobjdir)))))

_check: action:=_check
_check: build:=$(action) -s -f $(makemore) file
_check: $(subdir-target) $(lib-check-target)

_hook:
	$(Q)$(foreach target,$(hook-$(action:_%=%)-y),$(MAKE) -f $(file) $(target);)

.PHONY:clean distclean install check default_action pc all
clean: action:=_clean
clean: build:=$(action) -f $(makemore) file
clean: default_action ;

distclean: action:=_clean
distclean: build:=$(action) -f $(makemore) file
distclean: cleanconfig default_action
	@$(call cmd,clean,$(CONFIG))
	@$(call cmd,clean_dir,$(wildcard $(builddir)host))
	@$(call cmd,clean_dir,$(filter-out $(srcdir),$(builddir)))
	@$(call cmd,clean_dir,$(wildcard $(gitclone-target)))
	@$(call cmd,clean,$(wildcard $(download-target)))
	@$(call cmd,clean,$(wildcard $(builddir).*.pc.in))

install:: action:=_install
install:: build:=$(action) -f $(makemore) file
install:: default_action ;

check: action:=_check
check: build:=$(action) -s -f $(makemore) file
check: $(.DEFAULT_GOAL) ;

hosttools: action:=_hostbuild
hosttools: build:=$(action) -f $(makemore) file
hosttools: $(hostbuilddir) default_action ;

default_action: _info
	$(Q)$(MAKE) $(build)=$(file)
	@:

all: default_action ;

version?=0.1
subversion?=$(word 3,$(subst ., ,$(version)))
ifeq ($(subversion),)
subversion=0
else
version:=$(patsubst %.$(subversion),%, $(version))
endif

version:
	@echo $(package) $(version).$(subversion)

###############################################################################
# Commands for clean
##
quiet_cmd_clean=$(if $(2),CLEAN $(notdir $(2)))
 cmd_clean=$(if $(2),$(RM) $(2))
quiet_cmd_clean_dir=$(if $(2),CLEAN $(notdir $(2)))
 cmd_clean_dir=$(if $(2),$(RM) -d $(2))

###############################################################################
# Commands for build
##
RPATH=$(wildcard $(addsuffix /.,$(wildcard $(CURDIR:%/=%)/* $(objdir)*)))
quiet_cmd_lex_l=LEX $*
 cmd_lex_l=$(LEX) -Cf -o $@ $<
quiet_cmd_yacc_y=YACC $*
 cmd_yacc_y=$(YACC) $($*_YACCFLAGS) -o $@ $<
quiet_cmd_as_o_s=AS $*
 cmd_as_o_s=$(TARGETAS) $(ASFLAGS) $(INTERN_CFLAGS) $(SYSROOT_CFLAGS) $($*_CFLAGS) -c -o $@ $<
quiet_cmd_cc_o_c=CC $*
 cmd_cc_o_c=$(TARGETCC) $(CFLAGS) $(INTERN_CFLAGS) $(SYSROOT_CFLAGS) $($*_CFLAGS) -c -o $@ $<
quiet_cmd_cc_o_cpp=CXX $*
 cmd_cc_o_cpp=$(TARGETCXX) $(CXXFLAGS) $(CFLAGS) $(INTERN_CFLAGS) $(SYSROOT_CFLAGS) $($*_CXXFLAGS) $($*_CFLAGS) -c -o $@ $<
quiet_cmd_ld_bin=LD $*
 cmd_ld_bin=$(TARGETCC) $(LDFLAGS) $(INTERN_LDFLAGS) $(SYSROOT_LDFLAGS) $($*_LDFLAGS) $(RPATHFLAGS) -o $@ $(filter %.o,$(filter-out $(file),$^)) -Wl,--start-group $(LIBS:%=-l%) $($*_LIBS:%=-l%) -Wl,--end-group $(INTERN_LIBS:%=-l%)
quiet_cmd_ld_slib=LD $*
 cmd_ld_slib=$(RM) $@ && \
	$(TARGETAR) -cvq $@ $^ > /dev/null && \
	$(TARGETRANLIB) $@
quiet_cmd_ld_dlib=LD $*
 cmd_ld_dlib=$(TARGETCC) $(LDFLAGS) $(INTERN_LDFLAGS) $(SYSROOT_LDFLAGS) $($*_LDFLAGS) $(RPATHFLAGS) -Bdynamic -shared -o $@ $(filter %.o,$(filter-out $(file),$^)) $(LIBS:%=-l%) $($*_LIBS:%=-l%) $(INTERN_LIBS:%=-l%)

quiet_cmd_hostcc_o_c=HOSTCC $*
 cmd_hostcc_o_c=$(HOSTCC) $(HOSTCFLAGS) $(INTERN_CFLAGS) $($*_CFLAGS) -c -o $@ $<
quiet_hostcmd_cc_o_cpp=HOSTCXX $*
 cmd_hostcc_o_cpp=$(HOSTCXX) $(HOSTCXXFLAGS) $(HOSTCFLAGS) $(INTERN_CFLAGS) $($*_CFLAGS) -c -o $@ $<
quiet_cmd_hostld_bin=HOSTLD $*
 cmd_hostld_bin=$(HOSTCC) $(HOSTLDFLAGS) $(INTERN_LDFLAGS) $($*_LDFLAGS) -o $@ $(filter %.o,$(filter-out $(file),$^)) $(LIBS:%=-l%) $($*_LIBS:%=-l%) $(INTERN_LIBS:%=-l%)
quiet_cmd_hostld_slib=HOSTLD $*
 cmd_hostld_slib=$(RM) $@ && \
	$(HOSTAR) -cvq $@ $(filter %.o,$(filter-out $(file),$^)) > /dev/null && \
	$(HOSTRANLIB) $@

###############################################################################
# Commands for directories and links
##
quiet_cmd_mkdir=DIR $*
 cmd_mkdir=$(MKDIR) $2
quiet_cmd_link=LINK $*
 cmd_link=$(LN) $2 $3
##
# build rules
##
.SECONDEXPANSION:
$(sort $(hostobjdir) $(objdir) $(builddir) $(buildpath)): $(builddir)%: $(file)
	@$(call cmd,mkdir,$@)

$(objdir)%.lexer.c $(hostobjdir)%.lexer.c:%.l $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,lex_l)

$(objdir)%.tab.c $(hostobjdir)%.tab.c:%.y $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,yacc_y)

$(objdir)%.o:$(objdir)%.s $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,as_o_s)

$(objdir)%.o:%.s $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,as_o_s)

$(objdir)%.o:$(objdir)%.c $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,cc_o_c)

$(objdir)%.o:%.c $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,cc_o_c)

$(objdir)%.o:$(objdir)%.cpp $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,cc_o_cpp)

$(objdir)%.o:%.cpp $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,cc_o_cpp)

$(hostobjdir)%.o:$(hostobjdir)%.c $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,hostcc_o_c)

$(hostobjdir)%.o:%.c $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,hostcc_o_c)

$(hostobjdir)%.o:$(hostobjdir)%.cpp $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,hostcc_o_cpp)

$(hostobjdir)%.o:%.cpp $(file)
	@$(call qcmd,mkdir,$(dir $@))
	@$(call cmd,hostcc_o_cpp)

$(lib-static-target): $(objdir)lib%$(slib-ext:%=.%): $$(addprefix $(objdir),$$(%-objs)) $(file)
	@$(call cmd,ld_slib)

$(lib-dynamic-target): CFLAGS+=-fPIC
$(lib-dynamic-target): $(objdir)lib%$(dlib-ext:%=.%): $$(addprefix $(objdir),$$(%-objs)) $(file)
	@$(call cmd,ld_dlib)

$(modules-target): CFLAGS+=-fPIC
$(modules-target): $(objdir)%$(dlib-ext:%=.%): $$(addprefix $(objdir),$$(%-objs)) $(file)
	@$(call cmd,ld_dlib)

$(bin-target): $(objdir)%$(bin-ext:%=.%): $$(addprefix $(objdir),$$(%-objs)) $(file)
	@$(call cmd,ld_bin)

$(hostbin-target): $(hostobjdir)%$(bin-ext:%=.%): $$(addprefix $(hostobjdir),$$(%-objs)) $(file)
	@$(call cmd,hostld_bin)

$(hostslib-target): $(hostobjdir)lib%$(slib-ext:%=.%): $$(addprefix $(hostobjdir),$$(%-objs)) $(file)
	@$(call cmd,hostld_slib)

# this line is for <target>_GENERATED variable
%: ;

###############################################################################
# subdir evaluation
#
quiet_cmd_subdir=SUBDIR $*
define cmd_subdir
	$(MAKE) -C $(dir $*) cwdir=$(cwdir)$(filter-out ./,$(dir $*)) builddir=$(builddir) $(build)=$(notdir $*)
endef

quiet_cmd_subdir-project=PROJECT $*
define cmd_subdir-project
	$(if $($(*)_CONFIGURE),cd $* && $($(*)_CONFIGURE) &&) \
	$(MAKE) -C $* && \
	$(MAKE) -C $* DESTDIR=$(destdir) install
endef

.PHONY: $(subdir-project) $(subdir-target) FORCE
$(subdir-project): %: FORCE
	@$(call cmd,subdir-project)

$(subdir-target): %: FORCE
	@$(call cmd,subdir)

###############################################################################
# Libraries dependencies checking
#
quiet_cmd_check_lib=CHECK $*
define cmd_check_lib
	$(eval CHECKLIB=$(firstword $(subst {, ,$(subst },,$2))))
	$(eval CHECKVERSION=$(if $(findstring {, $(2)),$(subst -, - ,$(lastword $(subst {, ,$(subst },,$2))))))
	$(eval CHECKOPTIONS=$(if $(CHECKVERSION),$(if $(findstring -,$(firstword $(CHECKVERSION))),--max-version=$(word 2,$(CHECKVERSION)))))
	$(eval CHECKOPTIONS+=$(if $(CHECKVERSION),$(if $(findstring -,$(lastword $(CHECKVERSION))),--atleast-version=$(word 1,$(CHECKVERSION)))))
	$(eval CHECKOPTIONS+=$(if $(CHECKVERSION),$(if $(findstring -,$(CHECKVERSION)),,--exact-version=$(CHECKVERSION))))
	$(Q)PKG_CONFIG_PATH=$(sysroot)/usr/lib/pkg-config $(PKGCONFIG) --exists --print-errors $(CHECKOPTIONS) $(CHECKLIB);
	$(eval CHECKCFLAGS:=$(call cmd_pkgconfig,$(CHECKLIB),--cflags))
	$(eval CHECKLDFLAGS:=$(call cmd_pkgconfig,$(CHECKLIB),--libs))
	$(Q)$(TARGETCC) -c -o $(<:%.c=%.o) $< $(INTERN_CFLAGS) $(CHECKCFLAGS);
	$(Q)$(TARGETCC) -o $(TMPDIR)/$(TESTFILE) $(<:%.c=%.o) $(INTERN_LDFLAGS) $(CHECKLDFLAGS) > /dev/null 2>&1
endef

$(TMPDIR)/$(TESTFILE:%=%.c):
	$(Q)echo "int main(){return 0;}" > $@

$(lib-check-target): check_%: $(TMPDIR)/$(TESTFILE:%=%.c) FORCE
	$(Q)$(call cmd,check_lib,$*)
	$(Q)echo "HAVE_$(firstword $(subst {, ,$(subst },,$*)))=y" | tr '[:lower:]' '[:upper:]' | sed 's/[.-]/_/g' >>  $(CONFIG)

###############################################################################
# Commands for install
##
quiet_cmd_install_dir=INSTALL $*
define cmd_install_dir
	find $< -type f -exec $(INSTALL_DATA) "{}" "$(@D)/{}" \;
endef
quiet_cmd_install_data=INSTALL $*
define cmd_install_data
	$(INSTALL_DATA) $< $@
endef
quiet_cmd_install_bin=INSTALL $*
define cmd_install_bin
	$(INSTALL_PROGRAM) $< $@;
endef
quiet_cmd_install_link=INSTALL $*
define cmd_install_link
$(eval link_dir=$(subst $(destdir),,$(if $(findstring $(dir $(3)),./),$(dir $2),$(dir $3)))) $(MKDIR) $(destdir)$(link_dir) && cd $(destdir)$(link_dir) && $(LN) $(subst $(destdir),,$(subst $(link_dir),,$2)) $(subst $(destdir)$(link_dir),,$3)
endef
quiet_cmd_strip_bin=STRIP $*
define cmd_strip_bin
	$(TARGETSTRIP) $@;
endef

##
# install rules
##
$(foreach dir, includedir datadir docdir sysconfdir libdir bindir sbindir ,$(addprefix $(destdir),$($(dir))/)):
	$(Q)$(MKDIR) $@

$(include-install): $(destdir)$(includedir:%/=%)/%: %
	@$(call cmd,install_data)
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(sysconf-install): $(destdir)$(sysconfdir:%/=%)/%: %
	@$(call cmd,install_data)
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(data-install): $(destdir)$(datadir:%/=%)/%: %
	@$(call cmd,install_data)
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(doc-install): $(destdir)$(docdir:%/=%)/%: %
	@$(call cmd,install_data)
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(lib-static-install): $(destdir)$(libdir:%/=%)/lib%$(slib-ext:%=.%): $(objdir)lib%$(slib-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(lib-dynamic-install): $(destdir)$(libdir:%/=%)/lib%$(dlib-ext:%=.%)$(version:%=.%): $(objdir)lib%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(if $(version_m),$(call cmd,install_link,$@,$(@:%.$(version)=%.$(version_m))))
	@$(if $(version_m),$(call cmd,install_link,$(@:%.$(version)=%.$(version_m)),$(@:%.$(version)=%)))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(modules-install): $(destdir)$(pkglibdir:%/=%)/%$(dlib-ext:%=.%): $(objdir)%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(bin-install): $(destdir)$(bindir:%/=%)/%$(bin-ext:%=.%): $(objdir)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(sbin-install): $(destdir)$(sbindir:%/=%)/%$(bin-ext:%=.%): $(objdir)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(libexec-install): $(destdir)$(libexecdir:%/=%)/%$(bin-ext:%=.%): $(objdir)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)
	@$(if $(findstring 1, $S),$(call cmd,strip_bin))
	@$(foreach a,$($*_ALIAS) $($*_ALIAS-y), $(call cmd,install_link,$@,$(a)))

$(pkgconfig-install): $(destdir)$(libdir:%/=%)/pkgconfig/%.pc: $(builddir)%.pc
	@$(call cmd,install_data)

########################################################################
# the makefiles are recursives and (s)lib-y is cleaned each call
# for each call of Makemore, the libraries list must be filled.
# <package>.pc.in is updated each call
# <package>.pc is fill at the end
##
define pkgconfig_pc
# generated by makemore
prefix=@prefix@
exec_prefix=@exec_prefix@
sysconfdir=@sysconfdir@
libdir=@libdir@
pkglibdir=@pkglibdir@
includedir=@includedir@

Name: $(1)
Version: @version@
Description: $($(1)_DESC)
Cflags: -I$${includedir}
Libs: -L$${libdir} $(foreach lib,$(sort $($(1)_LIBS)),-l$(lib:lib%=%))

endef

quiet_cmd_generate_pkgconfig=PKGCONFIG $*
define cmd_generate_pkgconfig
	cat $< | \
		sed "s,@version@,$(version),g" | \
		sed "s,@prefix@,$(prefix),g" | \
		sed "s,@exec_prefix@,$(exec_prefix),g" | \
		sed "s,@libdir@,$(libdir:$(prefix)/%=$${exec_prefix}/%),g" | \
		sed "s,@sysconfdir@,$(sysconfdir:$(prefix)/%=$${prefix}/%),g" | \
		sed "s,@pkglibdir@,$(pkglibdir:$(prefix)/%=$${exec_prefix}/%),g" | \
		sed "s,@includedir@,$(includedir:$(prefix)/%=$${prefix}/%),g" > $@
endef

$(builddir)%.pc.in:
	$(file > $@,$(call pkgconfig_pc,$*))

$(pkgconfig-target): $(builddir)%.pc:$(builddir)%.pc.in
	@$(call cmd,generate_pkgconfig)

###############################################################################
# Project configuration
#
define _generate_configline
$(foreach config,$2,$(if $(findstring n,$$($$(config))),,$(if $$($$(config)),#define $$(config) $$($$(config)))))
endef

define config_header_h
#ifndef __CONFIG_H__
#define __CONFIG_H__

endef

define config_footer_h

#define PKGLIBDIR "$(pkglibdir)"
#define DATADIR "$(datadir)"
#define PKG_DATADIR "$(pkgdatadir)"
#define SYSCONFDIR "$(sysconfdir)"
#define LOCALSTATEDIR "$(localstatedir)"

#endif
endef

quiet_cmd_generate_config_h=CONFIG $(notdir $@)
define cmd_generate_config_h
  $(file >> $@,$(call config_header_h))
  $(foreach config,$2,$(file >> $@,#define $(config) $($(config)) $(newline)))
  $(file >> $@)
  $(file >> $@,$(call config_footer_h))
endef

$(CONFIGFILE): OTHER_CONFIGS=$(foreach line,$(file < $(CONFIG)), $(foreach pattern,$(line), $(if $(findstring $(firstword $(subst =, ,$(pattern))), $(CONFIGS)),,$(firstword $(subst =, ,$(pattern))))))
$(CONFIGFILE): $(if $(wildcard $(srcdir)defconfig),$(CONFIG)) $(dir $(CONFIGFILE))
	$(file > $@)
	@$(call cmd,generate_config_h,$(sort $(CONFIGS) $(OTHER_CONFIGS)))

define version_h
#ifndef __VERSION_H__
#define __VERSION_H__

$(if $(version),#define VERSION $(version))
$(if $(version),#define VERSION_MAJOR $(firstword $(subst ., ,$(version))))
$(if $(version),#define VERSION_MINOR $(word 2,$(subst ., ,$(version))))
$(if $(package),#define PACKAGE "$(package)")
$(if $(version),#define PACKAGE_VERSION "$(version)")
$(if $(package),#define PACKAGE_NAME "$(package)")
$(if $(package),#define PACKAGE_TARNAME "$(subst " ","_",$(package))")
$(if $(package),#define PACKAGE_STRING "$(package) $(version)")
#endif
endef

quiet_cmd_generate_version_h=VERSION $(notdir $@)
define cmd_generate_version_h
	$(file >> $@,$(call version_h))
endef

$(VERSIONFILE): $(dir $(VERSIONFILE))
	$(file > $@)
	@$(call cmd,generate_version_h)

##
# config rules
##
.PHONY: menuconfig gconfig xconfig config oldconfig _oldconfig saveconfig defconfig FORCE
menuconfig gconfig xconfig config:
	$(EDITOR) $(CONFIG)

configfiles+=$(wildcard $(CONFIGFILE))
configfiles+=$(wildcard $(VERSIONFILE))
configfiles+=$(wildcard $(TMPCONFIG))
configfiles+=$(wildcard $(PATHCACHE))

cleanconfig: FORCE
	@$(foreach file,$(configfiles), $(call cmd,clean,$(file));)

oldconfig: _info $(builddir) $(CONFIG) FORCE
	@$(call cmd,clean,$(PATHCACHE))
	$(Q)$(MAKE) _oldconfig

quiet_cmd_oldconfig=OLDCONFIG
cmd_oldconfig=cat $< | grep $(addprefix -e ,$(RESTCONFIGS)) >> $(CONFIG)

_oldconfig: RESTCONFIGS:=$(foreach config,$(CONFIGS),$(if $($(config)),,$(config)))
_oldconfig: $(DEFCONFIG) $(PATHCACHE)
	@$(if $(strip $(RESTCONFIGS)),$(call cmd,oldconfig))

# manage the defconfig files
# 1) use the default defconfig file
# 2) relaunch with _defconfig target
defconfig: action:=_defconfig
defconfig: TMPCONFIG:=$(builddir).tmpconfig
defconfig: build:=$(action) TMPCONFIG=$(builddir).tmpconfig -f $(makemore) file
defconfig: cleanconfig $(builddir) default_action ;

# manage the defconfig files
# 1) set the DEFCONFIG variable
# 2) relaunch with _defconfig target
DEFCONFIGFILES:=$(notdir $(wildcard $(srcdir)configs/*))
$(DEFCONFIGFILES): %_defconfig: cleanconfig $(builddir)
	@$(call cmd,clean,$(CONFIG))
	$(Q)$(MAKE) _defconfig DEFCONFIG=$(srcdir)configs/$*_defconfig TMPCONFIG=$(builddir).tmpconfig -f $(makemore) file=$(file)

.PHONY: $(DEFCONFIGFILES)

ifneq ($(TMPCONFIG),)
include $(TMPCONFIG)

# set the list of configuration variables
ifneq ($(wildcard $(DEFCONFIG)),)
SETCONFIGS=$(shell cat $(DEFCONFIG) | grep -v '^\#' | awk -F= 't$$1 != t {print $$1}'; )
UNSETCONFIGS=$(shell cat $(DEFCONFIG) | awk '/^. .* is not set/{print $$2}')
endif

# set to no all configs available into defconfig and not into .config
CONFIGS:=$(SETCONFIGS) $(UNSETCONFIGS)

quiet_cmd__saveconfig=DEFCONFIG $(notdir $<)
define cmd__saveconfig
  $(foreach config,$2,$(file >> $@,$(config)=$($(config))$(newline)))
endef

$(CONFIG): $(DEFCONFIG) $(TMPCONFIG)
	$(Q)$(file >$@)
	$(Q)$(call cmd,_saveconfig,$(sort $(CONFIGS)))

$(PATHCACHE):
	$(Q)$(file >$@)
	$(Q)$(call cmd,_saveconfig,$(PATHES))

# create a temporary defconfig file in the format of the config file
$(TMPCONFIG): $(DEFCONFIG)
	@cat $< | grep -v '^\#' > $@
	@cat $< | awk '/^. .* is not set/{print $$2"=n"}' >> $@

# load the temporary defconfig file
# if a value is already set on the command line of 'make', the value stay:
_configbuild: $(if $(wildcard $(DEFCONFIG)),$(CONFIGFILE))
_versionbuild: $(if $(strip $(package)$(version)), $(VERSIONFILE))

# 1) load the defconfig file to replace the .config file
# 2) build the pathcache
# recipes) create the .config file with the variables from DEFCONFIG
_defconfig: action:=_defconfig
_defconfig: build:=$(action) TMPCONFIG= -f $(makemore) file
_defconfig: $(PATHCACHE) $(CONFIG) $(subdir-target) $(lib-check-target) _hook _configbuild _versionbuild ;
	@:

.PHONY:_defconfig
else

$(CONFIG):
	$(warning "Configure the project first")
	$(warning "  make <...>_defconfig")
	$(warning "  make defconfig")
	$(warning "  ./configure")
	$(error  )

_defconfig: action:=_defconfig
_defconfig: build:=$(action) TMPCONFIG= -f $(makemore) file
_defconfig: $(subdir-target) $(lib-check-target) _hook;
	@:

.PHONY:_defconfig
endif # ifneq ($(TMPCONFIG),)

########################################################################

ifneq ($(wildcard scripts/help.mk),)
  HELP_OPTIONS+=_help_options_more
endif
ifneq ($(wildcard scripts/gcov.mk),)
  HELP_ENTRIES+=_help_entries_gcov
  HELP_OPTIONS+=_help_options_gcov
endif
ifneq ($(wildcard scripts/qt.mk),)
  HELP_ENTRIES+=_help_entries_qt
  HELP_OPTIONS+=_help_options_qt
endif
ifneq ($(wildcard scripts/download.mk),)
  HELP_ENTRIES+=_help_entries_download
  HELP_OPTIONS+=_help_options_download
endif
help: _help_main _help_options_main $(HELP_OPTIONS)
	@

_help_main:
	@echo "makemore is a set of tools to build your program on every OS with only"
	@echo "a compiler and "make" tools"

_help_options_main:
	@echo ""
	@echo "Make accept several options:"
	@echo " make defconfig :"
	@echo "  options:"
	@echo "    prefix=<directory path>      default /usr/local"
	@echo "    exec_prefix=<directory path> default $$prefix"
	@echo "    bindir=<directory path>      default $$exec_prefix/bin"
	@echo "    sbindir=<directory path>     default $$exec_prefix/sbin"
	@echo "    libdir=<directory path>      default $$exec_prefix/lib"
	@echo "    includedir=<directory path>  default $$exec_prefix/include"
	@echo "    sysconfdir=<directory path>  default $$exec_prefix/etc"
	@echo "    pkglibdir=<directory path>   default $$exec_prefix/lib/<package>"
	@echo "    datadir=<directory path>     default $$exec_prefix/share/<package>"
	@echo ""
	@echo "    builddir=<directory path>        default ."
	@echo "    CROSS_COMPILE=<compiler prefix>  default empty"
	@echo "    SYSROOT=<system root directory>  default empty or /"
	@echo "    TOOLCHAIN=<directory path>       default empty"
	@echo ""
	@$(foreach config,$(CONFIGS),echo "    $(config)=<y|n>    default $($(config))";)
	@echo ""
	@echo " make <name>_defconfig : configuration from a file of \"configs\" directory"
	@echo "  options: "
	@echo "    as defconfig"
	@echo ""
	@echo " make all :"
	@echo "  options: "
	@echo "    DESTDIR=<directory path>     to search libraries into it default empty"
	@echo "    V=<0|1>			to set verbosity default 0"
	@echo "    G=<0|1>			to set gcov options default 0"
	@echo "    DEBUG=<n|y>			to set the debug options default n"
	@echo ""
	@echo " make install :"
	@echo "  options: "
	@echo "    DESTDIR=<directory path>     to search libraries into it default empty"
	@echo "    DEVINSTALL=<y|n>		to install header files default y"
	@echo ""
	@echo " make check : check all LIBRARY entries of the Makefile scripts"
	@echo "  options: "
	@echo ""

endif

