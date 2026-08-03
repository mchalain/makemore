# Libraries
## pkgconfig file generation
*Makemore* supports pkgconfig (*.pc) file for generation:

 * *pkgconfig-y+=<libmylib>* : generate libmylib.pc and install to $(libdir)/pkg-config/ directory :
 * *<libmylib>_DESC="my library description"* : a string to describe the library into pkgconfig file :
 * *<libmylib>_LIBS=<library>* : append a library into the *<libmylib>.pc.in* file :

A *<libmylib>.pc.in* may be available for special configuration or *Makemore* generates this file .
too.

