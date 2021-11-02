TARGETGCOV:=$(TARGETPREFIX)$(GCOV)

ifeq ($(G),1)
INTERN_CFLAGS+=--coverage -fprofile-arcs -ftest-coverage
INTERN_LDFLAGS+=--coverage -fprofile-arcs -ftest-coverage
INTERN_LIBS+=gcov
O:=0
endif

gcov-target:=$(patsubst %.o,%.c.gcov,$(sort $(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_GENERATED) $(addprefix $(obj),$($(t)-objs)))))

_gcov: action:=_gcov
_gcov: build:=$(action) -f $(makemore) file
_gcov: _info $(subdir-target) $(gcov-target)
	@:

gcov: action:=_gcov
gcov: build:=$(action) -f $(makemore) file
gcov: default_action ;

quiet_cmd_cc_gcov_c=GCOV $*
 cmd_cc_gcov_c=$(TARGETGCOV) -o $(obj) -s $(src) -p $< -t > $@;

$(obj)%.c.gcov:%.c $(file)
	@$(call cmd,cc_gcov_c)

$(obj)%.c.gcov:%.cpp $(file)
	@$(call cmd,cc_gcov_c)

# for generated files
$(obj)%.c.gcov:$(obj)%.c $(file)
	@$(call cmd,cc_gcov_c)

$(obj)%.c.gcov:$(obj)%.cpp $(file)
	@$(call cmd,cc_gcov_c)
