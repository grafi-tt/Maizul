cat	r20	r0	128;
or	r21	r0	-1;
cat	r22	r0	32640; /* infinity */

loop:
	st	r20	r29	1;
	fld	f20	r29	1;

	fmov	f1	f20;
	srl	r0	r0	2;
	fmov	f21	f1;
	fmov	f1	f20;
	jmpc	r31	r0	min_caml_atan@t;
	fmov	f2	f1;
	fmov	f1	f21;
	or	r1	r0	16;
	srl	r0	r0	3;

	beq	r1	r21	error@t;
	add	r20	r20	1;
bne	r20	r22	loop@t;

srl	r0	r0	4;
putb	r1;
jmp	r0	r0	end@t;

error:
or	r1	r0	r20;
jmpc	r31	r0	min_caml_prerr_int@t;
jmpc	r31	r0	min_caml_prerr_float@t;
fmov	f1	f2;
jmpc	r31	r0	min_caml_prerr_float@t;

end:
jmp	r0	r0	end@t;
