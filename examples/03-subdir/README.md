# Sub-directories management
For a complex project is often necessary to manage different directories.
*Makemore* doesn't force any kind of hierarchy in the directories, but the *Makefile* must checks the order of the entries and the search pathes for header files and libraries.

## Add a subdirectory
Like *bin-y*, *Makemore* uses a variable to append the directories to parse. The big difference between *Makemore* and the *Linux Kernel Build System* is the rule to parse the directories.
Where *Linux Kernel* parse all the directories at the first call of *make*, *Makemore* call *make* for each directories. The building start may be faster for *Makemore* but some conveniences
exist to write the dependencies between source codes.

```Makefile
package=helloworld
version=0.2

include scripts.mk

subdir-y+=lib
subdir-y+=src
```

The directories are parsed in the same order than the list. *Makemore* reads the *Makefile* available in each directory, or stop in error if it doesn't exist.

## Add a specific *Makefile*
For some reason, it is useful to dispatch the build rules in different files. As only one *Makefile* must exist in one directory, *Makemore* accept a fileś path instead a directory path.

```Makefile
subdir-y+=foo.mk
```

## Build out of the tree
Using directories for dispatching the code, may allow some troubles.
The first directory may contain a library and the second may contain a binary which uses the first libary, like our example.

If the project is built out of the tree with the variable *BUILDDIR*, the binary should not find the library during the linking.

The first solution is to use the *builddir* variable inside the LDFLAGS of the binary:

```Makefile
bin-y+=foo
foo_LDFLAGS+=-L$(builddir)lib
```

Another way is to build the binary from the library. Out example uses this solution:

*lib/Makefile* :
```Makefile
subdir-y+=bar.mk
subdir-y+=../src/foo.mk
```

*lib/bar.mk* :
```Makefile
lib-y+=bar
```

*src/foo.mk* :
```Makefile
bin-y+=foo
foo_LIBS+=bar
```
