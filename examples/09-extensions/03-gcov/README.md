# static code analysis
*Makemore* is able to use GCOV for analysing the code. To do that, it needs the gcov.mk [extension](../07-extensions/README.md).

## applications' test build
To differenciate the normal build the G variable must be set to 1 during the build:

```bash
$ make BUILDDIR=build-gcov G=1
...
$ ls build-gcov
bar.gcda  bar.gcno  barloader.gcda  barloader.gcno  barloader.o  bar.o  bar.so  foo  foo.gcda  foo.gcno  foo.o  libbar.a  libbar.so  superfoo  version.h
```

This command build the *\*.gcno* and *\*.gcda* files from the *\*_SOURCES* and *\*_GENERATED* files.

## applications' test running
GCOV needs to have filled *\*.gcda* files, and the user must run the applications' test:

```bash
$ cd build-gcov
$ LD_LIBRARY_PATH=. ./foo
...
```

## application code analysis
When the applications' test are ready, gcov may be call on every code file. *makemore* may do it easily.

```
$ make BUILDDIR=build-gcov gcov
$ ls build-gcov/gcov.info
```

## results display
The result may be used by another tool like *Clockwork* or *SonarQube*, of by *lcov*.

```bash
$ make BUILDDIR=build-gcov gcovhtml
$ firefox build-gcov/gcov_report/index.html
```
