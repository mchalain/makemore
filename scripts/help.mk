help_more: _help_entries_main $(HELP_ENTRIES)
	@

_help_entries_main:
	@echo "Makefile entries may be:"
	@echo " package="
	@echo " version="
	@echo " bin-y+="
	@echo " sbin-y+="
	@echo " lib-y+="
	@echo " slib-y+="
	@echo " hostbin-y+="
	@echo " hostslib-y+="
	@echo " modules-y+="
	@echo " subdir-y+="
	@echo " include-y+="
	@echo " pkgconfig-y+="
	@echo " sysconf-y+="
	@echo " data-y+="
	@echo " doc-y+="
	@echo " <target>_SOURCES+=<*.c|*.cpp|*.s|*.y|*.l|all <target>_GENERATED file>"
	@echo " <target>_CFLAGS+="
	@echo " <target>_CXXFLAGS+="
	@echo " <target>_LDFLAGS+="
	@echo " <target>_LIBS+="
	@echo " <target>_LIBRARY+=<pkgconfig file without pc extension>"
	@echo " <target>_HEADERS+="
	@echo " <target>_GENERATED+="
	@echo " <target>_CONFIGURE+="
	@echo " <target>_INSTALL+=<directory path|libexec for binary>"

_help_options_more:
	@echo " make help_more : display more help"
	@echo "  options: "
	@echo ""

