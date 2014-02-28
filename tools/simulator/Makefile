CC = gcc
CFLAGS = -std=c99 -Wall -Werror -O3 -fno-fast-math
LDFLAGS = -lm

all: csim fputest

csim: csim.c fpu.c fpu.h fpu-table.h
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

fputest: fputest.c fpu.c fpu.h fpu-table.h
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
