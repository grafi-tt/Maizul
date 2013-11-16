.data
const_0_5:
word	w1056964608;
const_1_5:
word	w1069547520;
const_2_0:
word	w1073741824;

.text
or	r1	r0	3;
rtof	f1	r1;
jmpc	r31	r0	finv@t;
fmovr	r1	f1;
put	r1;

or	r1	r0	3;
rtof	f1	r1;
jmpc	r31	r0	fsqr@t;
fmovr	r1	f1;
put	r1;

halt:	jmp	r0	r0	halt@t;

finv:
	fmovr	r1	f1;
	cat	r2	r0	32512;
	cat	r3	r0	32640;
	fbeq	f1	f0	finv_arg_zero@t;
	or	r3	r1	r2;
	beq	r3	r2	finv_arg_inf@t;
	fld	f4	r0	const_2_0@d;
	sub	r1	r2	r1;
	st	r1	r29	1;
	fld	f2	r29	1;
	fmul	f3	f1	f2;
	fsub	f3	f4	f3;
	fmul	f2	f2	f3;
	fmul	f3	f1	f2;
	fsub	f3	f4	f3;
	fmul	f2	f2	f3;
	fmul	f3	f1	f2;
	fsub	f3	f4	f3;
	fmul	f1	f2	f3;
	jmpr	r0	r31	0;
	finv_arg_inf:
	or	r3	r0	0;
	finv_arg_zero:
	srl	r1	r1	31;
	sll	r1	r1	31;
	or	r1	r1	r3;
	st	r1	r29	1;
	fld	f1	r29	1;
	jmpr	r0	r31	0;

fsqr:
	fmovr	r1	f1;
	cat	r2	r0	32512;
	or	r3	r1	r2;
	beq	r3	r2	fsqr_arg_inf@t;
	fld	f4	r0	const_0_5@d;
	fld	f5	r0	const_1_5@d;
	srl	r1	r1	1;
	cat	r2	r0	24384;
	sub	r1	r2	r1;
	fmul	f4	f4	f1;
	st	r1	r29	1;
	fld	f2	r29	1;
	fmul	f3	f4	f2;
	fmul	f3	f3	f2;
	fsub	f3	f5	f3;
	fmul	f2	f2	f3;
	fmul	f3	f4	f2;
	fmul	f3	f3	f2;
	fsub	f3	f5	f3;
	fmul	f2	f2	f3;
	fmul	f3	f4	f2;
	fmul	f3	f3	f2;
	fsub	f3	f5	f3;
	fmul	f2	f2	f3;
	fmul	f1	f1	f2;
	fsqr_arg_inf:
	jmpr	r0	r31	0;
