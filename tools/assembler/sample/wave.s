.data
const_001:
word w1008981770;
.text
or	r20	r0	100;
or	r21	r0	-1;
fld	f20	r0	const_001@d;
loop:
rtof	f1	r21;
fmovr	r22	f1;
ftorx	f1	r22;
fmovr	r22	f1;
putb	r22;
/*jmpc	r31	r0	min_caml_prerr_float@t;*/
/*jmpc	r31	r0	min_caml_cos@t;*/
/*jmpc	r31	r0	min_caml_sin@t;*/
add	r21	r21	1;
blt	r21	r20	loop@t;
halt:
jmp	r0	r0	halt@t;
