# Qt Application
## Qt.mk extension
The Qt target requires to an extension of *Makemore*. When the project
is created, the main *scripts.mk* file must be copy and yet the
*scripts/qt.mk* file.

The project tree looks like:
```bash
├── defconfig
├── Makefile
├── scripts.mk
├── scripts
│   └── qt.mk
└── src
    ├── main.cpp
    ├── Makefile
    ├── Viewer.cpp
    └── Viewer.hpp
```

Read the [extension chapter](../07-extensions/README.md) for more information.

## *<target>\_QTOBJECTS*
To build Qt application, the moc tool must be pass on the **QTOBJECT**.
The **QTOBJECT** is defined inside the object description.

The variable *<target>\_QTOBJECTS* must contain all header files with **QTOBJECT**

```cpp
#include <QAbstractTableModel>

class Viewer : public QAbstractTableModel
{
    Q_OBJECT
```

```Makefile
bin-y+=qtsimple

qtsimple_SOURCES+=Viewer.cpp
qtsimple_QTOBJECTS+=Viewer.hpp
```

## Qt5 libraries
Makemore is able to use pkgconfig for Qt. *<target>\_LIBRARY* may contain *Qt5<module>*.

The pkgconfig files from Qt contain an error and don't return the
complete CXXFLAGS. The *<target>_CFLAGS* must be set to add the **-fPIC** option.

```Makefile
qtsimple_LIBRARY+=Qt5Widgets
qtsimple_CXXFLAGS+=-fPIC
```
