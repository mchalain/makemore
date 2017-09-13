makemore:=$(notdir $(lastword $(MAKEFILE_LIST)))
ifeq ($(inside_makemore),)
inside_makemore:=yes
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
cmd = $(echo-cmd) $(cmd_$(1))

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
data-y:=
hostbin-y:=

srcdir?=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
file?=$(notdir $(firstword $(MAKEFILE_LIST)))

VERSIONFILE=version

# CONFIG could define LD CC or/and CFLAGS
# CONFIG must be included before "Commands for build and link"
CONFIGURE_STATUS:=configure.status
ifneq ($(wildcard $(srcdir)$(CONFIGURE_STATUS)),)
include $(srcdir)$(CONFIGURE_STATUS)
endif

CONFIG?=config
ifneq ($(wildcard $(srcdir)$(CONFIG)),)
include $(srcdir)$(CONFIG)
endif

ifneq ($(file),)
include $(file)
endif

obj=$(if $(builddir),$(join $(srcdir),$(join $(builddir:%=%/),$(cwdir))))
hostobj=$(srcdir)host/$(dir $(file))

PATH:=$(value PATH):$(hostobj)
TMPDIR:=/tmp
TESTFILE:=makemore_test
##
# default Macros for installation
##
# not set variable if not into the build step
AWK?=awk
RM?=rm -f
INSTALL?=install
INSTALL_PROGRAM?=$(INSTALL)
INSTALL_DATA?=$(INSTALL) -m 644
PKGCONFIG?=pkg-config
YACC=bison

CC?=gcc
CXX?=g++
LD?=gcc
AR?=ar
RANLIB?=ranlib
HOSTCC=$(CC)
HOSTCXX=$(CXX)
HOSTLD=$(LD)
HOSTAR=$(AR)
HOSTRANLIB=$(RANLIB)

ldgcc=$(1) $(2)

ifneq ($(CROSS_COMPILE),)
	AS=$(CROSS_COMPILE:%-=%)-as
	CC=$(CROSS_COMPILE:%-=%)-gcc
	CXX=$(CROSS_COMPILE:%-=%)-g++
	LD=$(CROSS_COMPILE:%-=%)-gcc
	AR=$(CROSS_COMPILE:%-=%)-ar
	RANLIB=$(CROSS_COMPILE:%-=%)-ranlib
	ldgcc=-Wl,$(1),$(2)
else ifeq ($(CC),cc)
# if cc is a link on gcc, prefer to use directly gcc for ld
CCVERSION=$(shell $(CC) -v 2>&1)
ifneq ($(findstring GCC,$(CCVERSION)), )
	LD=cc
	HOSTLD=$(LD)
	ldgcc=-Wl,$(1),$(2)
endif
else ifneq ($(findstring gcc,$(CC)),)
	LD=$(CC)
	ldgcc=-Wl,$(1),$(2)
endif

ARCH?=$(shell LANG=C $(CC) -v 2>&1 | grep Target | $(AWK) 'BEGIN {FS="[- ]"} {print $$2}')
libsuffix=$(findstring 64,$(ARCH))

prefix?=/usr/local
prefix:=$(prefix:"%"=%)
bindir?=$(prefix)/bin
bindir:=$(bindir:"%"=%)
sbindir?=$(prefix)/sbin
sbindir:=$(sbindir:"%"=%)
libdir?=$(word 1,$(wildcard $(prefix)/lib$(libsuffix) $(prefix)/lib))
libdir:=$(if $(libdir), $(libdir),$(prefix)/lib)
libdir:=$(libdir:"%"=%)
sysconfdir?=$(prefix)/etc
sysconfdir:=$(sysconfdir:"%"=%)
includedir?=$(prefix)/include
includedir:=$(includedir:"%"=%)
datadir?=$(prefix)/share/$(package:"%"=%)
datadir:=$(datadir:"%"=%)
pkglibdir?=$(libdir)/$(package:"%"=%)
pkglibdir:=$(pkglibdir:"%"=%)

ifneq ($(sysroot),)
SYSROOT+=--sysroot=$(sysroot)
endif

#CFLAGS+=$(foreach macro,$(DIRECTORIES_LIST),-D$(macro)=\"$($(macro))\")
CFLAGS+=-I$(src) -I$(CURDIR) -I. -I$(sysroot)$(includedir)
LIBRARY+=
ifneq ($(builddir),)
LDFLAGS+=-L$(builddir)
else
LDFLAGS+=-L.
endif
LDFLAGS+=-L$(sysroot)$(libdir)
LDFLAGS+=$(if $(strip $(libdir)),$(call ldgcc,-rpath,$(strip $(libdir))))
LDFLAGS+=$(if $(strip $(pkglibdir)),$(call ldgcc,-rpath,$(strip $(pkglibdir))))

