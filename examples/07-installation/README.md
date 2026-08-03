# Project installation
## The installation variables
*Makemore* uses several variables to set the installation path of each element. The name of each variable reuse the standard naming:

 * prefix
 * exec-prefix
 * bindir and sbindir for installing binaries
 * libdir for installing dynamic and static libraries
 * pkglibdir for installing modules
 * sysconfdir for installing configuration files

Some other may be less standard:

 * docdir for installing documentation files (like license or changelog).
 * datadir for installing data files (like databases).
 * localstatedir for running data files (like pid file).

As some values may be useful during the building, (like *sysconfdir* to search the configuration file), this variables must be set during the configuration.


This may be done directly from the *make* command:  
```bash

	$ make prefix=/usr sysconfdir=/etc localstatedir=/var defconfig
	  DEFCONFIG defconfig
```

Or from the *configure* script:  

```bash

	$ ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
	...
```

### The special case of *libdir*
The libraries installation depends on the system. *Makemore* is able to
manage the default UNIX installation into *<exec\_prefix>/lib/* directory
or the installation into *<exec\_prefix>/lib/<architecture>/* like the
Debian like OS. For other OS the *libdir* variable needs to be set during
the configuration.

On Debian:  
```bash

	$ make DESTDIR=$PWD/package install
	...
	$ tree ./package
	.
	└── usr
		└── lib
			└── x86_64-linux-gnu
				├── libbar.so -> libbar.so.0
				├── libbar.so.0 -> libbar.so.0.2
				├── libbar.so.0.2
				└── pkgconfig
					└── foo.pc
```

On Redhat it is mandatory to change the :  
```bash

	$ make libdir=/usr/lib$(getconf LONG_BIT) defconfig
	...
	$ make
	...
	$ make DESTDIR=$PWD/package install
	...
	$ tree ./package
	.
	└── usr
		└── lib64
			├── libbar.so -> libbar.so.0
			├── libbar.so.0 -> libbar.so.0.2
			├── libbar.so.0.2
			└── pkgconfig
				└── foo.pc
```

## The C Macro
The build step generate a *config.h* and a *version.h* files on the root of the project with few Macro definitions for the paths.

```C

	#ifndef __CONFIG_H__
	#define __CONFIG_H__
	#define BUILD_LIBRARY y
	#define MYMACRO "test"

	#define PKGLIBDIR "/usr/lib/foo"
	#define DATADIR "/usr/share/foo"
	#define PKG_DATADIR "/usr/share/foo"
	#define SYSCONFDIR "/etc"
	#define LOCALSTATEDIR "/var"

	#endif
```

The files are automatically included during the application build.

## The installation out of the box
Only the super user *root* may install a package on the system. *Makemore* may install a project into another directory than the */* directory and keep the same tree. To do that a destination directory must be instantiate during the installation step.

```bash

	$ make DESTDIR=$PWD/package install
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
	$ tree ./package
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
	$ tar -czf foo.tar.gz -C package .
```

## The data files
There is a lot of kinds of file in a project, and their installation depends on the usage. *Makemore* allows to dispatch using different variables.

### The application configuration file
The configuration file may be installed with the *sysconf-y*. All files in this variable will be installed inside the *sysconfdir* directory.

```Makefile

	sysconf-y+=foo.conf
	sysconf-y+=foo.d/test.conf
```

```bash

	$ tree ./package
	.
	└── etc
		├── foo.conf
	    └── foo.d
		    └── test.conf
```
