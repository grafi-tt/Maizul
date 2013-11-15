#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

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

static inline float kill_denormal(float f) {
    _box.f = f;
    if (bits(_box.i, 30, 23))
        return _box.f;
    else {
        _box.i &= -((int32_t) 1 << 23);
        return _box.f;
    }
}

float fadd_native(float a, float b) {
    return kill_denormal(a + b);
}

float fsub_native(float a, float b) {
    return kill_denormal(a - b);
}

float fmul_native(float a, float b) {
    return kill_denormal(a * b);
}

float finv_soft(float a) {
    if (a == 0.0f) return copysign(INFINITY, a);
    if (fabs(a) >= scalbn(1.0f, 127)) return copysign(0.0f, a);
    uint32_t bin = float_as_uint(a);
    float x = uint_as_float(UINT32_C(0x7f000000) - bin);
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    return x;
}

float fsqr_soft(float a) {
    if (a == INFINITY) return a;
    float ahalf = 0.5f * a;
    uint32_t bin = float_as_uint(a);
    float x = uint_as_float(UINT32_C(0x5f400000) - (bin >> 1));
    x = fmul_native(x, (fsub_native(1.5f, fmul_native(fmul_native(ahalf, x), x))));
    x = fmul_native(x, (fsub_native(1.5f, fmul_native(fmul_native(ahalf, x), x))));
    x = fmul_native(x, (fsub_native(1.5f, fmul_native(fmul_native(ahalf, x), x))));
    return fmul_native(a, x);
}

static inline int count_ulp(float x, float y, int lim) {
    if (isnan(x) || isnan(y)) return -1;
    if (isinf(x) && isinf(y)) return signbit(x) == signbit(y) ? 0 : -1;
    int n = 0;
    while (x != y) {
        if (n == lim) return -1;
        x = nextafterf(x, y);
        n++;
    }
    return n;
}

int main() {
    uint32_t u;
    int bound = 0;
    int c;
    for (u = 0; u < 0x7f800000; u++) {
        if (
            (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) ||
            (UINT32_C(0x7F800000) < u && u < UINT32_C(0x80000000)) ||
            (UINT32_C(0x80000000) < u && u < UINT32_C(0x80800000))
        ) continue;

        float f1 = sqrtf(uint_as_float(u));
        float f2 = fsqr_soft(uint_as_float(u));
        c = count_ulp(f1, f2, 7);
        if (c == -1) {
            printf("%08x %08x %08x\n", u, float_as_uint(f1), float_as_uint(f2));
            return 1;
        }
        if (c > bound) bound = c;
    }
    printf("%d\n", bound);
    return 0;
}
