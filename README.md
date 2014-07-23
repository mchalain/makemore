makemore
========

Makefile scripts to build your projects.  
  
scripts.mk is a makefile to include inside your main Makefile of your project.  
After you have just to add new makefile for each binary that you want to build.  

Create simple binaries
----------------------
  
### create the "main" application with the file main.c:
> ##### Makefile
bin-y+=main
include scripts.mk
call  
> $: make
  CC main
  LD main
 $: make install
  INSTALL main
 $: make distclean
  CLEAN main.o
  CLEAN main
  
### create the "test" library with the file test.c:
> ##### Makefile
lib-y+=test
include scripts.mk
  
### create the static "test" library with the file test.c:
> ##### Makefile
slib-y+=test
include scripts.mk
  
Create complexe binaries
------------------------
  
### create the "main" application with the file main.c and test.c:
[Makefile]  
```
bin-y+=main  
main_SOURCES:=main.c test.c  
include scripts.mk  
```
call  
  
> $: make  
>  CC main  
>  CC test  
>  LD main  
> $: make install  
>  INSTALL main  
> $: make distclean  
>  CLEAN main.o  
>  CLEAN test.o  
>  CLEAN main  
  
### create the "main" application and link with libm:
> # Makefile
> bin-y+=main  
> main_LIBRARY:=m  
> include scripts.mk

### create the main application with source files into src directory:
> # Makefile
> subdir-y+=src
> include scripts.mk
  
> # src/Makefile
> bin-y+=main
> main_SOURCES:=main.c test.c
  
another way to do the same thing:  
  
> # Makefile
> include scripts.mk
> all:
	> make $(build)=src/main.mk
  
> # src/main.mk
> bin-y+=main
> main_SOURCES:=main.c test.c
  

### create :
