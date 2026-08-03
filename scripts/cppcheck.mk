CPPCHECK_TOOL=cppcheck
export CPPCHECK

ifeq (1,$(CPPCHECK))
cppcheck-target=$(filter %.i,$(objs-target:%.o=%.i))
$(filter %.o,$(objs-target)): $(cppcheck-target)
objs-target+=$(cppcheck-target)

quiet_cmd_cppcheck_c=CCHECK $*
 cmd_cppcheck_c=$(TARGETCC) -E $(CFLAGS) $(INTERN_CFLAGS) $(SYSROOT_CFLAGS) $($*_CFLAGS) -c -o $(@:.o=.i) $< && \
	$(CPPCHECK_TOOL) --enable=all --inconclusive --language=c $(@:.o=.i)
quiet_cmd_cppcheck_cpp=CCHECK $*
 cmd_cppcheck_cpp=$(TARGETCXX) $(CXXFLAGS) $(CFLAGS) $(INTERN_CFLAGS) $(SYSROOT_CFLAGS) $($*_CXXFLAGS) $($*_CFLAGS) -c -o $@ $< && \
	$(CPPCHECK_TOOL) --enable=all --inconclusive $@

$(objdir)%.i:%.c
	$(Q)$(call cmd,cppcheck_c)
$(objdir)%.i:$(objdir)%.c
	$(Q)$(call cmd,cppcheck_c)

$(objdir)%.i:%.cpp
	$(Q)$(call cmd,cppcheck_cpp)
$(objdir)%.i:$(objdir)%.cpp
	$(Q)$(call cmd,cppcheck_cpp)

$(hostobjdir)%.i:%.c
	$(Q)$(call cmd,cppcheck_c)
$(hostbjdir)%.i:$(hostobjdir)%.c
	$(Q)$(call cmd,cppcheck_c)

$(hostobjdir)%.i:%.cpp
	$(Q)$(call cmd,cppcheck_cpp)
$(hostobjdir)%.i:$(hostobjdir)%.cpp
	$(Q)$(call cmd,cppcheck_cpp)
endif

.PHONY: cppcheck
cppcheck: CPPCHECK=1
cppcheck: all
