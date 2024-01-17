## Qt support
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.hpp,%.moc.cpp,$(filter %.hpp,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.ui,%.ui.hpp,$(filter %.ui,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.ui,%.moc.cpp,$(filter %.ui,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))

#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_GENERATED),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CFLAGS+=$($(t)_CFLAGS)))))
#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_GENERATED),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CXXFLAGS+=$($(t)_CXXFLAGS)))))

#$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)-objs+=$(call src2obj,$($(t)_GENERATED))))

#objs-target:=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(addprefix $(objdir),$($(t)_GENERATED))		$(addprefix $(objdir),    $($(t)-objs)))
#hostobjs-target:=$(foreach t, $(hostbin-y) $(hostslib-y),                    $(addprefix $(hostobjdir),$($(t)_GENERATED))	$(addprefix $(hostobjdir),$($(t)-objs)))

quiet_cmd_moc_hpp=QTMOC $*
 cmd_moc_hpp=$(MOC) $(INCLUDES) $($*_MOCFLAGS) -o $@ $<
quiet_cmd_uic_hpp=QTUIC $*
 cmd_uic_hpp=$(UIC) $< > $@

$(objdir)%.moc.cpp:$(obj)%.ui.hpp $(file)
	@$(call cmd,moc_hpp)

$(objdir)%.moc.cpp:%.hpp $(file)
	@$(call cmd,moc_hpp)

$(objdir)%.ui.hpp:%.ui $(file)
	@$(call cmd,uic_hpp)

_help_entries_qt:
	@echo " <target>_QTOBJECTS-y+="

_help_options_qt:
	@
