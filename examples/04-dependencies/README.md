# Dependencies

## Library dependencies

*Makemore* is able to check the availability of a libraries with the *pkg-config* tool.  
It uses this tools to retrieve the build flags
(**CFLAGS**, **CXXFLAGS** and **LDFLAGS**).

To use *pkg-config* the binaries' rule must set *<binary>\_LIBRARY* variable with the package name of the external library.

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib
```

**Note**: The entries of *<binary>\_LIBRARY* must be the package's name and not the library name.  
**Note**: The binaries' rule uses the *<binary>_LIBS* variable to append the requested libraries without checking.
**Note**: If a internal library provide its pc file inside the same directory, the binaries may use it too.

### Library version

The project may add a version for each entries of the *<binary>\_LIBRARY* variable.
The version must follow the package's name inside {}.

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{1.2.11}
```

The `-` indicates the rule to apply to the checking.
If the version has to be up a fix value the `-` must be in prefix of the version:

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{-1.2.}
```

If the version has to be at least a fix value the `-` must be in suffix of the version:

```Makefile
bin-y+=foo
foo_LIBRARY+=zlib{1.2.-}
```

### Library checking

The *make* command accepts a special target *check* to do the checking of all external libraries:

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

The entries are:

 * *pkgconfig-y+=<pcname>* : generate libmylib.pc and install to $(libdir)/pkg-config/ directory :
 * *<pcname>_DESC="my library description"* : a string to describe the library into pkgconfig file :
 * *<pcname>_LIBS+=<library>* : append a library into the *<pcname>.pc.in* file :
 * *<library>_PKGCONFIG+=<pcname>* : append a library into the *<pcname>.pc.in* file :

A *<libmylib>.pc.in* may be available for special configuration otherwise *Makemore* generates this file first.

```Makefile
pkgconfig-y+=foo
foo_DESC="library example"

lib-y+=bar
bar_PKGCONFIG+=foo

lib-y+=bar2
foo_LIBS+=bar2
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
**Note**: some time the pkgconfig file for *mylib* may be named *mylib,pc* or *libmylib.pc*. The both cases are supported.

