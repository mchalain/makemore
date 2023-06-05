# Generated sources
## Lex and Yacc
The two kinds of generated files come from the *lex* and *bison* tools.
*Makemore* is able to to manage this types of files directly from the
*<target>_SOURCES* variable:

```Makefile
bin-y+=wc
wc_SOURCES+=wc4.l

bin-y+=rpcalc
rpcalc_SOURCES+=rpcalc.y
rpcalc_LIBS+=m
```

## Generic rule
The project may use a code generator not supported by *Makemore*. In this
case a new variable is required to set the file name and to add the
generation's rule.

```Makefile
bin-y+=test
test_GENERATED+=test.c

test.c:
	generator $@
```

This method may be used for other kind of files

```Makefile
data-y+=Changelog
Changelog_GENERATED+=Changelog

$(objdir)Changelog:
	git log > $@
```

## Build out of directory

```shell
> make BUILDDIR=$(pwd)/build
```
