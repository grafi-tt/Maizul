#include <stdio.h>
#include <string.h>

typedef struct {
    const char *name;
    int (*fp)();
} test_t;

static test_t tests[];

int main(int argc, char *argv[]) {
    int argc2 = 1;
    if (argc > 1) {
        for (int i = 0; tests[i].name; i++) {
            int j;
            for (j = 1; j < argc; j++)
                if (argv[j] && !strcmp(tests[i].name, argv[j])) {
                    argv[j] = NULL;
                    argc2++;
                    break;
                }
            if (j == argc)
                tests[i].name = NULL;
        }
        if (argc != argc2) {
            puts("some of specified tests not available:");
            for (int j = 1; j < argc; j++) {
                if (argv[j]) puts(argv[j]);
            }
            return 1;
        }
    }
    for (int i = 0; tests[i].fp; i++) {
        if (!tests[i].name) continue;
        printf("executing %s:\n", tests[i].name);
        int e = tests[i].fp();
        if (e) {
            printf("test failed\n");
            return 1;
        }
    }
    printf("all test succeeded\n");
    return 0;
}

/* test definition */
#include "fpu.h"
int test_ftoi_circuit() {
    uint32_t u;
    for (u = 0; u <= UINT32_C(0xFF800000); u++) {
        if (
            (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) ||
            (UINT32_C(0x7F800000) < u && u < UINT32_C(0x80000000)) ||
            (UINT32_C(0x80000000) < u && u < UINT32_C(0x80800000))
        ) continue;
        int32_t i1 = ftoi_native(uint_as_float(u));
        int32_t i2 = ftoi_circuit(uint_as_float(u));
        if (i1 != i2) {
            printf("%08x %08x %08x\n", u, i1, i2);
            return 1;
        }
    }
    return 0;
}

int test_itof_circuit() {
    uint32_t u = 0;
    do {
        float f1 = itof_native((int32_t) u);
        float f2 = itof_circuit((int32_t) u);
        if (f1 != f2) {
            printf("%08x %08x %08x\n", u, float_as_uint(f1), float_as_uint(f2));
            return 1;
        }
        u++;
    } while (u != 0);
    return 0;
}

int test_fflr_circuit() {
    uint32_t u;
    for (u = 0; u <= UINT32_C(0xFF800000); u++) {
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

int test_fsqr_circuit() {
    uint32_t u;
    int bound = 0;
    int c;
    for (u = 0; u <= UINT32_C(0x7f800000); u++) {
        if (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) continue;

        float f1 = fsqr_native(uint_as_float(u));
        float f2 = fsqr_circuit(uint_as_float(u));
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

int test_finv_soft() {
    uint32_t u;
    int bound = 0;
    int c;
    for (u = 0; u < UINT32_C(0xFF800000); u++) {
        if (
            (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) ||
            (UINT32_C(0x7F800000) < u && u < UINT32_C(0x80000000)) ||
            (UINT32_C(0x80000000) < u && u < UINT32_C(0x80800000))
        ) continue;

        float f1 = kill_denormal(1 / (uint_as_float(u)));
        float f2 = finv_soft(uint_as_float(u));
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

int test_fsqr_soft() {
    uint32_t u;
    int bound = 0;
    int c;
    for (u = 0; u <= UINT32_C(0x7F800000); u++) {
        if (UINT32_C(0x00000000) < u && u < UINT32_C(0x00800000)) continue;

        float f1 = kill_denormal(sqrtf(uint_as_float(u)));
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

static test_t tests[] = {
    { "ftoi_circuit", test_ftoi_circuit },
    { "itof_circuit", test_itof_circuit },
    { "fflr_circuit", test_fflr_circuit },
    { "fsqr_circuit", test_fsqr_circuit },
    { "finv_soft", test_finv_soft },
    { "fsqr_soft", test_fsqr_soft },
    { NULL, NULL }
};
