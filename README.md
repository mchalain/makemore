makemore
========

Makefile scripts to build your projects.

**scripts.mk** is a makefile to include in the main "Makefile" of your project.
You just have to declare your binaries and their source files, after Makemore does the rest and more.

Makemore support C, C++, Qt applications, libraries and dynamic modules.

Content:
-------

1. [Create a binary](#binary)
    1. [Simple application with one source file](#application_simple)
    2. [Application with several source files](#application_files)
    3. [Libraries](#libraries)
2. [Complexe project](#project)
    1. [Library linking](#linking)
    2. [Several binaries](#several_binaries)
    3. [Files dispatching](#submakefile)
3. [Project Configuration](#configuration)
    1. [Configuration variables](#confvars)
    2.

List of entries:
---------------

1. [bin-y](#application_simple): application binary installed into *bindir*.
2. [lib-y](#libraries): shared library installed into *libdir*.
2. [slib-y](#libraries): static library.
2. [modules-y](#libraries): dynamic module installed into *pkglibdir*.
1. [hostbin-y](#crosscompile): application binary for the build machine, not installed.
2. [subdir-y](#submakefile): sub directory or sub makefile.
3. [include-y](#installation): header file to install with library into *includedir*.
5. [pkgconfig-y](#pkgconfig): generic pkgconfig to install into *libdir*/pkgconfig.
3. [data-y](#installation): static file to install into *datadir*.
3. [sysconfdir-y](#installation): configuration file to install into *sysconfdir*.
3. [download-y](#download): download file.
4. [gitclone-y](#download): git repository.
5. [hook-*-y](#hooks): Makefile target to call after *build*, *hostbuild*, *install*, *clean*.

List of variables:
-----------------

1. [\*_SOURCES](#application_files): source files for *bin-y*, *lib-y*, *slib-y* or *modules-y*.
2. [\*_LIBRARY](#linking): libraries to link to the binary.
3. [\*_LIBS](#linking): libraries to link to the binary.
3. [\*_CFLAGS](#linking): compiler options for the binary.
3. [\*_LDFLAGS](#linking): linker options for the binary.
3. [\*_PKGCONFIG](#pkgconfig): library pkgconfig file.
4. [DEBUG](#extention): force the debug flags on the compiler.
4. [CROSS_COMPILE](#crosscompile): toolchain prefix for cross-compilation.
5. [SYSROOT](#crosscompile): sysroot directory to use with the binaries' compiler.
5. [DESTDIR](#installation): prefix directory for installation.
6. [DEVINSTALL](#installation): force the header files, static libraries installation.

# Create a binary {#binary}

## Simple application with one source file {#application_simple}
The simplest way is to have a C or C++ file with all code.
The application will have the same name of the file.

*Makefile*:
```Makefile
include scripts.mk

bin-y+=main
```

The command lines to call are:
```shell
$: make
  CC main
  LD main
$: make install
  INSTALL main
$: make distclean
  CLEAN main.o
  CLEAN main
```

## Application with several source files {#application_files}
To use more than one file for your source code, you must define the list
of files for your binary. That list is a variable build with the name of
your binary and the suffix `_SOURCES`.

*Makefile*:
```Makefile
include scripts.mk

bin-y+=main
main_SOURCES:=main.c test.c
```

```shell
$: make
  CC main
  CC test
  LD main
$: make install
  INSTALL main
$: make distclean
  CLEAN main.o
  CLEAN test.o
  CLEAN main
```

## Libraries {#libraries}
Each kind of library uses the same syntax from the binary. Only the entry point change and the target installation.

 - shared libraries use **lib-y** and are installed into **libdir** directory
 - static libraries use **slib-y** and not installed
 - dynamic modules use **modules-y**  and are installed into **pkglibdir** directory

*Makefile*:
```Makefile
include scripts.mk

lib-y+=myshared
myshared_SOURCES=test.c
```

*Makefile*:
```
include scripts.mk

slib-y+=mystatic
mystatic_SOURCES=test.c
```
# Complexe project {#project}
## Library linking {#linking}
Makemore allows to link your binaries to the system libraries or your own libraries.
Like the **\*_SOURCES**, you can define several variables to manage the target build:

- **\*_LIBRARY** to link your binary to another library (1)(2).
- **\*_LIBS** to link your binary to another library.
- **\*_CFLAGS** to change the arguments of the compiler.
- **\*_LDFLAGS** to change the arguments of the linker.

(1) the **\*_CFLAGS** and the **\*_LDFLAGS** is updated if the pkg-config file (<libname>.pc)
exists.
(2) the entries of **\*_LIBRARY** may contain a version for the checking:

Example to link the application with libm the mathematic library and
glib-2 with the version 0.6400.6:
```Makefile
 include scripts.mk
 bin-y+=main
 main_LIBS+=m
 main_LIBRARY+=glib-2.0{0.6400.6}
```

## Several binaries {#several_binaries}
Your *Makefile* may contain more than one target. Each target may define its own rules as previously see.

This example define a generic CFLAGS for all binaries, after 2 binaries are built:

- the *libtest.so* library with the file *test/test.c*
- the *main* application with the file *main.c*. This application defines the macro *TEST* and it is linked to the *libtest.so* library.

```Makefile
 include scripts.mk
 CFLAGS+=-g
 lib-y:=foo
 test_SOURCES=lib/foo.c

 bin-y+=bar
 bar_CFLAGS+=-DTEST
 bar_CFLAGS+=-Ilib
 bar_LDFLAGS:=-Llib.c
 bar_LIBS+=foo

 bin-$(TESTS)+=test
 test_SOURCES+=testrun.c
 test_SOURCES+=test1.c
 test_SOURCES+=test2.c
 test_LIBS+=foo
```

## Files dispatching {#submakefile}
Makemore can manage your project into several directories. Each directory
can contain its own "Makefile" and "script.mk" may be included only
in the main one.

*Makefile*:
```Makefile
include scripts.mk
subdir-y+=src
subdir-y+=lib
```

*src/Makefile*:
```Makefile
bin-y+=bar
bar_SOURCES+=main.c bar.c
bar_LIBS+=foo
bar_CFLAGS+=-DTEST
bar_CFLAGS+=-I../lib
bar_LDFLAGS:=-L../lib
```

*lib/Makefile*:
```Makefile
lib-y+=foo
foo_SOURCES:=foo.c
```

The **subdir-y** entries may contain a list of directories or files. Only **\*.mk** or **Makefile** are allowed.

This example merge the project files into the same directory but dispatch the build rules in different Makefile:

*Makefile*:
```Makefile
include scripts.mk
subdir-y+=src/main.mk
subdir-y+=src/test.mk
```

*src/main.mk*:
```Makefile
bin-y+=bar
bar_SOURCES+=main.c bar.c
bar_LIBS+=foo
bar_CFLAGS+=-DTEST
```

*src/test.mk*:
```Makefile
lib-y+=foo
foo_SOURCES:=foo.c
```

# Project Configuration {#configuration}

It is possible to define some variables to manage the build.
The variables will allow to build or not some tools or append files to the binary,
either add some build flags.

The variables take the values:

* a boolean value `y` or `n`
* a numerical value
* a string.

## Local configuration

The variables may be set inside a Makefile to be use in the same
Makefile or theirs sub-Makefiles:

```Makefile
CONFIG_TEST=y
bin-y+=main
main_SOURCES:=main.c
main_SOURCES-$(CONFIG_TEST)+=test.c
main_CFLAGS-$(CONFIG_TEST)+=-DTEST
```

## Default configuration file

This variables may be included into a configuration file of your project.
To do that you can modify the `defconfig` file into the same directory
of your main Makefile with:

*defconfig*:
```
FOO=y
TEST=n
MYSTRING="helloworld"
```

*Makefile*:
```Makefile
include scripts.mk
bin-y+=bar
lib-$(FOO)+=foo
bar_LIBS-$(FOO)+=foo
bar_CFLAGS-$(TEST)+=-DTEST -DMYSTRING2=$(MYSTRING)
```
All variables must be defined inside the *defconfig* file. This one will
be used by Makmore to generate or to update the *.config* file.

## Configuration directory
The project may contain several configuration files, and all have to
stored into the *configs* folder of your project. Each one must be named
*\*_defconfig*.

```bash
$ make mytest_defconfig
$ make
$ make DESTDIR=$PWD/tempo install
```

Makemore searchs the file into the *configs* folder, merges with the
*defconfig* to check the new entries, and create the *.config* file.

## rename the configuration file
It is possible to change the name of the configuration file, instead to
use to use the *.config* file. The `CONFIG` variable may be modified
inside the main *Makefile*:

```Makefile
CONFIG:=myconfig
include scripts.mk
bin-y+=main
lib-$(CONFIG_TEST)+=test
main_LIBS-$(CONFIG_TEST)+=test
```

or on the command line:

```bash
$ make CONFIG=myconfig
```

## Configuration possibilities are many

### Add macro for a specific configuration:

```Makefile
include scripts.mk
bin-y+=main
main_SOURCES:=main.c
main_CFLAGS-$(CONFIG_TEST)+=-DTEST
```

### Add a source file to the project [*](#Note):

```Makefile
include scripts.mk
bin-y+=main
main_SOURCES:=main.c
main_CFLAGS-$(CONFIG_TEST)+=-DTEST
main_SOURCES-$(CONFIG_TEST)+=test.c
```

### Add a library and all elements for this library:

```Makefile
bin-y+=main
main_SOURCES:=main.c
main_CFLAGS-$(CONFIG_X264)+=-DX264
main_LIBRARY-$(CONFIG_X264)+=x264
main_LDFLAGS-$(CONFIG_X264)+=-L/usr/local/lib
include scripts.mk
```

### Add flag for a specific file [*](#Note):

```Makefile
bin-y+=main
main_SOURCES:=main.c
main_SOURCES-$(CONFIG_TEST)+=test.c
test_CFLAGS+=-DTEST
include scripts.mk
```

 {#Note})Note the difference between the both solutions:
  * first the CFLAGS is associated to the binary : main_CFLAGS.
  * second the CFLAGS is associated to the source file : test_CFLAGS.

## Use the configuration in the source files

During the build step, `makemore` generates a `config.h` file
which will contains the definition of your configuration. This file
is **automaticly** included in your source code.

```config
CONFIG_TEST=n
CONFIG_X264=y
CONFIG_X265=n
```

gererate:

```C
#define CONFIG_TEST n
#define CONFIG_X264 y
#define CONFIG_X265 n
```

# Dependancies of external libraries management:

## retrieve the compiler flags for each external library
Makemore uses `pkg-config` to retrieve information about your each
library added to the **LIBRARY** variable. The **CFLAGS** and the
**LDFLAGS** will be automatically updates with `pkg-config` result.
If the library is not found then only **LDFLAGS** is updated to add the
library.

```Makefile
include scripts.mk
bin-y+=main
main_SOURCES:=main.c
main_LIBRARY-$(CONFIG_X264)+=x264
```

If `libx264` is installed into "/usr/local/", the object will be create
with the following command line:

```bash
 $ gcc -c -I/usr/local/include -o main.o main.c
 $ gcc -L/usr/local/lib -lpthread -o main main.o -lx264
```

## check the version of an external library
Another Makemore feature is to check the version of the libraries
with `pkg-config`

```Makefile
include scripts.mk
bin-y+=main
main_SOURCES:=main.c
main_LIBRARY-$(CONFIG_X264)+=x264{0.125.x-}
main_LIBRARY-$(CONFIG_AVCODEC)+=avcodec{-54.23.100}
```

The `-` indicates the rule to apply to the checking.
If the version has to be up a fix value the `-` must be in prefix of the version:

```Makefile
main_LIBRARY-$(CONFIG_AVCODEC)+=avcodec{-54.23.100}
```

If the version has to be at least a fix value the `-` must be in suffix of the version:

```Makefile
main_LIBRARY-$(CONFIG_X264)+=x264{0.125.x-}
```

If a specific version is required, the value must be indicate alone.

The checking is not required and has to be call by the user with a command:

```bash
$ make check
```

# Build your project outside the source tree

The `builddir` variable may define the results' directory of  the build.
The variable may be defined during the call:

```bash
 $ make builddir=build
 ...
```

or into the main `Makefile`

```Makefile
builddir=.libs
include scripts.mk
lib-y+=mylib
```

# Cross-compilation

## Build variables
Makemore uses the standard variables for build:

 1) **CC**
 2) **LD**
 3) **CFLAGS**
 4) **LDFLAGS**
 5) **CROSS_COMPILE**
 6) **SYSROOT**

A simple way may be to set the variables 1), 2), 3), 4) with the
compilator version of the target. Or to set the variable 5) with
the target compilor prefix.

```bash
$ make CROSS_COMPILE=aarch64-linux-gnu-
```

The variable 6) is useful to change the root directory to search the
headers and the libraries during the build.

## Mix host and target binaries

Some projects may need to build a tool to continue the build. During
a cross compilation is necessary to separate.

The host binaries may be identified by the *hostbin-y* entry.

```Makefile
DEFAULT_ADDRESS=192.168.1.254
DEFAULT_PORT=8080
bin-y+=server
server_SOURCES+=main.c
server_SOURCES+=server.c

hostbin-y+=clienttest
clienttest_SOURCES+=test.c
```

#Install your project

The default installation uses the path `prefix=/usr/local` and modify the other paths with :

 - exec_prefix is $(prefix) by default
 - binary into `$(exec_prefix)/bin`
 - library into `$(exec_prefix)/lib`
 - modules into `$(exec_prefix)/lib/$(package_name)`
 - data into  `$(prefix)/share/$(package_name)`

To change the installation you can modify some conventional variables into your configuration file

*config*:
```
package_name=myproject
prefix=/usr
libdir=$(prefix)/lib
datadir=/etc
```

To package the binary, it is possible to modify the installation directory with a prefixing destination directory

```bash
$ make DESTDIR=/my/path/to/package install
```
