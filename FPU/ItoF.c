#include <stdint.h>
#include <stdio.h>

static inline uint64_t bits(uint64_t u, unsigned int i, unsigned int j) {
    return (u & ((1ul << (i + 1)) - (1ul << j))) >> j;
}

static union {
    uint32_t i;
    float f;
} _box;

static inline uint32_t float_as_uint(float f) {
    _box.f = f;
    return _box.i;
}

static inline float uint_as_float(uint32_t i) {
    _box.i = i;
    return _box.f;
}

float i_to_f(int32_t i) {
    uint64_t u_frc[5];
    uint64_t u_frc_tmp;
    uint32_t x_nlz;
    int tail_any, round;
    uint32_t u_frc_norm, frc_out, exp_out;

    u_frc[4] = bits(i, 31, 31) == 0 ? (uint64_t) (uint32_t) i : (uint64_t) (uint32_t) -i;
    x_nlz = bits(u_frc[4], 32, 17) == 0 ? 0 : 1;
    x_nlz <<= 1;
    u_frc[3] = bits(u_frc[4], 32, 17) == 0 ? u_frc[4] << 16 : u_frc[4];
    x_nlz |= bits(u_frc[3], 32, 25) == 0 ? 0 : 1;
    x_nlz <<= 1;
    u_frc[2] = bits(u_frc[3], 32, 25) == 0 ? u_frc[3] << 8 : u_frc[3];
    x_nlz |= bits(u_frc[2], 32, 29) == 0 ? 0 : 1;
    x_nlz <<= 1;
    u_frc[1] = bits(u_frc[2], 32, 29) == 0 ? u_frc[2] << 4 : u_frc[2];
    x_nlz |= bits(u_frc[1], 32, 31) == 0 ? 0 : 1;
    x_nlz <<= 1;
    u_frc[0] = bits(u_frc[1], 32, 31) == 0 ? u_frc[1] << 2 : u_frc[1];
    x_nlz |= bits(u_frc[0], 32, 32) == 0 ? 0 : 1;
    u_frc_tmp = bits(u_frc[0], 32, 32) == 0 ? u_frc[0] << 1 : u_frc[0];

    tail_any = bits(u_frc_tmp, 7, 0) == 0 ? 0 : 1;
    round = (bits(u_frc_tmp, 8, 8) & tail_any) | ((bits(u_frc_tmp, 9, 9) & bits(u_frc_tmp, 8, 8)));

    u_frc_norm = bits(u_frc_tmp, 32, 9) + round;

    frc_out = bits(u_frc_norm, 23, 23) == 0 ?
              bits(u_frc_norm, 21, 0) :
              bits(u_frc_norm, 22, 0);

    exp_out = bits(u_frc_tmp, 32, 31) == 0 ? 0x00 :
              bits(u_frc_tmp, 32, 31) == 1 ? 0x7F :
              bits(u_frc_norm, 23, 23) == 0 ? 0x80 | bits(x_nlz + 1, 4, 0) :
              0x80 | bits(x_nlz, 4, 0);

    return uint_as_float(bits(i, 31, 31) << 31 | exp_out << 23 | frc_out);
}

int main() {
    uint64_t u;
    for (u = 0; u < 0x100000000ul; u++) {
        float f1 = (float) (int32_t) u;
        float f2 = i_to_f((int32_t) (uint32_t) u);
        if (f1 != f2) {
            printf("%08x %08x %08x\n", (uint32_t) u, float_as_uint(f1), float_as_uint(f2));
            return 1;
        }
    }
    return 0;
}
