#include <stdio.h>

extern int bar(void);
extern int bar2(void);

int main(int argc, char *argv[])
{
	printf("from %s\n", argv[0]);
	bar();
	bar2();
}
