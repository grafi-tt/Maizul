.PHONY: all clean asm

all: asm sim

asm:
	$(MAKE) -f Makefile.asm

sim:
	$(MAKE) -f Makefile.sim

clean:
	$(MAKE) -f Makefile.asm clean
	$(MAKE) -f Makefile.sim clean
