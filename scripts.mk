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

# CONFIG could define LD CC or/and CFLAGS
# CONFIG must be included before "Commands for build and link"
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
##
# default Macros for installation
##
# not set variable if not into the build step
AWK?=awk
INSTALL?=install
INSTALL_PROGRAM?=$(INSTALL)
INSTALL_DATA?=$(INSTALL) -m 644
PKGCONFIG?=pkg-config
YACC=bison

ifneq ($(CROSS_COMPILE),)
	AS=$(CROSS_COMPILE:%-=%)-as
	CC=$(CROSS_COMPILE:%-=%)-gcc
	CXX=$(CROSS_COMPILE:%-=%)-g++
	LD=$(CROSS_COMPILE:%-=%)-gcc
	AR=$(CROSS_COMPILE:%-=%)-ar
	RANLIB=$(CROSS_COMPILE:%-=%)-ranlib
	HOSTCC=gcc
	HOSTCXX=g++
	HOSTLD=gcc
	HOSTAR=ar
	HOSTRANLIB=ranlib
else
ifeq ($(CC),)
# CC is not set use gcc as default compiler
	AS=as
	CC=gcc
	CXX=g++
	LD=gcc
	AR=ar
	RANLIB=ranlib
else ifeq ($(CC),cc)
# if cc is a link on gcc, prefer to use directly gcc for ld
CCVERSION=$(shell $(CC) --version)
ifneq ($(findstring GCC,$(CCVERSION)), )
	CC=gcc
	CXX=g++
	LD=gcc
	AR=ar
	RANLIB=ranlib
endif
endif 
	HOSTCC=$(CC)
	HOSTCXX=$(CXX)
	HOSTLD=$(LD)
	HOSTAR=$(AR)
	HOSTRANLIB=$(RANLIB)
endif
ifeq ($(findstring gcc,$(LD)),gcc)
ldgcc=-Wl,$(1),$(2)
else
ldgcc=$(1) $(2)
endif

prefix?=/usr/local
prefix:=$(prefix:"%"=%)
bindir?=$(prefix)/bin
bindir:=$(bindir:"%"=%)
sbindir?=$(prefix)/sbin
sbindir:=$(sbindir:"%"=%)
libdir?=$(prefix)/lib
libdir:=$(libdir:"%"=%)
includedir?=$(prefix)/include
includedir:=$(includedir:"%"=%)
datadir?=$(prefix)/share/$(PACKAGE_NAME:"%"=%)
datadir:=$(datadir:"%"=%)
pkglibdir?=$(libdir)/$(PACKAGE_NAME:"%"=%)
pkglibdir:=$(pkglibdir:"%"=%)

ifneq ($(file),)
#CFLAGS+=$(foreach macro,$(DIRECTORIES_LIST),-D$(macro)=\"$($(macro))\")
CFLAGS+=-I$(src) -I$(CURDIR) -I.
LIBRARY+=
LDFLAGS+=-L$(builddir)
LDFLAGS+=$(call ldgcc,-rpath,$(libdir)) $(call ldgcc,-rpath-link,$(obj))
else
export prefix bindir sbindir libdir includedir datadir pkglibdir srcdir
endif

##
# objects recipes generation
##

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(eval $(t)-objs+=$(patsubst %.Ss,%.o,$(patsubst %.S,%.o,$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$($(t)_SOURCES) $($(t)_SOURCES-y)))))))
target-objs:=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(if $($(t)-objs), $(addprefix $(obj),$($(t)-objs)), $(obj)$(t).o))

$(foreach t,$(hostbin-y), $(eval $(t)-objs:=$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$($(t)_SOURCES) $($(t)_SOURCES-y)))))
target-hostobjs:=$(foreach t, $(hostbin-y), $(if $($(t)-objs), $(addprefix $(hostobj)/,$($(t)-objs)), $(hostobj)/$(t).o))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_CFLAGS+=$($(s:%.c=%)_CFLAGS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_CFLAGS+=$($(s:%.cpp=%)_CFLAGS)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBRARY+=$($(s:%.c=%)_LIBRARY)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LIBRARY+=$($(s:%.cpp=%)_LIBRARY)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(eval $(t)_CFLAGS+=$($(t)_CFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(eval $(t)_LDFLAGS+=$($(t)_LDFLAGS-y)))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(eval $(t)_LIBRARY+=$($(t)_LIBRARY-y)))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_CFLAGS+=$(shell pkg-config --cflags lib$(l) 2> /dev/null) ) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(s:%.c=%)_CFLAGS+=$($(t)_CFLAGS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(s:%.cpp=%)_CFLAGS+=$($(t)_CFLAGS)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LDFLAGS+=$($(s:%.c=%)_LDFLAGS)) ))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES) $($(t)_SOURCES-y),$(eval $(t)_LDFLAGS+=$($(s:%.cpp=%)_LDFLAGS)) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_LDFLAGS+=$(shell pkg-config --libs-only-L lib$(l) 2> /dev/null) ) ))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBRARY),$(eval $(t)_LIBS+=$(firstword $(subst {, ,$(subst },,$(l)))) ) ))
$(foreach l, $(LIBRARY),$(eval LIBS+=$(firstword $(subst {, ,$(subst },,$(l)))) ) )

