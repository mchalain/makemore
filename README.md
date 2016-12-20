makemore
========

Makefile scripts to build your projects.  
  
scripts.mk is a makefile to include inside your main "Makefile" of your project.  
After that, you just have to insert the name of your binaries and the file names
of your code source.

Create simple binaries
----------------------
  
### create a "main" application with a single file "main.c":
*Makefile*:  
```
bin-y+=main  
include scripts.mk  
```

The command lines to call are: 

	$: make  
	  CC main  
	  LD main  
	$: make install  
	  INSTALL main  
	$: make distclean  
	  CLEAN main.o  
	  CLEAN main  

 
### create a "test" library with the file "test.c":
*Makefile*:  
```
lib-y+=test  
include scripts.mk
```

### create the static "test" library with the file test.c:
*Makefile*:  
```
slib-y+=test  
include scripts.mk
```

----------

Create complexes binaries
------------------------
  
### create a binary with several source files
To use more than one file for your source code, you must define the list
of files for your binary. That list is a variable build with the name of
your binary and the suffix `_SOURCES`.

*Makefile*:  
```
include scripts.mk  
bin-y+=main  
main_SOURCES:=main.c test.c  
```

call  

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
  
### build more than one binary
It is possible to build several binaries of the same type.
*Makefile*:  
```
 bin-y+=main1 main2  
 main1_SOURCES:=main.c test1.c  
 main2_SOURCES:=main.c test2.c
 include scripts.mk
```
  

### link with an external library and add compiler flags
Makemore manages several variables to complete your setup.

To link the "main" application to the mathematics library "m",
you must define a new variable specific to your binary:

*Makefile*:  
```
 bin-y+=main  
 main_LIBRARY:=m  
 include scripts.mk
```

To call the compiler with CFLAGS and LDFLAGS:

*Makefile*:  
```
 CFLAGS+=-g
 lib-y:=test
 test_SOURCES=test/test.c
 bin-y+=main  
 main_CFLAGS:=-DTEST  
 main_LDFLAGS:=-Ltest  
 main_LIBRARY+=test
 include scripts.mk
```

### manage dispatched files into different directories
Makemore can manage your project into several directories. Each directory
can contain its own "Makefile" and "script.mk" may be included only
in the main one.

*Makefile*:  
```
include scripts.mk
subdir-y+=src  
```

*src/Makefile*:  
```
bin-y+=main  
main_SOURCES:=main.c test.c
```  
  
another way to do the same thing:  
  
*Makefile*:  
```
include scripts.mk  
all:  
	make $(build)=src/main.mk  
```  
  
*src/main.mk*:  
```
bin-y+=main  
main_SOURCES:=main.c test.c  
```  


----------
Configure your project
----------------------
It is possible to define some variables to manage the build.
The variables will allow to build or not some tools or append files to the binary,
either add some build flags.

### the configuration variables
The variables take the value of `y` or `n`, and may append to the end of the build
variables.

*examples*:
```
CONFIG_TEST:=y
bin-y+=main
main_SOURCES:=main.c
main_SOURCES-$(CONFIG_TEST)+=test.c  
main_CFLAGS-$(CONFIG_TEST)+=-DTEST  
```  

This variables may be included into a configuration file of your project.  
To do that you can create a `config` file into the same directory of your main Makefile with:  
*config*:  
```
CONFIG_TEST=n
```  

*Makefile*:  
``` Makefile
bin-y+=main
lib-$(CONFIG_TEST)+=test  
main_LIBRARY-$(CONFIG_TEST)+=test  
include scripts.mk
```  

### rename the configuration file
To change the name of the configuration file is possible to give the name with
the `CONFIG` variable. Two ways are allowed to do that:

*Makefile*:  
``` 
CONFIG:=myconfig
bin-y+=main
lib-$(CONFIG_TEST)+=test  
main_LIBRARY-$(CONFIG_TEST)+=test  
include scripts.mk
```  
or on the command line:

	make CONFIG=myconfig

