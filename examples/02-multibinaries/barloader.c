#include <dlfcn.h>
#include <stdio.h>

int (*tempobar)(void);

int bar2(void)
{
	printf("load ./bar.so\n");
	void *handle;
	handle = dlopen("./bar.so", RTLD_LAZY);
	if (handle != NULL)
	{
		tempobar = dlsym(handle, "bar");
		tempobar();
	}
	return 0;
}
