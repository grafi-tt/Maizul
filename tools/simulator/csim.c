#include <arpa/inet.h>
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "fpu.h"

#define INST_ADDR 0x10000 // 64Kword
#define DATA_ADDR 0x800000 // 8Mword

// http://d.hatena.ne.jp/nyanp/20110728/p1
#define B__(b) ( \
     ((b & 1 <<  0) >>  0) + ((b & 1 <<  3) >>  2) + ((b & 1 <<  6) >>  4) + \
     ((b & 1 <<  9) >>  6) + ((b & 1 << 12) >>  8) + ((b & 1 << 15) >> 10) + \
     ((b & 1 << 18) >> 12) + ((b & 1 << 21) >> 14))
#define B(b) B__(0 ## b)

#define NDEBUG
#define FLG_STEP false
#define FLG_COUNT_INST true
#define FLG_FLUSH false
#include <assert.h>

typedef uint32_t inst_t;

static uint32_t GPR[32];
static float FPR[32];
static uint32_t PC;
static uint32_t IP;

static inst_t INST_MEM[INST_ADDR];
static uint32_t DATA_MEM[DATA_ADDR];

static uint64_t inst_count;

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
    case B(00):
        w = v;
        break;
    case B(01):
        w = -v;
        break;
    case B(10):
        w = copysign(v, 1);
        break;
    case B(11):
        w = copysign(v, -1);
        break;
    default:
        assert(false);
        w = v;
        break;
    }
    set_fpr(tag, w);
}

static void issue();
static void step();

static void alu(inst_t code, inst_t tagD, uint32_t a, uint32_t b) {
    switch (code) {
    case B(0000):
        set_gpr(tagD, a + b);
        return issue();
    case B(0001):
        set_gpr(tagD, a - b);
        return issue();
    case B(0010):
        set_gpr(tagD, a == b);
        return issue();
    case B(0011):
        set_gpr(tagD, ((int32_t) a) < ((int32_t) b));
        return issue();
    case B(0100):
        set_gpr(tagD, a & b);
        return issue();
    case B(0101):
        set_gpr(tagD, a | b);
        return issue();
    case B(0110):
        set_gpr(tagD, a ^ b);
        return issue();
    case B(0111):
        set_gpr(tagD, a << bits(b, 4, 0));
        return issue();
    case B(1000):
        set_gpr(tagD, a >> bits(b, 4, 0));
        return issue();
    case B(1001):
        set_gpr(tagD, ((int32_t) a) >> bits(b, 4, 0)); // relying on undefined behavior
        return issue();
    case B(1010):
        set_gpr(tagD, (a & ((1 << 16) - 1)) | (b << 16));
        return issue();
    case B(1011):
        set_gpr(tagD, (a & ((1 << 16) - 1)) * (b & 0xFFFF));
        return issue();
    default:
        assert(false);
        return issue();
    }
}

static void aluf(inst_t code, inst_t tagD, float a, float b) {
    switch (code) {
    case B(1100):
        assert(b == 0.0);
        set_gpr(tagD, float_as_uint(a));
        return issue();
    case B(1101):
        assert(b == 0.0);
        set_gpr(tagD, ftoi_native(a));
        return issue();
    case B(1110):
        set_gpr(tagD, a == b);
        return issue();
    case B(1111):
        set_gpr(tagD, a < b);
        return issue();
    default:
        assert(false);
        return issue();
    }
}

static void fpu(inst_t code, inst_t sgn, inst_t tagD, float a, float b) {
    switch (code) {
    case B(000):
        set_fpr_sgn(tagD, sgn, fadd_native(a, b));
        return issue();
    case B(001):
        set_fpr_sgn(tagD, sgn, fsub_native(a, b));
        return issue();
    case B(010):
        set_fpr_sgn(tagD, sgn, fmul_native(a, b));
        return issue();
    case B(011):
        assert(b == 0);
        set_fpr_sgn(tagD, sgn, finv_circuit(a));
        return issue();
    case B(100):
        assert(b == 0);
        set_fpr_sgn(tagD, sgn, fsqr_circuit(a));
        return issue();
    case B(101):
        assert(b == 0);
        set_fpr_sgn(tagD, sgn, a);
        return issue();
    case B(110):
        assert(b == 0);
        set_fpr_sgn(tagD, sgn, fflr_native(a));
        return issue();
    default:
        assert(false);
        return issue();
    }
}

static void fpur(inst_t code, inst_t sgn, inst_t tagD, uint32_t a, uint32_t b) {
    switch (code) {
    case B(111):
        assert(b == 0);
        set_fpr_sgn(tagD, sgn, itof_native(a));
        return issue();
    default:
        assert(false);
        return issue();
    }
}

