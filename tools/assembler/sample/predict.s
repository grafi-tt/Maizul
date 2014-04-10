or	r1	r0	0;
outer:
bne	r1	r0	somewhere@t;
or	r2	r0	2;
inner:
or	r8	r0	0;
or	r9	r0	0;
sub	r2	r2	1;
bne	r2	r0	inner@t;
beq	r1	r0	outer@t;
somewhere:
add	r0	r0	42;
