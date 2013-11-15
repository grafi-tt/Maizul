#include <stdint.h>
#include <stdio.h>
#include <math.h>

static inline uint64_t bits(uint64_t u, unsigned int i, unsigned int j) {
    return (u & (((uint64_t) 1 << (i + 1)) - ((uint64_t) 1 << j))) >> j;
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

int32_t f_to_i(float f) {
    uint32_t fu = float_as_uint(f);
    uint32_t x_len;
    uint32_t u_frc_4, u_frc_3, u_frc_2, u_frc_1, u_frc_0, u_frc_o, u_frc_v;
    int any_4, any_3, any_2, any_1, any_0, any_o;
    int round;

    x_len = bits(bits(fu, 30, 23) - 0x7E, 8, 0);

    any_4 = 0;
    u_frc_4 = (uint32_t) 1 << 31 | bits(fu, 22, 0) << 8;
    any_3 = bits(x_len, 4, 4) == 0 && bits(u_frc_4, 15, 0) ? 1 : any_4;
    u_frc_3 = bits(x_len, 4, 4) == 0 ? u_frc_4 >> 16 : u_frc_4;
    any_2 = bits(x_len, 3, 3) == 0 && bits(u_frc_3, 7, 0) ? 1 : any_3;
    u_frc_2 = bits(x_len, 3, 3) == 0 ? u_frc_3 >> 8 : u_frc_3;
    any_1 = bits(x_len, 2, 2) == 0 && bits(u_frc_2, 3, 0) ? 1 : any_2;
    u_frc_1 = bits(x_len, 2, 2) == 0 ? u_frc_2 >> 4 : u_frc_2;
    any_0 = bits(x_len, 1, 1) == 0 && bits(u_frc_1, 1, 0) ? 1 : any_1;
    u_frc_0 = bits(x_len, 1, 1) == 0 ? u_frc_1 >> 2 : u_frc_1;
    any_o = bits(x_len, 0, 0) == 0 && bits(u_frc_0, 0, 0) ? 1 : any_0;
    u_frc_o = bits(x_len, 0, 0) == 0 ? u_frc_0 >> 1 : u_frc_0;

    u_frc_v = u_frc_o >> 1;
    round = (bits(u_frc_o, 0, 0) & any_o) | (bits(u_frc_o, 1, 1) & bits(u_frc_o, 0, 0));

    return bits(x_len, 8, 8) == 1 ? INT32_C(0x00000000) :
           bits(fu, 31, 31) == 0 && bits(x_len, 7, 5) ? INT32_C(0x7FFFFFFF) :
           bits(fu, 31, 31) == 1 && bits(x_len, 7, 5) ? INT32_C(0x80000000) :
           (bits(fu, 31, 31) == 0) & (round == 0) ? u_frc_v :
           (bits(fu, 31, 31) == 0) & (round == 1) ? u_frc_v + 1:
           round == 0 ? -u_frc_v :
           ~u_frc_v;
}

int main() {
    uint32_t u;
    for (u = 0; u <= UINT32_C(0xFF800000); u++) {
        if (UINT32_C(0x7F800000) < u && u < UINT32_C(0x80000000)) continue;
        int64_t il1 = lrint(uint_as_float(u));
        int32_t i1 = il1 > INT32_MAX ? INT32_MAX : il1 < INT32_MIN ? INT32_MIN : il1;
        int32_t i2 = f_to_i(uint_as_float(u));
        if (i1 != i2) {
            printf("%08x %08x %08x\n", u, i1, i2);
            return 1;
        }
    }
    return 0;
}
