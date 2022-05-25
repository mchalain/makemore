# Project configuration
Different kinds of configuration may be useful for a project:

 * enable the building or the installation of an object;
 * enable a feature inside the binary;
 * set the installation path;
 * set a macro value inside the code;

## Manage the features
All variables of the Makefile may ended with a *-y*, and be replaced by *-$(MYCONFIG)*.

```Makefile
package=helloworld
version=0.2

include scripts.mk

subdir-$(BUILD_LIBRARY)+=lib
subdir-y+=src
```

The configuration must be appended to the command line of the *make* to enable or disable the feature. By default the feature is disable.

```bash
$ make BUILD_LIBRARY=y
```

To have a default value to *y*, the *Makefile* is a little more complexe:

```Makefile
subdir-y$(BUILD_LIBRARY:y=)
```

## The configuration step
To set the configuration only once, *Makemore* uses a *defconfig* file. This file must be on the root of the project with the main *Makefile*.

The *defconfig* must contain all variables used inside the project and their default values.

*defconfig* :
```Makefile
BUILD_LIBRARY=y
MYMACRO="test"
```

This file will be used to generate the *.config* and *.pathcache* files, for all calls to *make*. If the *defconfig* file is available, any other step aren't accessible.

### The *configure* script
*Makemore* is available with a *configure* script. This one is able to read the *defconfig* file for generating the configuration.

The *configure* script tries to keep the format of the *autotools* and the *--help* option displaies the other options.

```bash
$ ./configure --help
./configure [options]

Configuration:
	--help			display this help and exit

Installation directories:
	--prefix=PREFIX		install architecture-independent files in PREFIX [/usr/local]
	--exec-prefix=PREFIX	install architecture-dependent files in PREFIX [$prefix]
	--bindir=DIR		user executables in DIR [$exec-prefix/bin]
	--sbindir=DIR		system admin executables in DIR [$exec-prefix/sbin]
	--sysconfdir=DIR	read-only single-machine data in DIR [$prefix/etc]
	--libdir=DIR		object code libraries in DIR [$exec-prefix/lib]
	--includedir=DIR	C header files in DIR [$prefix/include]
	--datadir=DIR		read-only architecture-independent data files in DIR[$prefix/share]
	--localstatedir=DIR	running data files in DIR[$prefix/var]

System types:
	--build=BUILD		configure for building on BUILD [guessed]
	--host=HOST		cross-compile to build programs to run on HOST [BUILD]
	--target=<host>		cross-compile to build programs to run on HOST [BUILD]
	--sysroot=DIR		cross-compiler root directory [none]
	--toolchain=DIR		cross-compiler tools path [none]

Features enabling:
	--enable-build-library	default:y

Features:
	--with-mymacro=<value>	default:"test"
```

### The *make \*defconfig* command
Another way to generate the configuration is to use the *Makefile* directly.

```bash
$ make BUILD_LIBRARY=n defconfig
```

This command will use the default configuration and the variables on the commandline to generate the configuration. After each other call to *make* wil use the same configuration.

The advantage of this way is to save different versions of configuration. *Makemore* parses a *configs/* directory on the root of the project, to find another default configuration file. The name of the file must end with *_defconfig*.

```bash
$ cat configs/onlyapp_defconfig
BUILD_LIBRARY=n
$ make onlyapp_defconfig
```

## The installation variables
### The pathes

### The target files
#### *prefix* and *exec\_prefix*
The *prefix* variable is the main entry to change the project's installation. The default value is */usr/local* and all other installation path may be built from this variable.

The *prefix* may be changed during the configuration step with the variable *PREFIX* or *prefix*. The first one is preferred, but the both are accepted.

```bash
$ make PREFIX=/usr defconfig
```

The *exec\_prefix* allows to dispatch binaries and data files into two distinguish roots. The most often the *prefix* and the *exec\_prefix* contains the same value.

To modify the value of *exec\_prefix*, only the *exec\_prefix* variable is available.