export package version prefix bindir sbindir libdir includedir datadir pkglibdir srcdir

##
# objects recipes generation
##

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(eval $(t)-objs+=$(patsubst %.Ss,%.o,$(patsubst %.S,%.o,$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$($(t)_SOURCES) $($(t)_SOURCES-y)))))))
target-objs:=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(if $($(t)-objs), $(addprefix $(obj),$($(t)-objs)), $(obj)$(t).o))

$(foreach t,$(hostbin-y), $(eval $(t)-objs:=$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$($(t)_SOURCES) $($(t)_SOURCES-y)))))
$(foreach t,$(hostslib-y), $(eval $(t)-objs:=$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$($(t)_SOURCES) $($(t)_SOURCES-y)))))
target-hostobjs:=$(foreach t, $(hostbin-y) $(hostslib-y), $(if $($(t)-objs), $(addprefix $(hostobj)/,$($(t)-objs)), $(hostobj)/$(t).o))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBS+=$($(s:%.c=%)_LIBS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBS+=$($(s:%.cpp=%)_LIBS)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBRARY+=$($(s:%.c=%)_LIBRARY)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBRARY+=$($(s:%.cpp=%)_LIBRARY)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_CFLAGS+=$($(t)_CFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LDFLAGS+=$($(t)_LDFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LIBS+=$($(t)_LIBS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostbin-y),$(eval $(t)_LIBRARY+=$($(t)_LIBRARY-y)))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(s:%.c=%)_CFLAGS+=$($(t)_CFLAGS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(s:%.cpp=%)_CFLAGS+=$($(t)_CFLAGS)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LDFLAGS+=$($(s:%.c=%)_LDFLAGS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LDFLAGS+=$($(s:%.cpp=%)_LDFLAGS)) ))

# LIBRARY contains libraries name to check
# The name may terminate with {<version>} informations like LIBRARY+=usb{1.0}
# Here the commands remove the informations and store the name into LIBS
# After LIBS contains all libraries name to link
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_LIBS+=$(firstword $(subst {, ,$(subst },,$(l)))) ) ))
$(foreach l, $(LIBRARY),$(eval LIBS+=$(firstword $(subst {, ,$(subst },,$(l)))) ) )

$(foreach l, $(LIBS),$(eval CFLAGS+=$(shell $(PKGCONFIG) --cflags lib$(l) 2> /dev/null) ) )
$(foreach l, $(LIBS),$(eval LDFLAGS+=$(shell $(PKGCONFIG) --libs-only-L lib$(l) 2> /dev/null) ) )
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBS),$(eval $(t)_CFLAGS+=$(shell $(PKGCONFIG) --cflags lib$(l) 2> /dev/null))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBS),$(eval $(t)_LDFLAGS+=$(shell $(PKGCONFIG) --libs-only-L lib$(l) 2> /dev/null) ) ))


# The Dynamic_Loader library (libdl) allows to load external libraries.
# If this libraries has to link to the binary functions, 
# this binary has to export the symbol with -rdynamic flag
$(foreach t,$(bin-y) $(sbin-y),$(if $(findstring dl, $($(t)_LIBS) $(LIBS)),$(eval $(t)_LDFLAGS+=-rdynamic)))

