#include <stdio.h>

#include <zlib.h>

int main(void)
{
#ifdef HAVE_ZLIB
	printf("zlib found\n");
#else
	printf("zlib not found\n");
#endif
	return 0;
}
