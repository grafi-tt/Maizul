or	r2	r0	40;
jmp	r31	r0	fib@t;
put	r1;
halt:	jmp	r0	r0	halt@t;

fib:
	lt	r3	r2	2;
	or	r1	r0	1;
	bne	r3	r0	fibret@t;
	add	r30	r30	2;
	st	r31	r30	-2;
	st	r2	r30	-1;
	sub	r2	r2	1;
	jmp	r31	r0	fib@t;
	ld	r2	r30	-1;
	st	r1	r30	-1;
	sub	r2	r2	2;
	jmp	r31	r0	fib@t;
	ld	r2	r30	-1;
	add	r1	r1	r2;
	ld	r31	r30	-2;
	sub	r30	r30	2;
	fibret:
	jmp	r0	r31	0;
