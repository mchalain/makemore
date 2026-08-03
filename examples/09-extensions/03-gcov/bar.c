#include <stdio.h>

#ifndef TYPE
#warning
#define TYPE "unknown"
#endif

int bar(void)
{
	printf("hello to %s\n", TYPE);
	return 0;
}
