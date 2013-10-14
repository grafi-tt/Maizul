#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define INST_ADDR 0x10000 // 64Kword
#define DATA_ADDR 0x800000 // 8Mword

typedef uint32_t inst_t;

static uint32_t GPR[32];
static float FPR[32];
static uint32_t PC;

static inst_t INST_MEM[INST_ADDR];
static uint32_t DATA_MEM[DATA_ADDR];

static inline inst_t bits(inst_t inst, unsigned int i, unsigned int j) {
	return inst & ((1 << (i + 1)) - (1 << j)) >> j;
}

static inline void set_gpr(uint32_t *tag, uint32_t v) {
	if (tag != &GPR[0]) *tag = v;
}

static inline void set_fpr(float *tag, float v) {
	if (tag != &FPR[0]) *tag = v;
}

static inline void set_fpr_sgn(float *tag, inst_t sgn, float v) {
	// TODO sgn
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
	if (tag != &FPR[0]) *tag = w;
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

static void alu(inst_t code, uint32_t *ptrD, uint32_t a, uint32_t ub, int32_t sb) {
	switch (code) {
	case 0b0000:
		set_gpr(ptrD, a + ub);
		return issue();
	case 0b0001:
		set_gpr(ptrD, a - ub);
		return issue();
	case 0b0010:
		set_gpr(ptrD, (int32_t) a == sb);
		return issue();
	case 0b0011:
		set_gpr(ptrD, (int32_t) a < sb);
		return issue();
	case 0b0100:
		set_gpr(ptrD, a & sb);
		return issue();
	case 0b0101:
		set_gpr(ptrD, a | sb);
		return issue();
	case 0b0110:
		set_gpr(ptrD, a ^ sb);
		return issue();
	case 0b0111:
		set_gpr(ptrD, a << bits(ub, 4, 0));
		return issue();
	case 0b1000:
		set_gpr(ptrD, (uint32_t) a >> bits(ub, 4, 0));
		return issue();
	case 0b1001:
		set_gpr(ptrD, a >> bits(ub, 4, 0)); // relying on undefined behavior
		return issue();
	case 0b1010:
		set_gpr(ptrD, (a & ((1 << 16) - 1)) | (ub << 16));
		return issue();
	case 0b1011:
		set_gpr(ptrD, a * ub);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void aluf(inst_t code, uint32_t *ptrD, float a, float b) {
	switch (code) {
	case 0b1100:
		assert(b == 0.0);
		set_gpr(ptrD, (uint32_t) float_as_int(a));
		return issue();
	case 0b1101:
		assert(b == 0.0);
		set_gpr(ptrD, (uint32_t) (int32_t) a);
		return issue();
	case 0b1110:
		set_gpr(ptrD, a == b);
		return issue();
	case 0b1111:
		set_gpr(ptrD, a < b);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void fpu(inst_t code, inst_t sgn, float *ptrD, float a, float b) {
	switch (code) {
	case 0b000:
		set_fpr_sgn(ptrD, sgn, a + b);
		return issue();
	case 0b001:
		set_fpr_sgn(ptrD, sgn, a - b);
		return issue();
	case 0b010:
		set_fpr_sgn(ptrD, sgn, a * b);
		return issue();
	case 0b011:
		assert(b == 0.0);
		set_fpr_sgn(ptrD, sgn, 1 / a);
		return issue();
	case 0b100:
		assert(b == 0.0);
		set_fpr_sgn(ptrD, sgn, sqrtf(a));
		return issue();
	case 0b101:
		assert(b == 0.0);
		set_fpr_sgn(ptrD, sgn, a);
		return issue();
	default:
		assert(false);
		return issue();
	}
}

static void fpur(inst_t code, inst_t sgn, float *ptrD, uint32_t a, uint32_t b) {
	switch (code) {
	case 0b110:
		assert(b == 0);
		set_fpr_sgn(ptrD, sgn, int_as_float((int32_t) a));
		return issue();
	case 0b111:
		assert(b == 0);
		set_fpr_sgn(ptrD, sgn, ((float) (int32_t) a));
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

static void rrsp(inst_t func, uint32_t *ptrA, uint32_t b) {
	switch (func) {
		int i;
		case 0:
			for (i = 0; i < 4; i++) {
				putchar((char) b >> 24);
				b = b >> 8;
			}
			return issue();
		case 1:
			for (i = 0; i < 4; i++) {
				b = b << 8;
				b &= (unsigned char) getchar();
			}
			*ptrA = b;
			return issue();
		default:
			assert(false);
			return issue();
	}
}

static void rfsp(inst_t func, uint32_t *ptrA, float b) {
	assert(false);
	return issue();
}

static void frsp(inst_t func, float *ptrA, uint32_t b) {
	assert(false);
	return issue();
}

static void ffsp(inst_t func, float *ptrA, float b) {
	switch (func) {
		uint32_t tmp;
		int i;
		case 0:
			tmp = float_as_int(b);
			for (i = 0; i < 4; i++) {
				putchar((char) tmp >> 24);
				tmp = tmp >> 8;
			}
			return issue();
		case 1:
			for (i = 0; i < 4; i++) {
				tmp = tmp << 8;
				tmp &= (unsigned char) getchar();
			}
			*ptrA = int_as_float(tmp);
			return issue();
		default:
			assert(false);
			return issue();
	}
}

static void issue() {
	inst_t inst = INST_MEM[PC++];

	inst_t tagA = bits(inst, 25, 21);
	inst_t tagB = bits(inst, 20, 16);
	inst_t tagC = bits(inst, 15, 11);
	uint16_t imm = bits(inst, 15, 0);

	switch (bits(inst, 31, 30)) {
	case 0b00:
		return alu(bits(inst, 29, 26), &GPR[tagA], GPR[tagB], imm, (int32_t) imm);
	case 0b01:
		switch (bits(inst, 29, 26)) {
			case 0b0000:
				return alu(bits(inst, 3, 0), &GPR[tagA], GPR[tagB], GPR[tagC], (int32_t) GPR[tagC]);
			case 0b0001:
				return aluf(bits(inst, 3, 0), &GPR[tagA], FPR[tagB], FPR[tagC]);
			case 0b0010:
				assert(imm == 0);
				GPR[tagB] = PC << 2;
				PC = GPR[tagA] >> 2 & (INST_ADDR - 1);
				return issue();
			case 0b0011:
				assert(tagA == 0);
				GPR[tagB] = PC << 2;
				PC = imm;
				return issue();
			case 0b1000:
				return fpur(bits(inst, 3, 0), bits(inst, 5, 4), &FPR[tagA], GPR[tagB], GPR[tagC]);
			case 0b1001:
				return fpu(bits(inst, 3, 0), bits(inst, 5, 4), &FPR[tagA], FPR[tagB], FPR[tagC]);
			case 0b0100:
				return rrsp(imm, &GPR[tagA], GPR[tagB]);
			case 0b0101:
				return rfsp(imm, &GPR[tagA], FPR[tagB]);
			case 0b1100:
				return frsp(imm, &FPR[tagA], GPR[tagB]);
			case 0b1101:
				return ffsp(imm, &FPR[tagA], GPR[tagB]);
			default:
				assert(false);
				return issue();
		}
	case 0b10:
		;
		uint32_t addr = (GPR[tagB] >> 2 & (DATA_ADDR - 1)) + imm;
		switch (bits(inst, 29, 26)) {
			case 0b0000:
				set_gpr(&GPR[tagA], DATA_MEM[addr]);
				return issue();
			case 0b0001:
				DATA_MEM[addr] = GPR[tagA];
				return issue();
			case 0b1000:
				set_gpr(&GPR[tagA], int_as_float((int32_t) DATA_MEM[addr]));
				return issue();
			case 0b1001:
				DATA_MEM[addr] = (uint32_t) float_as_int(FPR[tagA]);
				return issue();
			default:
				assert(false);
				return issue();
		}
	case 0b11:
		switch (bits(inst, 29, 29)) {
			case 0b0:
				return brr(bits(inst, 29, 26), imm, GPR[tagA], GPR[tagB]);
			case 0b1:
				return brf(bits(inst, 29, 26), imm, FPR[tagA], FPR[tagB]);
		}
	}
}

int main(int argc, const char *argv[]) {
	if (argc != 1) {
		fputs("extactly one source file must be specified", stderr);
		return 1;
	}
	FILE *fp = fopen(argv[0], "r");
	if (!fp) {
		fputs("opening file failed", stderr);
		return 1;
	}

	size_t cnt;
	size_t pos = 0;
	while ((cnt = fread(&INST_MEM[pos], 4, 2048, fp))) {
		pos += cnt;
	}

	issue();

	return 0;
}
