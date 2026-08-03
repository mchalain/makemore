# Libraries
## pkgconfig file generation
*Makemore* supports pkgconfig (*.pc) file for generation:

 * *pkgconfig-y+=<libmylib>* : generate libmylib.pc and install to $(libdir)/pkg-config/ directory :
 * *<libmylib>_DESC="my library description"* : a string to describe the library into pkgconfig file :
 * *<libmylib>_LIBS=<library>* : append a library into the *<libmylib>.pc.in* file :

A *<libmylib>.pc.in* may be available for special configuration or *Makemore* generates this file .
too.

# Full project
This example shows, how to create a library with all files for a good installation
## Configuration
The build tool allow several builds: dynamic library, static library, hostlibrary for cross compilationm and appliation

The flags STATIC and HOST select the rules to use. The dynamic library and the application are always built.

```shell
$ make BUILDDIR=$PWD/build STATIC=y defconfig"
```

## Build
The files generation is simple

```shell
$ cd build
$ make
```

The resulting content is:

.
├── bar.pc
├── bar.pc.in
├── config.h
├── lib
│   ├── bar.o
│   ├── libbar.a
│   └── libbar.so
├── Makefile
└── version.h

## Installation
The installation starts from the same "build" directory in this case.

```shell
$ sudo make install
```

And this will installs the following files
.
└── usr
    └── local
        ├── include
        │   └── bar.h
        └── lib
            └── x86\_64-linux-gnu
                ├── libbar.a
                ├── libbar.so -> libbar.so.0
                ├── libbar.so.0 -> libbar.so.0.2
                ├── libbar.so.0.2
                └── pkgconfig
                    └── bar.pc

