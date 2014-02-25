CC = gcc
CFLAGS = -std=c99 -Wall -Werror -O3
LDFLAGS = -lm

csim: csim.c fpu.c fpu.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

fputest: fputest.c fpu.c fpu.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