##
# targets recipes generation
##
ifeq (STATIC,y)
lib-static-target:=$(addprefix $(obj),$(addsuffix $(slib-ext:%=.%),$(addprefix lib,$(slib-y) $(lib-y))))
else
lib-static-target:=$(addprefix $(obj),$(addsuffix $(slib-ext:%=.%),$(addprefix lib,$(slib-y))))
lib-dynamic-target:=$(addprefix $(obj),$(addsuffix $(dlib-ext:%=.%),$(addprefix lib,$(lib-y))))
endif
modules-target:=$(addprefix $(obj),$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
bin-target:=$(addprefix $(obj),$(addsuffix $(bin-ext:%=.%),$(bin-y) $(sbin-y)))
hostslib-target:=$(addprefix $(hostobj),$(addsuffix $(slib-ext:%=.%),$(addprefix lib,$(hostslib-y))))
hostbin-target:=$(addprefix $(hostobj),$(addsuffix $(bin-ext:%=.%),$(hostbin-y)))
subdir-target:=$(wildcard $(addsuffix /Makefile,$(subdir-y)))
subdir-dir:=$(dir $(subdir-target))
subdir-y:=$(filter-out $(subdir-dir:%/=%),$(subdir-y))
subdir-target+=$(wildcard $(addsuffix /*$(makefile-ext:%=.%),$(subdir-y)))
subdir-target+=$(wildcard $(subdir-y))
#subdir-project:=$(wildcard $(addsuffix /configure,$(subdir-y)))
#subdir-target:=$(filter-out $(subdir-project),$(subdir-target))

targets:=
targets+=$(lib-dynamic-target)
targets+=$(modules-target)
targets+=$(lib-static-target)
targets+=$(bin-target)

##
# install recipes generation
##
sysconf-install:=$(addprefix $(DESTDIR:%=%/)$(sysconfdir)/,$(sysconf-y))
data-install:=$(addprefix $(DESTDIR:%=%/)$(datadir)/,$(data-y))
include-install:=$(addprefix $(DESTDIR:%=%/)$(includedir)/,$(include-y))
lib-dynamic-install:=$(addprefix $(DESTDIR:%=%/)$(libdir)/,$(addsuffix $(dlib-ext:%=.%),$(addprefix lib,$(lib-y))))
modules-install:=$(addprefix $(DESTDIR:%=%/)$(pkglibdir)/,$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
bin-install:=$(addprefix $(DESTDIR:%=%/)$(bindir)/,$(addsuffix $(bin-ext:%=.%),$(bin-y)))
sbin-install:=$(addprefix $(DESTDIR:%=%/)$(sbindir)/,$(addsuffix $(bin-ext:%=.%),$(sbin-y)))

install:=
ifneq ($(CROSS_COMPILE),)
ifneq ($(DESTDIR),)
install+=$(bin-install)
install+=$(sbin-install)
install+=$(lib-dynamic-install)
install+=$(modules-install)
install+=$(data-install)
install+=$(sysconf-install)
install+=$(include-install)
endif
else
install+=$(bin-install)
install+=$(sbin-install)
install+=$(lib-dynamic-install)
install+=$(modules-install)
install+=$(data-install)
install+=$(sysconf-install)
install+=$(include-install)
endif

##
# main entries
##
action:=_build
build:=$(action) -f $(srcdir)$(makemore) file
.DEFAULT_GOAL:=_entry
.PHONY:_entry _build _install _clean _distclean _check
_entry: default_action

_info:
	@:

_hostbuild: $(if $(hostslib-y) $(hostbin-y) , $(hostobj) $(hostslib-target) $(hostbin-target))
_configbuild: $(if $(wildcard $(CONFIG)),$(join $(CURDIR)/,$(CONFIG:%=%.h)))
_versionbuild: $(if $(package) $(version), $(join $(CURDIR)/,$(VERSIONFILE:%=%.h)))

_build: _info $(obj) $(subdir-project) $(subdir-target) _hostbuild $(targets)
	@:

_install: action:=_install
_install: build:=$(action) -f $(srcdir)$(makemore) file
_install: _info $(install) $(subdir-target)
	@:

_clean: action:=_clean
_clean: build:=$(action) -f $(srcdir)$(makemore) file
_clean: $(subdir-target) _clean_objs

_clean_objs:
	$(Q)$(call cmd,clean,$(wildcard $(target-objs)) $(wildcard $(target-hostobjs)))

_distclean: action:=_distclean
_distclean: build:=$(action) -f $(srcdir)$(makemore) file
_distclean: $(subdir-target) _clean_objs
	$(Q)$(call cmd,clean,$(wildcard $(targets)))
	$(Q)$(call cmd,clean_dir,$(filter-out $(src),$(obj)))

_check: action:=_check
_check: build:=$(action) -s -f $(srcdir)$(makemore) file
_check: $(subdir-target) $(LIBRARY) $(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_LIBRARY))

clean: action:=_clean
clean: build:=$(action) -f $(srcdir)$(makemore) file
clean: $(.DEFAULT_GOAL)

distclean: action:=_distclean
distclean: build:=$(action) -f $(srcdir)$(makemore) file
distclean: $(.DEFAULT_GOAL)
distclean:
	$(Q)$(call cmd,clean,$(wildcard $(join $(CURDIR)/,$(CONFIG:%=%.h))))
	$(Q)$(call cmd,clean,$(wildcard $(join $(CURDIR)/,$(VERSIONFILE:%=%.h))))

install: action:=_install
install: build:=$(action) -f $(srcdir)$(makemore) file
install: $(.DEFAULT_GOAL)

check: action:=_check
check: build:=$(action) -s -f $(srcdir)$(makemore) file
check: $(.DEFAULT_GOAL)

default_action: _info _configbuild _versionbuild
	$(Q)$(MAKE) $(build)=$(file)
	@:

all: default_action

$(join $(CURDIR)/,$(CONFIG:%=%.h)): $(srcdir)/$(CONFIG)
	@$(call cmd,config)

$(join $(CURDIR)/,$(VERSIONFILE:%=%.h)):
	@echo '#ifndef __VERSION_H__' >> $@
	@echo '#define __VERSION_H__' >> $@
	@$(if $(version), echo '#define VERSION "'$(version)'"' >> $@)
	@$(if $(package), echo '#define PACKAGE "'$(package)'"' >> $@)
	@echo '#endif' >> $@

##
# Commands for clean
##
quiet_cmd_clean=$(if $(2),CLEAN  $(notdir $(2)))
 cmd_clean=$(if $(2),$(RM) $(2))
quiet_cmd_clean_dir=$(if $(2),CLEAN $(notdir $(2)))
 cmd_clean_dir=$(if $(2),$(RM) -r $(2))
##
# Commands for build and link
##
RPATH=$(wildcard $(addsuffix /.,$(wildcard $(CURDIR:%/=%)/* $(obj)*)))
quiet_cmd_yacc_y=YACC $*
 cmd_yacc_y=$(YACC) -o $@ $<
quiet_cmd_as_o_s=AS $*
 cmd_as_o_s=$(AS) $(SYSROOT) $(ASFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_cc_o_c=CC $*
 cmd_cc_o_c=$(CC) $(SYSROOT) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_cc_o_cpp=CXX $*
 cmd_cc_o_cpp=$(CXX) $(SYSROOT) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_ld_bin=LD $*
 cmd_ld_bin=$(LD) $(SYSROOT) -o $@ $^ $(LDFLAGS) $($*_LDFLAGS) -L. $(LIBS:%=-l%) $($*_LIBS:%=-l%)
quiet_cmd_hostcc_o_c=HOSTCC $*
 cmd_hostcc_o_c=$(HOSTCC) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_hostcmd_cc_o_cpp=HOSTCXX $*
 cmd_hostcc_o_cpp=$(HOSTCXX) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_hostld_bin=HOSTLD $*
 cmd_hostld_bin=$(HOSTLD) -o $@ $^ $(LDFLAGS) $($*_LDFLAGS) -L. $(LIBS:%=-l%) $($*_LIBS:%=-l%)
quiet_cmd_hostld_slib=HOSTLD $*
 cmd_hostld_slib=$(RM) $@ && \
	$(HOSTAR) -cvq $@ $^ > /dev/null && \
	$(HOSTRANLIB) $@
quiet_cmd_ld_slib=LD $*
 cmd_ld_slib=$(RM) $@ && \
	$(AR) -cvq $@ $^ > /dev/null && \
	$(RANLIB) $@
quiet_cmd_ld_dlib=LD $*
 cmd_ld_dlib=$(LD) $(SYSROOT) $(LDFLAGS) $($*_LDFLAGS) -shared $(call ldgcc,-soname,$(strip $(notdir $@))) -o $@ $^ $(addprefix -L,$(RPATH)) $(LIBS:%=-l%) $($*_LIBS:%=-l%)

checkoption:=--exact-version
quiet_cmd_check_lib=CHECK $*
cmd_check_lib=$(CC) -c -o $(TMPDIR)/$(TESTFILE:%=%.o) $(TMPDIR)/$(TESTFILE:%=%.c) $(CFLAGS) && \
	$(LD) -o $(TMPDIR)/$(TESTFILE) $(TMPDIR)/$(TESTFILE:%=%.o) $(LDFLAGS) $(addprefix -l, $2) > /dev/null 2>&1
prepare_check=$(if $(filter %-, $2),$(eval checkoption:=--atleast-version),$(if $(filter -%, $2),$(eval checkoption:=--max-version)))
cmd_check2_lib=$(if $(findstring $(3:%-=%), $3),$(if $(findstring $(3:-%=%), $3),,$(eval checkoption:=--atleast-version),$(eval checkoption:=--max-version))) \
	$(PKGCONFIG) --print-errors $(checkoption) $(subst -,,$3) lib$2

##
# build rules
##
.SECONDEXPANSION:
$(obj)%.tab.c:%.y
	@$(call cmd,yacc_y)

$(obj)%.o:%.s
	@$(call cmd,as_o_s)

$(obj)%.o:%.c
	@$(call cmd,cc_o_c)

$(obj)%.o:%.cpp
	@$(call cmd,cc_o_cpp)

$(obj):
	$(Q)mkdir -p $@

$(hostobj)%.o:%.c
	@$(call cmd,hostcc_o_c)

$(hostobj)%.o:%.cpp
	@$(call cmd,hostcc_o_cpp)

$(hostobj):
	$(Q)mkdir -p $@

$(lib-static-target): $(obj)lib%$(slib-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(obj),$$(%-objs)), $(obj)%.o)
	@$(call cmd,ld_slib)

$(lib-dynamic-target): CFLAGS+=-fPIC
$(lib-dynamic-target): $(obj)lib%$(dlib-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(obj),$$(%-objs)), $(obj)%.o)
	@$(call cmd,ld_dlib)

$(modules-target): CFLAGS+=-fPIC
$(modules-target): $(obj)%$(dlib-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(obj),$$(%-objs)), $(obj)%.o)
	@$(call cmd,ld_dlib)

#$(bin-target): $(obj)/%$(bin-ext:%=.%): $$(if $$(%_SOURCES), $$(addprefix $(src)/,$$(%_SOURCES)), $(src)/%.c) 
$(bin-target): $(obj)%$(bin-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(obj),$$(%-objs)), $(obj)%.o)
	@$(call cmd,ld_bin)

$(hostbin-target): $(hostobj)%$(bin-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(hostobj),$$(%-objs)), $(hostobj)%.o)
	@$(call cmd,hostld_bin)

$(hostslib-target): $(hostobj)lib%$(slib-ext:%=.%): $$(if $$(%-objs), $$(addprefix $(hostobj),$$(%-objs)), $(hostobj)%.o)
	@$(call cmd,hostld_slib)

.PHONY:$(subdir-target) $(subdir-project) FORCE
#$(subdir-project): %:
#	$(Q)cd $(dir $*) && autoreconf -i
#	$(Q)cd $(dir $*) && ./configure
#	$(Q)cd $(dir $*) && $(MAKE)

$(subdir-target): %: FORCE
	$(Q)$(MAKE) -C $(dir $*) cwdir=$(cwd)$(dir $*) builddir=$(builddir) $(build)=$(notdir $*)

$(LIBRARY) $(sort $(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_LIBRARY))): %:
	@$(RM) $(TMPDIR)/$(TESTFILE:%=%.c) $(TMPDIR)/$(TESTFILE)
	@echo "int main(){}" > $(TMPDIR)/$(TESTFILE:%=%.c)
	@$(call cmd,check_lib,$(firstword $(subst {, ,$(subst },,$@))))
	@$(call prepare_check,$(lastword $(subst {, ,$(subst },,$@))))
	@$(if $(findstring $(words $(subst {, ,$(subst },,$@))),2),$(call cmd,check2_lib,$(firstword $(subst {, ,$(subst },,$@))),$(lastword $(subst {, ,$(subst },,$@)))))

##
# Commands for install
##
quiet_cmd_install_data=INSTALL $*
 cmd_install_data=$(INSTALL_DATA) -D $< $@
quiet_cmd_install_bin=INSTALL $*
 cmd_install_bin=$(INSTALL_PROGRAM) -D $< $@

##
# install rules
##
$(include-install): $(DESTDIR:%=%/)$(includedir)/%: %
	@$(call cmd,install_data)
$(sysconf-install): $(DESTDIR:%=%/)$(sysconfdir)/%: %
	@$(call cmd,install_data)
$(data-install): $(DESTDIR:%=%/)$(datadir)/%: %
	@$(call cmd,install_data)
$(lib-dynamic-install): $(DESTDIR:%=%/)$(libdir)/lib%$(dlib-ext:%=.%): $(obj)lib%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
$(modules-install): $(DESTDIR:%=%/)$(pkglibdir)/%$(dlib-ext:%=.%): $(obj)%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
$(bin-install): $(DESTDIR:%=%/)$(bindir)/%$(bin-ext:%=.%): $(obj)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)
$(sbin-install): $(DESTDIR:%=%/)$(sbindir)/%$(bin-ext:%=.%): $(obj)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)

##
# commands for configuration
##
empty=
space=$(empty) $(empty)
quote="
sharp=\#
quiet_cmd_config=CONFIG $*
 cmd_config=$(AWK) -F= '$$1 != $(quote)$(quote) {print $(quote)$(sharp)define$(space)$(quote)$$1$(quote)$(space)$(quote)$$2}' $< > $@
endif
