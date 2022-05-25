# Introduction
To build a C application, it is necessary to have:

 * a C Compiler and de binary Linker. For a lot of OS, GCC is the main C Compiler and Linker. Makemore is tested with GCC and a few with CLang.
 * a C library and often other libraries. For Linux a libraries' information DB is available with pkg-config. Makemore is able to check this DB to obtain the good options of the Compiler and the Linker.
 * one or more source file.
 * a name.

For a long time, a tool exist to generate binary from source, it is *make*. *GNU make* is a powerful variant of *make*

A lot of tools exist to help the writting of *Makefile*. These tools often read configuration files to generate the *Makefile*. Few of them are:

 * autotools and libtool
 * CMake
 * qmake

Other tools have there own files to describe the project and they don't need *make* for the generation. Few of them are:

 * Scons
 * Go

*Makemore* offers to help the *Makefile* writting without any tools on the computer's system. It is a script file to share with the project.

# Simple application build rules
## First Makefile
The generic *Makefile* to build a simple application may be:

```Makefile
TARGET=helloworld
OBJ=helloworld.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o $@ $^
```

This very simple *Makefile* is enought but it doesn't allow the installation, and it doesn't manage any option.

*Makemore* proposes to rewrite this file with:

```Makefile
include scripts.mk
bin-y+=helloworld
```

or to add more source files:

```Makefile
include scripts.mk

bin-y+=helloworld
helloworld_SOURCES+=helloworld.c
```

The file *scripts.mk* **must be installed** in the same directory than this *Makefile*.

## Extend the capabilities
The generic *Makefile* uses some generic variables to set some options to the Compiler and the Linker.

 * CFLAGS for the C Compiler
 * CXXFLAGS for the C++ Compiler
 * LDFLAGS for the Linker

*Makemore* uses the same names:

```Makefile
include scripts.mk

bin-y+=helloworld
helloworld_SOURCES+=helloworld.c
helloworld_CFLAGS+=-DMESSAGE=\"world\"
```

## Build and install
*Makemore* offers a full toolbox for building and installing binaries.

A step of [configuration](../05_configuration/README.md) may be prepended.

### Build the binary
*Makemore* uses standard name for the targets like *build* and *äll*.
Like a lot of *Makefile*, just a call to *make* is enought:

```bash
$ make
  CC helloworld
  LD helloworld
```

To watch the command behind the output the *V=1* option allows to be more verbose:

```bash
make _build -f /media/mch/mchalain/Projects/makemore/examples/01-simpleC/../../scripts.mk file=Makefile
  gcc -O2 -I. -DMESSAGE="helloworld"  -I/usr/local/include -c -o helloworld.o helloworld.c
  gcc -L.  -Wl,-rpath,/usr/local/lib -Wl,-rpath,/usr/local/lib/ -o helloworld helloworld.o -Wl,--start-group   -Wl,--end-group -lc
```

### Build out of source tree
To keep the source tree clean, *Makemore* alloews to build the project into an output directory:

```bash
$ make BUILDDIR=build
  CC helloworld
  LD helloworld
$ ls
build/  helloworld.c  Makefile scripts.mk
```

All generated files are in the *build* directory.


### Install the application

```bash
$ make install
  INSTALL helloworld
```

The default installation path for the application will be */usr/local/bin*.

It is possible to change the destination and to install into */usr/bin*:
```bash
$ make PREFIX=/usr install
  INSTALL helloworld
```

or into another path */opt/helloworld/apps*:
```bash
$ make bindir=/opt/helloworld/apps install
  INSTALL helloworld
```

The *install* target accepts the *S* variable to strip the binaries after the installation.
```bash
$ make bindir=/opt/helloworld/apps S=1 install
  INSTALL helloworld
  STRIP helloworld
```

### Clean the source tree
To remove the object files
```bash
$ make clean
  CLEAN  helloworld.o
  CLEAN  helloworld
```
