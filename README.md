makemore
========

Makefile scripts to build your projects.  
  
scripts.mk is a makefile to include inside your main Makefile of your project.  
After you have just to add new makefile for each binary that you want to build.  

Create simple binaries
----------------------
  
### create the "main" application with the file main.c:
*Makefile*:  
> ```
bin-y+=main  
include scripts.mk  
```  

call  

> ```
 $: make  
  CC main  
  LD main  
 $: make install  
  INSTALL main  
 $: make distclean  
  CLEAN main.o  
  CLEAN main  
```  
 
### create the "test" library with the file test.c:
*Makefile*:  
> ```
lib-y+=test  
include scripts.mk
```  

### create the static "test" library with the file test.c:
*Makefile*:  
> ```
slib-y+=test  
include scripts.mk
```  
 
Create complexe binaries
------------------------
  
### create the "main" application with the file main.c and test.c:

*Makefile*:  
> ```
bin-y+=main  
main_SOURCES:=main.c test.c  
include scripts.mk  
```  
  
call  
>   ```
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
  
### create the "main" application and link with libm:
*Makefile*:  
> ```
 bin-y+=main  
 main_LIBRARY:=m  
 include scripts.mk
```  

### create the "main" application with compiler flags:
*Makefile*:  
> ```
 bin-y+=main  
 main_CFLAGS:=-g -DTEST  
 main_LDFLAGS:=-L../test  
 include scripts.mk
```  

### create the main application with source files into src directory:
*Makefile*:  
> ```
subdir-y+=src  
include scripts.mk
```  
  
*src/Makefile*:  
> ```
bin-y+=main  
main_SOURCES:=main.c test.c
```  
  
another way to do the same thing:  
  
*Makefile*:  
> ```
include scripts.mk  
all:  
	make $(build)=src/main.mk  
```  
  
*src/main.mk*:  
> ```
bin-y+=main  
main_SOURCES:=main.c test.c  
```  

Configure your project
----------------------
You can add a configuration file to your project to define some variables availables inside the Makefile and inside your source code.  
Example you don't want to build some part of code and for that you decide to define `CONFIG_NO_BUILD` to `n`.  
To do that you can create a `config` file with:  
*config*:  
> ```
CONFIG_NO_BUILD=n
```  

After you have to define the name of your configuration file into your main Makefile like :

*Makefile*:  
> ```
CONFIG=config
bin-y+=main
lib-$(CONFIG_NO_BUILD)+=test  
include scripts.mk
```  

or to exclude some source file to the build  

*Makefile*:  
> ```
CONFIG=config
bin-y+=main
main_SOURCES:=main.c
ifeq ($(CONFIG_TEST),y)  
main_SOURCES+=test.c  
main_CFLAGS+=-DTEST  
endif  
include scripts.mk
```  
  
or
*Makefile*:  
> ```
CONFIG=config
bin-y+=main
main_SOURCES:=main.c
main_SOURCES-$(CONFIG_TEST):=test.c
test_CFLAGS+=-DTEST  
include scripts.mk
```  
  
Note the difference between the both solutions:
 * first the CFLAGS is associated to the binary : main_CFLAGS.
 * second the CFLAGS is associated to the source file : test_CFLAGS.


During the build step, `makemore` generates a `$(CONFIG).h` file which will contains the definition of your configuration.  
In this example `makemore` generates `config.h` which contains

*config.h*:  
> ```
\#define CONFIG_NO_BUILD n
```  


Build your project outside the source tree  
------------------------------------------
Your main Makefile has to retrieve the `scripts.mk` file :  
 * A solution is to copy this file into the build directory.  
 * Another solution is to modify your Makefile like this:

*Makefile*:  
> ```
srcdir=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))  
#  
bin-y+=main  
include $(srcdir)/scripts.mk  
```  
  
call  
> ```
$ mkdir obj  
$ cd obj  
$ make -f ../Makefile
...
```  

Install your project  
--------------------
The normal installation is localized to `prefix=/usr/local` with :  
 * binary into `$(prefix)/bin`
 * library into `$(prefix)/lib`
 * modules into `$(prefix)/lib/$(package_name)`
 * data into `$(prefix)/share/$(package_name)`
   

To change the installation you can modify some conventional variables into your Makefile  

*Makefile*:  
> ```
package_name=main  
prefix=/usr  
libdir=$(prefix)/lib  
datadir=/etc  
include scripts.mk  
all:  
	make $(build)=src/main.mk  
```  
To package the binary, it is possible to modify the installation directory with a prefixing destination directory

	make DESTDIR=/my/path/to/package install

## create a full project:
*Makefile*:  
> ```
include scripts.mk  
all:  
	make $(build)=src/main.mk  
	make $(build)=data/conf.mk  
```  
  
*src/main.mk*:  
> ```
subdir+=lib/test.mk  
bin-y+=main  
main_SOURCES:=main.c
main_LIBRARY:=test  
```  
  
*src/lib/test.mk*:  
> ```
lib-y+=test  
test_SOURCES:=test.c
```  
   
*data/conf.mk*:  
> ```
data-y+=main.conf  
```  
   
call  
> ```  
$ mkdir  obj
$ cd  obj
$ make -f ../Makefile  
make[1]: enter "../obj/ "  
make[2]: enter "../obj/ "  
 CC test  
 LD libtest  
make[2]: exit "../obj/ "  
 CC main  
 LD main  
make[1]: exit "../obj/ "  
$ make -f ../Makefile install  
make[1]: enter "../obj/ "  
make[2]: enter "../obj/ "  
 INSTALL libtest  
make[2]: exit "../obj/ "  
 INSTALL main  
make[1]: exit "../obj/ "  
make[1]: enter "../obj/ "  
 INSTALL main.conf
make[1]: exit "../obj/ "  
```  
