msvc:
		cl /nologo /O2 /Ot /DTEST test.c s20.c
gnu:
		gcc -DTEST -Wall -O2 test.c s20.c -otest	 
clang:
		clang -DTEST -Wall -O2 test.c s20.c -otest	 
asm:
		nasm -f elf64 -o salsa.o asm/s20_64.asm	
		gcc -DTEST -Wall -O2 test.c asm/s20_64.o -otest
