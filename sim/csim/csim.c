// TODO rearange parameters
// compile : gcc -O3 -Wall -std=c99 -lm csim.c -o csim

#include <arpa/inet.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define INST_ADDR 0x10000 // 64Kword
#define DATA_ADDR 0x800000 // 8Mword

#define NDEBUG
#define FLG_STEP false
#define FLG_IO_PRINTF true
#define FLG_COUNT_INST true
#include <assert.h>

typedef uint32_t inst_t;

static uint32_t GPR[32];
static float FPR[32];
static uint32_t PC;

static inst_t INST_MEM[INST_ADDR];
static uint32_t DATA_MEM[DATA_ADDR];

static unsigned int inst_count;

static inline inst_t bits(inst_t inst, unsigned int i, unsigned int j) {
	return (inst & ((1 << (i + 1)) - (1 << j))) >> j;
}

static inline void set_gpr(inst_t tag, uint32_t v) {
	if (tag) GPR[tag] = v;
}

static inline void set_fpr(inst_t tag, float v) {
	if (tag) FPR[tag] = v;
}

static inline void set_fpr_sgn(inst_t tag, inst_t sgn, float v) {
	float w;
	switch (sgn) {
	case 0b00:
		w = v;
		break;
	case 0b01:
		w = -v;
		break;
	case 0b10:
		w = copysign(v, 1);
		break;
	case 0b11:
		w = copysign(v, -1);
		break;
	}
	if (tag) FPR[tag] = w;
}

static union {
	int32_t i;
	float f;
} _box;

static inline int32_t float_as_int(float f) {
	_box.f = f;
	return _box.i;
}

static inline float int_as_float(int32_t i) {
	_box.i = i;
	return _box.f;
}

static void issue();
static void step();