$(foreach l, $(LIBS),$(eval CFLAGS+=$(shell $(PKGCONFIG) --cflags lib$(l) 2> /dev/null) ) )
$(foreach l, $(LIBS),$(eval LDFLAGS+=$(shell $(PKGCONFIG) --libs-only-L lib$(l) 2> /dev/null) ) )
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBS),$(eval CFLAGS+=$(shell $(PKGCONFIG) --cflags lib$(l) 2> /dev/null))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach l, $($(t)_LIBS),$(eval LDFLAGS+=$(shell $(PKGCONFIG) --libs-only-L lib$(l) 2> /dev/null))))

# The Dynamic_Loader library (libdl) allows to load external libraries.
# If this libraries has to link to the binary functions, 
# this binary has to export the symbol with -rdynamic flag
$(foreach t,$(bin-y) $(sbin-y),$(if $(findstring dl, $($(t)_LIBRARY) $(LIBRARY)),$(eval $(t)_LDFLAGS+=-rdynamic)))

##
# targets recipes generation
##
slib-y:=$(addprefix lib,$(slib-y))
lib-y:=$(addprefix lib,$(lib-y))
ifeq (STATIC,y)
lib-static-target:=$(addprefix $(obj),$(addsuffix $(slib-ext:%=.%),$(slib-y) $(lib-y)))
else
lib-static-target:=$(addprefix $(obj),$(addsuffix $(slib-ext:%=.%),$(slib-y)))
lib-dynamic-target:=$(addprefix $(obj),$(addsuffix $(dlib-ext:%=.%),$(lib-y)))
endif
modules-target:=$(addprefix $(obj),$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
bin-target:=$(addprefix $(obj),$(addsuffix $(bin-ext:%=.%),$(bin-y) $(sbin-y)))
hostbin-target:=$(addprefix $(hostobj),$(addsuffix $(bin-ext:%=.%),$(hostbin-y)))
subdir-target:=$(wildcard $(addsuffix /Makefile,$(subdir-y)))
subdir-target+=$(wildcard $(addsuffix /*$(makefile-ext:%=.%),$(subdir-y)))
subdir-dir:=$(dir $(wildcard $(addsuffix /Makefile,$(subdir-y))))
subdir-target+=$(wildcard $(filter-out $(subdir-dir:%/=%),$(subdir-y)))

targets:=
targets+=$(lib-dynamic-target)
targets+=$(modules-target)
targets+=$(lib-static-target)
targets+=$(bin-target)

##
# install recipes generation
##
data-install:=$(addprefix $(datadir)/,$(data-y))
include-install:=$(addprefix $(includedir)/,$(include-y))
lib-dynamic-install:=$(addprefix $(libdir)/,$(addsuffix $(dlib-ext:%=.%),$(lib-y)))
modules-install:=$(addprefix $(pkglibdir)/,$(addsuffix $(dlib-ext:%=.%),$(modules-y)))
bin-install:=$(addprefix $(bindir)/,$(addsuffix $(bin-ext:%=.%),$(bin-y)))
sbin-install:=$(addprefix $(sbindir)/,$(addsuffix $(bin-ext:%=.%),$(sbin-y)))

install:=
ifneq ($(CROSS_COMPILE),)
ifneq ($(DESTDIR),)
install+=$(bin-install)
install+=$(sbin-install)
install+=$(lib-dynamic-install)
install+=$(modules-install)
install+=$(data-install)
endif
else
install+=$(bin-install)
install+=$(sbin-install)
install+=$(lib-dynamic-install)
install+=$(modules-install)
install+=$(data-install)
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

_hostbuild: $(if $(hostbin-y) , $(hostobj) $(hostbin-target))
_configbuild: $(if $(wildcard $(CONFIG)),$(join $(CURDIR)/,$(CONFIG:%=%.h)))

_build: _info $(obj) _configbuild $(subdir-target) _hostbuild $(targets)
	@:

_install: action:=_install
_install: build:=$(action) -f $(srcdir)$(makemore) file
_install: $(install) $(subdir-target)
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
_check: build:=$(action) -f $(srcdir)$(makemore) file
_check: $(subdir-target) $(LIBRARY) $(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_LIBRARY))

clean: action:=_clean
clean: build:=$(action) -f $(srcdir)$(makemore) file
clean: $(.DEFAULT_GOAL)

distclean: action:=_distclean
distclean: build:=$(action) -f $(srcdir)$(makemore) file
distclean: $(.DEFAULT_GOAL)
distclean:
	$(Q)$(call cmd,clean,$(wildcard $(CURDIR)$(CONFIG:%=%.h)))

install: action:=_install
install: build:=$(action) -f $(srcdir)$(makemore) file
install: $(.DEFAULT_GOAL)

check: action:=_check
check: build:=$(action) -f $(srcdir)$(makemore) file
check: $(.DEFAULT_GOAL)

default_action:
	$(Q)$(MAKE) $(build)=$(file)
	@:

all: default_action

$(join $(CURDIR)/,$(CONFIG:%=%.h)): $(srcdir)/$(CONFIG)
	@$(call cmd,config)

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
 cmd_as_o_s=$(AS) $(ASFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_cc_o_c=CC $*
 cmd_cc_o_c=$(CC) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_cc_o_cpp=CXX $*
 cmd_cc_o_cpp=$(CXX) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_ld_bin=LD $*
 cmd_ld_bin=$(LD) -o $@ $^ $(LDFLAGS) $($*_LDFLAGS) $(LIBS:%=-l%) $($*_LIBS:%=-l%) -lc
quiet_cmd_hostcc_o_c=HOSTCC $*
 cmd_hostcc_o_c=$(HOSTCC) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_hostcmd_cc_o_cpp=HOSTCXX $*
 cmd_hostcc_o_cpp=$(HOSTCXX) $(CFLAGS) $($*_CFLAGS) $($*_CFLAGS-y) -c -o $@ $<
quiet_cmd_hostld_bin=HOSTLD $*
 cmd_hostld_bin=$(HOSTLD) -o $@ $^ $(LDFLAGS) $($*_LDFLAGS) $(LIBS:%=-l%) $($*_LIBS:%=-l%) -lc
quiet_cmd_ld_slib=LD $*
 cmd_ld_slib=$(RM) $@ && \
	$(AR) -cvq $@ $^ > /dev/null && \
	$(RANLIB) $@
quiet_cmd_ld_dlib=LD $*
 cmd_ld_dlib=$(LD) $(LDFLAGS) $($*_LDFLAGS) -shared $(call ldgcc,-soname,$(notdir $@)) -o $@ $^ $(addprefix -L,$(RPATH)) $(LIBS:%=-l%) $($*_LIBS:%=-l%)

checkoption:=--exact-version
quiet_cmd_check_lib=CHECK $*
prepare_check=$(if $(filter %-, $1),$(eval checkoption:=--atleast-version),$(if $(filter -%, $1),$(eval checkoption:=--max-version)))
cmd_check_lib=$(if $(findstring $(3:%-=%), $3),$(if $(findstring $(3:-%=%), $3),,$(eval checkoption:=--atleast-version),$(eval checkoption:=--max-version))) \
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

.PHONY:$(subdir-target)
$(subdir-target): %:
	$(Q)$(MAKE) -C $(dir $*) cwdir=$(cwd)$(dir $*) builddir=$(builddir) $(build)=$(notdir $*)

$(LIBRARY) $(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_LIBRARY)): %:
	@$(call prepare_check,$(lastword $(subst {, ,$(subst },,$@))))
	@$(if $(findstring $(words $(subst {, ,$(subst },,$@))),2),$(call cmd,check_lib,$(firstword $(subst {, ,$(subst },,$@))),$(lastword $(subst {, ,$(subst },,$@)))))

##
# Commands for install
##
quiet_cmd_install_data=INSTALL $*
 cmd_install_data=$(INSTALL_DATA) -D $< $(DESTDIR:%=%/)$@
quiet_cmd_install_bin=INSTALL $*
 cmd_install_bin=$(INSTALL_PROGRAM) -D $< $(DESTDIR:%=%/)$@

##
# install rules
##
$(include-install): $(includedir)/%: %
	@$(call cmd,install_data)
$(data-install): $(datadir)/%: %
	@$(call cmd,install_data)
$(lib-dynamic-install): $(libdir)/lib%$(dlib-ext:%=.%): $(obj)lib%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
$(modules-install): $(pkglibdir)/%$(dlib-ext:%=.%): $(obj)%$(dlib-ext:%=.%)
	@$(call cmd,install_bin)
$(bin-install): $(bindir)/%$(bin-ext:%=.%): $(obj)%$(bin-ext:%=.%)
	@$(call cmd,install_bin)
$(sbin-install): $(sbindir)/%$(bin-ext:%=.%): $(obj)%$(bin-ext:%=.%)
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
