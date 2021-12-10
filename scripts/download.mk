#download-target+=$(foreach dl,$(download-y),$(DL)/$(dl)/$($(dl)_SOURCE))
$(foreach dl,$(download-y),$(if $($(dl)_SOURCE),, \
	$(eval $(dl)_SOURCE:=$(notdir $($(dl)_SITE))) \
	$(eval $(dl)_SITE:=$(dir $($(dl)_SITE)))))
$(foreach dl,$(download-y),$(eval $($(dl)_SOURCE)_URL=$($(dl)_SITE)$($(dl)_SOURCE:%=/%)))
$(foreach dl,$(download-y),$(if $(findstring .zip,$($(dl)_SOURCE)),$(eval $(dl)_SITE_METHOD:=zip)))
$(foreach dl,$(download-y),$(if $(findstring .tar,$($(dl)_SOURCE)),$(eval $(dl)_SITE_METHOD:=tar)))
$(foreach dl,$(download-y),$(eval $($(dl)_SITE_METHOD)download-target+=$(obj)/$(dl)))

###############################################################################
# Commands for download
##
DL?=$(builddir)/.dl

quiet_cmd_download=DOWNLOAD $*
define cmd_download
	echo 'wget -q -O' $(DL)/$* $($*_URL)
	wget -q -O $(DL)/$* $($*_URL)
endef

quiet_cmd_gitclone=CLONE $*
define cmd_gitclone
git clone --depth 1 $($*_SITE) $($*_VERSION:%=-b %) $@
endef

ifneq ($(download-y),)
$(shell $(MKDIR) $(DL))
endif

$(DL)/%:
	@$(call cmd,download)

.SECONDEXPANSION:
$(tardownload-target): $(obj)/%: $(DL)/$$(%_SOURCE)
	tar -xf $< -C $@
	
$(zipdownload-target): $(obj)/%: $(DL)/$$(%_SOURCE)
	unzip -o -d $@ $<

$(download-target): $(obj)/%: $(DL)/$$(%_SOURCE)
	@$(if $(findstring .zip, $($*_SOURCE)),unzip -o -d $@ $<, \
	  $(if $(findstring .tar.gz, $($*_SOURCE)),tar -xzf $< -C $@, \
	  $(MKDIR) $(dir $@) && cp $< $(dir $@)))

$(gitclone-target): %:
	@$(call cmd,gitclone)
	@ln -snf $* $(obj)/$*
