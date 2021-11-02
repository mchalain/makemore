## Qt support
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.hpp,%.moc.cpp,$(filter %.hpp,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.ui,%.ui.hpp,$(filter %.ui,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y) $(hostslib-y) $(hostbin-y), $(eval $(t)_GENERATED+=$(patsubst %.ui,%.moc.cpp,$(filter %.ui,$($(t)_QTOBJECTS) $($(t)_QTOBJECTS-y)))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_GENERATED),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CFLAGS+=$($(t)_CFLAGS)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_GENERATED),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CXXFLAGS+=$($(t)_CXXFLAGS)))))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(eval $(t)_GENERATED:=$(addprefix $(obj),$($(t)_GENERATED))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y), $(eval $(t)-objs+=$(call src2obj,$(notdir $($(t)_GENERATED)))))

target-objs+=$(foreach t, $(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$($(t)_GENERATED))

$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CFLAGS+=$($(t)_CFLAGS)))))
$(foreach t,$(slib-y) $(lib-y) $(bin-y) $(sbin-y) $(modules-y),$(foreach s, $($(t)_SOURCES),$(if $(findstring $(t),$(s)),,$(eval $(patsubst %.cpp,%,$(s))_CXXFLAGS+=$($(t)_CXXFLAGS)))))

quiet_cmd_moc_hpp=QTMOC $*
 cmd_moc_hpp=$(MOC) $(INCLUDES) $($*_MOCFLAGS) -o $@ $<
quiet_cmd_uic_hpp=QTUIC $*
 cmd_uic_hpp=$(UIC) $< > $@

$(obj)%.moc.cpp:$(obj)%.ui.hpp $(file)
	@$(call cmd,moc_hpp)

$(obj)%.moc.cpp:%.hpp $(file)
	@$(call cmd,moc_hpp)

$(obj)%.ui.hpp:%.ui $(file)
	@$(call cmd,uic_hpp)
