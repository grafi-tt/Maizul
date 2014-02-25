getb	r1;
getb	r2;
sll	r1	r1	8;
or	r1	r1	r2;
/* `setip` is not supported by asm, so there is placeholder (`add r0 r0 0`) and you must edit binary by hand.
setip	r0;*/
add r0 r0 0;
or	r2	r0	0;
firmware_loader_loop:
	add	r2	r2	1;
	getb	r3;
	sll	r3	r3	8;
	getb	r4;
	or	r3	r4	r3;
	sll	r3	r3	8;
	getb	r4;
	or	r3	r4	r3;
	sll	r3	r3	8;
	getb	r4;
	or	r3	r4	r3;
/*	wrti is not supported by asm, ...
	wrti	r3; */
	add r0 r0 0;
/* Loader will be placed on bottom of RAM, so asm cannot convert label to address properly and you must edit binary by hand.
blt	r2	r1	firmware_loader_loop@t;*/
blt r2 r1 0;
/* automatically goto PC 0 by overflow of PC */