### The capabilities are many

*Add macro for a specific configuration*:
```
bin-y+=main  
main_SOURCES:=main.c  
main_CFLAGS-$(CONFIG_TEST)+=-DTEST  
include scripts.mk  
```  
*Add a source file to the project* (*):
```  
bin-y+=main
main_SOURCES:=main.c
main_CFLAGS-$(CONFIG_TEST)+=-DTEST 
main_SOURCES-$(CONFIG_TEST)+=test.c
include scripts.mk
```  

*Add a library and all elements for this library*:  
```  
bin-y+=main
main_SOURCES:=main.c
main_CFLAGS-$(CONFIG_X264)+=-DX264
main_LIBRARY-$(CONFIG_X264)+=x264
main_LDFLAGS-$(CONFIG_X264)+=-L/usr/local/lib
include scripts.mk
```  

*Add flag for a specific file* (*):  
```  Makefile
bin-y+=main
main_SOURCES:=main.c
main_SOURCES-$(CONFIG_TEST)+=test.c  
test_CFLAGS+=-DTEST  
include scripts.mk
```  
  
(*)Note the difference between the both solutions:
 * first the CFLAGS is associated to the binary : main_CFLAGS.
 * second the CFLAGS is associated to the source file : test_CFLAGS.

### retrieve the configuration in the source files
During the build step, `makemore` generates a `$(CONFIG).h` file
which will contains the definition of your configuration. This file
may be included in your source code to manage the parts to build.
In this example `makemore` generates `config.h` which contains

*config.h*:  
``` C
#define CONFIG_TEST n
#define CONFIG_X264 y
#define CONFIG_X265 n
```  


----------
Manage the dependances of external libraries
--------------------------------------------
### retrieve the compiler flags for each external library
Makemore uses `pkg-config` to retrieve information about your each library linked to your binary.
If you append a library, the `CFLAGS` and the `LDFLAGS` will be automatically updates with `pkg-config` result.

*Makefile*:  
```
bin-y+=main
main_SOURCES:=main.c
main_LIBRARY-$(CONFIG_X264)+=x264
include scripts.mk
```  
  
If `libx264` is installed into "/usr/local/", the object will be create with the following command line:

	gcc -c -I/usr/local/include -o main.o main.c

and the link:

	gcc -L/usr/local/lib -lpthread -o main main.o -lx264


### check the version of each external library
Another capability of Makemore is to check the version of the libraries
with `pkg-config`

*Makefile*:  
```
bin-y+=main
main_SOURCES:=main.c
main_LIBRARY-$(CONFIG_X264)+=x264{0.125.x-}
main_LIBRARY-$(CONFIG_AVCODEC)+=avcodec{-54.23.100}
include scripts.mk
```  

The `-` indicates the rule to apply to the checking.
If the version has to be up a fix value the `-` must be in prefix of the version:

```
avcodec{-54.23.100}
```  

If the version has to be at least a fix value the `-` must be in suffix of the version:

```
x264{0.125.x-}
```  

If a specific version is required, the value must be indicate alone.

The checking is not required and has to be call by the user with a command:


	$ make check


----------
Build your project outside the source tree  
------------------------------------------
the `builddir` variable may define the results' directory of  the build.
The variable may be defined during the call or into the main `Makefile`.

call  :   

	$ make builddir=build
	...

*Makefile*:  
```
builddir=.libs
include scripts.mk  
lib-y+=mylib  
```  
It may be interesting to mix the use of the `builddir` and the cross compilation.

	$ make builddir=arm CROSS_COMPILE=arm-linux-gnuebaihf-
	$ make builddir=x86_64

----------
Install your project  
--------------------
The default installation uses the path `prefix=/usr/local` and modify the other paths with :  

 - binary into `$(prefix)/bin`  
 - library into `$(prefix)/lib` 
 - modules into `$(prefix)/lib/$(package_name)` 
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

	make DESTDIR=/my/path/to/package install


