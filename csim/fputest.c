#include <stdio.h>
#include "fpu.h"

int main() {
    uint32_t u;
    for (u = 0x00000000; u <= UINT32_C(0xFF800000); u++) {
        if (
            (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) ||
            (UINT32_C(0x7F800000) < u && u < UINT32_C(0x80000000)) ||
            (UINT32_C(0x80000000) < u && u < UINT32_C(0x80800000))
        ) continue;
        float g1 = fflr_native(uint_as_float(u));
        float g2 = fflr_circuit(uint_as_float(u));
        uint32_t u1 = float_as_uint(g1);
        uint32_t u2 = float_as_uint(g2);
        if (u1 != u2) {
            printf("%08x %08x %08x\n", u, u1, u2);
            return 1;
        }
    }
    return 0;
}
