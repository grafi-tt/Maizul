loop:
getb	r1;
putb	r1;
or	r1	r0	10;
putb	r1;
jmp	r0	r0	loop@t;
