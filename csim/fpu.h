#include <math.h>
#include <stdint.h>

static inline uint32_t float_as_uint(float f) {
    static union {
        uint32_t i;
        float f;
    } _box;
    _box.f = f;
    return _box.i;
}

static inline float uint_as_float(uint32_t i) {
    static union {
        uint32_t i;
        float f;
    } _box;
    _box.i = i;
    return _box.f;
}

static inline float kill_denormal(float f) {
    uint32_t i = float_as_uint(f);
    if (i & UINT32_C(0x7F800000))
        return f;
    else {
        return uint_as_float(i & UINT32_C(0xFF800000));
    }
}

static inline float fadd_native(float a, float b) {
    return kill_denormal(a + b);
}

static inline float fsub_native(float a, float b) {
    return kill_denormal(a - b);
}

static inline float fmul_native(float a, float b) {
    return kill_denormal(a * b);
}

static inline float itof_native(int32_t i) {
    return (float) i;
}

static inline float ftoi_native(float f) {
    int64_t l = lrint(f);
    return l > INT32_MAX ? INT32_MAX : l < INT32_MIN ? INT32_MIN : l;
}

static inline float fflr_native(float f) {
    return floorf(f);
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

float itof_circuit(int32_t i);
int32_t ftoi_circuit(float f);
float fflr_circuit(float f);
float finv_soft(float a);
float fsqr_soft(float a);