```bash
$ make PREFIX=/opt/foo exec_prefix=/usr defconfig
```

#### binaries
The *bin-y* entries are installed into *<bindir>* directory and *sbin-y* entries into *<sbindir>*.

The *<bindir>* (*<sbindir>*)is built with *<exec\_prefix*> and the string */bin/* (*/sbin/*).

This path may be changed during the configuration step with the variable *bindir*.

```bash
$ make bindir=/opt/foo/bin defconfig
```

#### libraries
The libraries installation depends on the system. *Makemore* is able to manage the default UNIX installation into *<exec\_prefix>/lib/* directory or the installation into *<exec\_prefix>/lib/<architecture>/* like the Debian like OS. For other OS the *libdir* variable needs to be set during the configuration.

```bash
$ make libdir=/usr/lib$(getconf LONG_BIT) defconfig
...
$ make
...
$ make install
...
$ ls /usr/lib64
```

#### modules
The modules may be installed everywhere, the binary loading them from a path. But the standard installation is the *pkglibdir*. Its default value is *<exec\_prefix>/lib/<package>* directory but it may be changed during the configuration step.

```bash
$ make pkglibdir=/usr/lib/x86_64-linux-gnu/gstreamer-1.0 defconfig
```

Like the libraries, *Makemore* may detect a Debian installation.
#### configuration file
The configuration file is not a binary, and a default version is often delivery with the project.

*Makemore* allows to distribute this default configuration file with the project and to install it.

```Makefile
sysconf-y+=foo.conf
```

The default path is *<prefix>/etc/* directory. But the standard path is */etc/* directory.

```bash
$ make sysconfdir=/etc defconfig
  DEFCONFIG defconfig
$ make
...
$ make DESTDIR=$PWD/tempo install
  CONFIG config.h
  VERSION version.h
  INSTALL foo.conf
  INSTALL foo
  SUBDIR lib/Makefile
  INSTALL bar
  INSTALL bar
  INSTALL bar
  SUBDIR src/Makefile
  SUBDIR foo.mk
  INSTALL foo
$ tree tempo
.
├── etc
│   └── foo.conf
└── usr
    ├── bin
    │   └── foo
    └── lib
        └── x86_64-linux-gnu
            ├── libbar.so -> libbar.so.0
            ├── libbar.so.0 -> libbar.so.0.2
            ├── libbar.so.0.2
            └── pkgconfig
                └── foo.pc

6 directories, 6 files
```

#### data files
#### documentation files

```Makefile
doc-y+=LICENCES
```

### The alias

### The installation out of the box
Only the super user *root* may install a package on the system. *Makemore* may install a project into another directory than the */* directory and keep the same tree. To do that a destination directory must be instanciate during the installation step.

```bash
$ make DESTDIR=$PWD/package install
$ ls package
 etc  usr
```

## The *config.h* file
*Makemore* generates a *config.h* and a *version.h* files on the root of the project during the first steps of the building. This files contains informations availables for the code. The configuration variables and some installation path are defined as macros.
```C
#ifndef __CONFIG_H__
#define __CONFIG_H__
#define BUILD_LIBRARY y
#define MYMACRO "test"

#define PKGLIBDIR "/usr/local/lib/foo"
#define DATADIR "/usr/local/share/foo"
#define PKG_DATADIR "/usr/local/share/foo"
#define SYSCONFDIR "/usr/local/etc"
#define LOCALSTATEDIR "/usr/local/var"

#endif
```

The files are automaticly included to the headers during the application build.

## Clean the configuration

The cleaning must remove all object files, and configuration files.
```bash
$ make distclean
  SUBDIR lib/Makefile
  CLEAN  bar.o
  CLEAN  libbar.so
  SUBDIR src/Makefile
  SUBDIR foo.mk
  CLEAN  foo.o
  CLEAN  foo
  CLEAN  .config
  CLEAN  config.h
  CLEAN  version.h
  CLEAN  .pathcache
```

After this command, a configuration step must be done before building.