static void alu(inst_t code, inst_t tagD, uint32_t a, uint32_t b) {
	switch (code) {
	case 0b0000:
		set_gpr(tagD, a + b);
		return issue();
	case 0b0001:
		set_gpr(tagD, a - b);
		return issue();
	case 0b0010:
		set_gpr(tagD, a == b);
		return issue();
	case 0b0011:
		set_gpr(tagD, ((int32_t) a) < ((int32_t) b));
		return issue();
	case 0b0100:
		set_gpr(tagD, a & b);
		return issue();
	case 0b0101:
		set_gpr(tagD, a | b);
		return issue();
	case 0b0110:
		set_gpr(tagD, a ^ b);
		return issue();
	case 0b0111:
		set_gpr(tagD, a << bits(b, 4, 0));
		return issue();
	case 0b1000:
		set_gpr(tagD, a >> bits(b, 4, 0));
		return issue();
	case 0b1001:
		set_gpr(tagD, ((int32_t) a) >> bits(b, 4, 0)); // relying on undefined behavior
		return issue();
	case 0b1010:
		set_gpr(tagD, (a & ((1 << 16) - 1)) | (b << 16));
		return issue();
	case 0b1011:
		set_gpr(tagD, a * b);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void aluf(inst_t code, inst_t tagD, float a, float b) {
	switch (code) {
	case 0b1100:
		assert(b == 0.0);
		set_gpr(tagD, (uint32_t) float_as_int(a));
		return issue();
	case 0b1101:
		assert(b == 0.0);
		set_gpr(tagD, (uint32_t) (int32_t) a);
		return issue();
	case 0b1110:
		set_gpr(tagD, a == b);
		return issue();
	case 0b1111:
		set_gpr(tagD, a < b);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void fpu(inst_t code, inst_t sgn, inst_t tagD, float a, float b) {
	switch (code) {
	case 0b000:
		set_fpr_sgn(tagD, sgn, a + b);
		return issue();
	case 0b001:
		set_fpr_sgn(tagD, sgn, a - b);
		return issue();
	case 0b010:
		set_fpr_sgn(tagD, sgn, a * b);
		return issue();
	case 0b011:
		assert(b == 0.0);
		set_fpr_sgn(tagD, sgn, 1 / a);
		return issue();
	case 0b100:
		assert(b == 0.0);
		set_fpr_sgn(tagD, sgn, sqrtf(a));
		return issue();
	case 0b101:
		assert(b == 0.0);
		set_fpr_sgn(tagD, sgn, a);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void fpur(inst_t code, inst_t sgn, inst_t tagD, uint32_t a, uint32_t b) {
	switch (code) {
	case 0b110:
		assert(b == 0);
		set_fpr_sgn(tagD, sgn, int_as_float((int32_t) a));
		return issue();
	case 0b111:
		assert(b == 0);
		set_fpr_sgn(tagD, sgn, ((float) (int32_t) a));
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void brr(inst_t code, uint32_t target, uint32_t a, uint32_t b) {
	switch (code) {
		case 0b000:
			if (a == b) PC = target;
			return issue();
		case 0b001:
			if (a != b) PC = target;
			return issue();
		case 0b010:
			if (a < b) PC = target;
			return issue();
		case 0b011:
			if (a >= b) PC = target;
			return issue();
		default:
			assert(false);
			return issue();
	}
}

static void brf(inst_t code, uint32_t target, float a, float b) {
	switch (code) {
		case 0b000:
			if (a == b) PC = target;
			return issue();
		case 0b001:
			if (a != b) PC = target;
			return issue();
		case 0b010:
			if (a < b) PC = target;
			return issue();
		case 0b011:
			if (a >= b) PC = target;
			return issue();
		default:
			assert(false);
			return issue();
	}
}

static void rrsp(inst_t func, inst_t tagX, uint32_t y) {
	switch (func) {
		case 0:
			assert(y == 0);
			for (int i = 0; i < 4; i++) {
				y = y << 8;
				y &= (unsigned char) getchar();
			}
			set_gpr(tagX, y);
			return issue();
		case 1:
			assert(tagX == 0);
			if (FLG_IO_PRINTF) {
				printf("%u\n", y);
			} else {
				for (int i = 0; i < 4; i++) {
					putchar((unsigned char) (y >> 24));
					y = y << 8;
				}
			}
			return issue();
		default:
			// halt signal
			return;
	}
}

static void rfsp(inst_t func, inst_t tagX, float y) {
	assert(false);
	return issue();
}

static void frsp(inst_t func, inst_t tagX, uint32_t y) {
	assert(false);
	return issue();
}

static void ffsp(inst_t func, inst_t tagX, float y) {
	switch (func) {
		uint32_t tmp;
		int i;
		case 0:
			assert(y == 0.0);
			for (i = 0; i < 4; i++) {
				tmp = tmp << 8;
				tmp &= (unsigned char) getchar();
			}
			set_fpr(tagX, int_as_float((int32_t) tmp));
			return issue();
		case 1:
			assert(tagX == 0);
			tmp = float_as_int(y);
			if (FLG_IO_PRINTF) {
				printf("%f\n", y);
			} else {
				for (i = 0; i < 4; i++) {
					putchar((char) tmp >> 24);
					tmp = tmp >> 8;
				}
			}
			return issue();
		default:
			assert(false);
			return issue();
	}
}

static void issue() {
	if (FLG_STEP) step();
	if (FLG_COUNT_INST) inst_count++;
	inst_t inst = INST_MEM[PC++];

	inst_t tagX = bits(inst, 25, 21);
	inst_t tagY = bits(inst, 20, 16);
	inst_t tagZ = bits(inst, 15, 11);
	uint16_t imm = bits(inst, 15, 0);

	switch (bits(inst, 31, 30)) {
	case 0b00:
		return alu(bits(inst, 29, 26), tagY, GPR[tagX], (uint32_t) (int32_t) (int16_t) imm);
	case 0b01:
		switch (bits(inst, 29, 26)) {
			case 0b0000:
				assert(bits(inst, 10, 4) == 0);
				return alu(bits(inst, 3, 0), tagZ, GPR[tagX], GPR[tagY]);
			case 0b0001:
				assert(bits(inst, 10, 4) == 0);
				return aluf(bits(inst, 3, 0), tagZ, FPR[tagX], FPR[tagY]);
			case 0b1000:
				assert(bits(inst, 10, 6) == 0);
				return fpur(bits(inst, 3, 0), bits(inst, 5, 4), tagZ, GPR[tagX], GPR[tagY]);
			case 0b1001:
				assert(bits(inst, 10, 6) == 0);
				return fpu(bits(inst, 3, 0), bits(inst, 5, 4), tagZ, FPR[tagX], FPR[tagY]);
			case 0b0100:
			case 0b0101:
			case 0b0110:
				assert(imm == 0);
				set_gpr(tagY, PC << 2);
				PC = (((GPR[tagX] >> 2) & (INST_ADDR - 1)) | imm);
				return issue();
			case 0b0010:
				return rrsp(imm, tagY, GPR[tagX]);
			case 0b0011:
				return rfsp(imm, tagY, FPR[tagX]);
			case 0b1010:
				return frsp(imm, tagY, GPR[tagX]);
			case 0b1011:
				return ffsp(imm, tagY, FPR[tagX]);
			default:
				assert(false);
				return issue();
		}
	case 0b10:
		;
		uint32_t addr = ((GPR[tagX] >> 2) + ((int32_t) (int16_t) imm)) & (DATA_ADDR - 1);
		switch (bits(inst, 29, 26)) {
			case 0b0000:
				set_gpr(tagY, DATA_MEM[addr]);
				return issue();
			case 0b0001:
				DATA_MEM[addr] = GPR[tagY];
				return issue();
			case 0b1000:
				set_fpr(tagY, int_as_float((int32_t) DATA_MEM[addr]));
				return issue();
			case 0b1001:
				DATA_MEM[addr] = (uint32_t) float_as_int(FPR[tagY]);
				return issue();
			default:
				assert(false);
				return issue();
		}
	case 0b11:
		switch (bits(inst, 29, 29)) {
			case 0b0:
				return brr(bits(inst, 29, 26), imm, GPR[tagX], GPR[tagY]);
			case 0b1:
				return brf(bits(inst, 29, 26), imm, FPR[tagX], FPR[tagY]);
		}
	}
}

static void step() {
	printf("pc: %d\n", PC);
	while (true) {
		char buf[10];
		gets(buf);
		unsigned int v;
		if (sscanf(buf, "r%u", &v) == 1 && v < 32) {
			printf("r%d: %d\n", v, GPR[v]);
			continue;
		}
		if (sscanf(buf, "mem%u", &v) == 1) {
			printf("mem%d: %d\n", v, DATA_MEM[v]);
			continue;
		}
		break;
	}
}

int main(int argc, const char *argv[]) {
	if (argc != 2) {
		fputs("extactly one source file must be specified", stderr);
		return 1;
	}
	FILE *fp = fopen(argv[1], "r");
	if (!fp) {
		fputs("opening file failed", stderr);
		return 1;
	}

	size_t cnt;
	size_t pos = 0;
	while ((cnt = fread(&INST_MEM[pos], 4, 2048, fp)))
		pos += cnt;
	for (size_t i = 0; i < pos; i++)
		INST_MEM[i] = htonl(INST_MEM[i]);

	issue();
	if (FLG_COUNT_INST) {
		printf("instruction count %u\n", inst_count);
	}

	return 0;
}
