# Dependencies
## Library dependencies
*Makemore* is able to check the availability of a libraries with the *pkg-config* tool.
It uses this tools to retrieve the build flags (CFLAGS, CXXFLAGS and LDFLAGS) and even checks the version of the library.

The binaries' rule uses the *<binary>_LIBS* variable to append the requested libraries. To use *pkg-config* the binaries' rule must replace this variable with *<binary>\_LIBRARY*.

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib
```

The entries of *<binary>\_LIBRARY* must be the package's name and not the library name. If the package doesn't exist, the value of the variable is appended to the *<binary>\_LIBS* variable.

### Version checking
The project may add a version for each entries of the *<binary>\_LIBRARY* variable. The version must follow the package's name inside {}.

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{1.2.11}
```

The requested version may be upto or over a value with the use of the minus character:

for at least the version
```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{1.2.-}
```

for no newer version
```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{-1.2.}
```

The *make* command accepts a special target *check* to do this checking:

```bash
$ make check
  SUBDIR lib/Makefile
  SUBDIR src/Makefile
  SUBDIR foo.mk
  CHECK zlib{-1.2}
Requested 'zlib <= 1.2' but version of zlib is 1.2.11
...
```
## Library packaging
*Makemore* is able to generate an entries for the *pkg-config* tool. Like a library or binary, a *pkgconfig-y* variable needs to be appended to create a new *pc* file.
After each library of the project may be added to this package, with the *<library>\_PKGCONFIG* variable:

```Makefile
pkgconfig-y+=foo
foo_DESC="library example"

lib-y+=bar
bar_PKGCONFIG+=foo
```

The project's building generates the file *pc* file:

```bash
$ make
  SUBDIR lib/Makefile
  CC bar
  LD bar
  SUBDIR src/Makefile
  SUBDIR foo.mk
  CC foo
  LD foo
  PKGCONFIG foo
$ cat foo.pc
prefix=/usr/local
exec_prefix=${prefix}
sysconfdir=${prefix}/etc
libdir=${exec_prefix}/lib
pkglibdir=${exec_prefix}/lib/
includedir=${prefix}/include

Name: foo
Version: 0.1
Description: "library example"
Cflags: -I${includedir}
Libs: -L${libdir}  -lbar
```

