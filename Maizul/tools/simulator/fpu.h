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

static inline int32_t ftoi_native(float f) {
    if (f > (int64_t) INT32_MAX + 2) return INT32_MAX;
    if (f < (int64_t) INT32_MIN - 2) return INT32_MIN;
    int64_t l = lrint(f);
    if (l > INT32_MAX) return INT32_MAX;
    if (l < INT32_MIN) return INT32_MIN;
    return l;
}

static inline float fflr_native(float f) {
    return floorf(f);
}

static inline float finv_native(float f) {
    return kill_denormal(1 / f);
}

static inline float fsqr_native(float f) {
    return kill_denormal(sqrtf(f));
}

/* TODO: consider denormalized number */
static inline int count_ulp(float x, float y, int lim) {
    if (isnan(x) && isnan(y)) return 0;
    if (isnan(x) || isnan(y)) return -1;
    if (isinf(x) && isinf(y)) return signbit(x) == signbit(y) ? 0 : -1;
    if (isinf(x) || isinf(y)) return -1;
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
float finv_circuit(float f);
float fsqr_circuit(float f);
float finv_soft(float f);
float fsqr_soft(float f);
