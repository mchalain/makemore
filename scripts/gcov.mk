GCOV?=gcov
LCOV?=lcov
GENHTML?=genhtml
TARGETGCOV:=$(TARGETPREFIX)$(GCOV)

ifeq ($(G),1)
INTERN_CFLAGS+=--coverage -fprofile-arcs -ftest-coverage
INTERN_LDFLAGS+=--coverage -fprofile-arcs -ftest-coverage
INTERN_LIBS+=gcov
O:=0
endif

gcov-target:=$(patsubst %.o,%.c.gcov,$(sort $(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_GENERATED) $(addprefix $(objdir),$($(t)-objs)))))

_gcov: action:=_gcov
_gcov: build:=$(action) -f $(makemore) file
_gcov: _info $(subdir-target) $(gcov-target)
	@:

gcov: action:=_gcov
gcov: build:=$(action) -f $(makemore) file
gcov: default_action ;

gcovhtml: $(builddir)gcov_report

quiet_cmd_cc_gcov_c=GCOV $*
 cmd_cc_gcov_c=$(TARGETGCOV) -o $(objdir) -s $(src) -p $< -t > $@;
quiet_cmd_lcov=LCOV
 cmd_lcov=$(LCOV) --directory $(builddir) --capture --output-file $@
quiet_cmd_genhtml=GENHTML $@
 cmd_genhtml=$(GENHTML) $< --output-directory $@

$(objdir)%.c.gcov:%.c $(file)
	@$(call cmd,cc_gcov_c)

$(objdir)%.c.gcov:%.cpp $(file)
	@$(call cmd,cc_gcov_c)

# for generated files
$(objdir)%.c.gcov:$(obj)%.c $(file)
	@$(call cmd,cc_gcov_c)

$(objdir)%.c.gcov:$(obj)%.cpp $(file)
	@$(call cmd,cc_gcov_c)

$(builddir)gcov.info: $(gcov-target)
	@$(call cmd,lcov)

$(builddir)gcov_report: $(builddir)gcov.info
	@$(call cmd,genhtml)
