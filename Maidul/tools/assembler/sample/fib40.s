or	r2	r0	40;
jmpc	r31	r0	fib@t;
put	r1;
halt:	jmp	r0	r0	halt@t;

fib:
	lt	r3	r2	2;
	or	r1	r0	1;
	bne	r3	r0	fibret@t;
	add	r29	r29	2;
	st	r31	r29	-2;
	st	r2	r29	-1;
	sub	r2	r2	1;
	jmpc	r31	r0	fib@t;
	ld	r2	r29	-1;
	st	r1	r29	-1;
	sub	r2	r2	2;
	jmpc	r31	r0	fib@t;
	ld	r2	r29	-1;
	add	r1	r1	r2;
	ld	r31	r29	-2;
	sub	r29	r29	2;
	fibret:
	jmpr	r0	r31	0;
