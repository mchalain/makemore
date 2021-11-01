#download-target+=$(foreach dl,$(download-y),$(DL)/$(dl)/$($(dl)_SOURCE))
$(foreach dl,$(download-y),$(if $(findstring git,$($(dl)_SITE_METHOD)),$(eval gitclone-target+=$(dl)),$(eval download-target+=$(dl))))

###############################################################################
# Commands for download
##
DL?=$(builddir)/.dl

quiet_cmd_download=DOWNLOAD $*
define cmd_download
	wget -q -O $(OUTPUT) $(URL)
endef

quiet_cmd_gitclone=CLONE $*
define cmd_gitclone
	$(if $(wildcard $(OUTPUT)),,git clone --depth 1 $(URL) $(VERSION) $(OUTPUT))
endef

$(DL)/:
	$(MKDIR) $@

$(download-target): %: $(DL)/
	$(eval URL=$($*_SITE)$($*_SOURCE:%=/%))
	$(eval DL=$(realpath $(DL)))
	$(eval OUTPUT=$(DL)/$(if $($*_SOURCE),$($*_SOURCE),$(notdir $($*_SITE))))
	@$(call cmd,download)
	@$(if $(findstring .zip, $($*_SOURCE)),unzip -o -d $(builddir)/$* $(OUTPUT))
	@$(if $(findstring .tar.gz, $($*_SOURCE)),tar -xzf $(OUTPUT) -C $(builddir)/$*)

$(gitclone-target): %:
	$(eval URL=$($*_SITE))
	$(eval OUTPUT=$(builddir)/$(if $($*_SOURCE),$($*_SOURCE),$*))
	$(eval VERSION=$(if $($*_VERSION),-b $($*_VERSION)))
	@$(call cmd,gitclone)