static void brr(inst_t code, uint32_t target, uint32_t a, uint32_t b) {
    switch (code) {
        case B(000):
            if (a == b) PC = target;
            return issue();
        case B(001):
            if (a != b) PC = target;
            return issue();
        case B(010):
            if (((int32_t) a) < ((int32_t) b)) PC = target;
            return issue();
        case B(011):
            if (((int32_t) a) > ((int32_t) b)) PC = target;
            return issue();
        default:
            assert(false);
            return issue();
    }
}

static void brf(inst_t code, uint32_t target, float a, float b) {
    switch (code) {
        case B(000):
            if (a == b) PC = target;
            return issue();
        case B(001):
            if (a != b) PC = target;
            return issue();
        case B(010):
            if (a < b) PC = target;
            return issue();
        case B(011):
            if (a > b) PC = target;
            return issue();
        default:
            assert(false);
            return issue();
    }
}

static void rrsp(inst_t func, inst_t tagX, uint32_t y) {
    switch (func) {
        case B(000):
            assert(false);
            return issue();
        case B(001):
            assert(false);
            return issue();
        case B(010):
            assert(y == 0);
            y = (unsigned char) getchar();
            set_gpr(tagX, y);
            return issue();
        case B(011):
            assert(tagX == 0);
            putchar((unsigned char) y);
            if (FLG_FLUSH) fflush(stdout);
            return issue();
        case B(100):
            assert(tagX == 0);
            INST_MEM[IP++] = y;
            return issue();
        case B(101):
            assert(tagX == 0);
            IP = y;
            return issue();
        case B(110):
            assert(y == 0);
            set_gpr(tagX, 3); // TODO
            return issue();
        case B(111):
            assert(y == 0);
            set_gpr(tagX, 0); // TODO
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
    uint32_t addr = (GPR[tagX] + ((int32_t) (int16_t) imm)) & (DATA_ADDR - 1);

    switch (bits(inst, 31, 30)) {
    case B(00):
        return alu(bits(inst, 29, 26), tagY, GPR[tagX], (uint32_t) (int32_t) (int16_t) imm);
    case B(01):
        switch (bits(inst, 29, 26)) {
            case B(0000):
                assert(bits(inst, 10, 4) == 0);
                return alu(bits(inst, 3, 0), tagZ, GPR[tagX], GPR[tagY]);
            case B(0001):
                assert(bits(inst, 10, 4) == 0);
                return aluf(bits(inst, 3, 0), tagZ, FPR[tagX], FPR[tagY]);
            case B(1000):
                assert(bits(inst, 10, 6) == 0);
                return fpur(bits(inst, 3, 0), bits(inst, 5, 4), tagZ, GPR[tagX], GPR[tagY]);
            case B(1001):
                assert(bits(inst, 10, 6) == 0);
                return fpu(bits(inst, 3, 0), bits(inst, 5, 4), tagZ, FPR[tagX], FPR[tagY]);
            case B(0010):
                set_gpr(tagY, DATA_MEM[addr]);
                return issue();
            case B(0011):
                DATA_MEM[addr] = GPR[tagY];
                return issue();
            case B(1010):
                set_fpr(tagY, uint_as_float(DATA_MEM[addr]));
                return issue();
            case B(1011):
                DATA_MEM[addr] = float_as_uint(FPR[tagY]);
                return issue();
            case B(0100):
            case B(0101):
            case B(0110):
                if (!tagX && imm == PC-1) {
                    return;
                }
                set_gpr(tagY, PC);
                PC = ((GPR[tagX] & (INST_ADDR - 1)) | imm);
                return issue();
            case B(0111):
                return rrsp(imm, tagY, GPR[tagX]);
            default:
                assert(false);
                return issue();
        }
    case B(10):
        return brr(bits(inst, 29, 26), imm, GPR[tagX], GPR[tagY]);
    case B(11):
        return brf(bits(inst, 29, 26), imm, FPR[tagX], FPR[tagY]);
    }
}

static void step() {
    printf("pc: %d\n", PC);
    while (true) {
        // needed to be static for TCO
        // <http://stackoverflow.com/questions/14088484/why-does-this-code-prevent-gcc-llvm-from-tail-call-optimization>
        static char buf[10];
        static unsigned int v;
        if (scanf(buf, "%9s%u", buf, &v) == 1) {
            if (strcmp(buf, "r") == 0 && v < 32) {
                printf("r%d: %d\n", v, GPR[v]);
                continue;
            }
            if (strcmp(buf, "mem") == 0) {
                printf("mem%d: %d\n", v, DATA_MEM[v]);
                continue;
            }
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
        fprintf(stderr, "instruction count%" PRIu64 "\n", inst_count);
    }

    return 0;
}
