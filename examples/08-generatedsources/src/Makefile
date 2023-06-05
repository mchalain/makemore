LEX:=$(LEX) -Cf

hostbin-y+=generator

bin-y+=wc
wc_SOURCES+=wc4.l

bin-y+=rpcalc
rpcalc_SOURCES+=rpcalc.y
rpcalc_LIBS+=m

bin-y+=test
test_GENERATED+=test.c

$(objdir)test.c: $(hostobjdir)generator
	$(hostobjdir)generator > $@

data-y+=Changelog
Changelog_GENERATED+=Changelog

$(objdir)Changelog:
	git log > $@
