# Extensions
## Installation
The extensions files must be installed in the project if needded.

## Download
This extension allows to download and extract a package or to clone a git repository.

The target must be set several variables:
```Makefile
download-y+=makemore
makemore_SITE=https://github.com/mchalain/makemore.git
makemore_SITE_METHOD=git
makemore_SOURCE=mymakemore
```

*<target>_SITE_METHOD* is required for git repository.  
*<target>_SOURCE* is optional for git repository. It contains the name
of the directory for cloning.

## Qt
The Qt extension allows to generate [Qt application](../09-qtappli/README.md).

## gcov
*gcov* is a test coverage program. The binary to test must be instrumented
first with the gcov library. This step creates new objects files.
After testing, the tool must parse the objects file to generate report files.

The first step is obtained with the *G* option of the build target.  
The second one has is own target *gcov*.

```bash
$ make G=1 BUILDDIR=build build
  CC helloworld
  LD helloworld
$ ./build/helloworld
Hello World
$ make BUILDDIR=build gcov
  GCOV helloworld
```

A third level is available to display the result into a html page:
```bash
$ make BUILDDIR=build gcovhtml
  LCOV helloworld
  GENHTML helloworld
```
