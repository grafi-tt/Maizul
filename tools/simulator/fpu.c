#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "fpu.h"
#include "fpu-table.h"

static inline uint64_t bits(uint64_t u, unsigned int i, unsigned int j) {
    return (u & (((uint64_t) 1 << (i + 1)) - ((uint64_t) 1 << j))) >> j;
}

float itof_circuit(int32_t i) {
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

int32_t ftoi_circuit(float f) {
    uint32_t fu = float_as_uint(f);
    uint32_t sgn;
    uint32_t x_len;
    uint32_t u_frc_4, u_frc_3, u_frc_2, u_frc_1, u_frc_0, u_frc_o, u_frc_v, u_frc_v2;
    uint32_t any_4, any_3, any_2, any_1, any_0, any_o;
    uint32_t i_err;
    uint32_t err, round;

    sgn = bits(fu, 31, 31);
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

    i_err = bits(x_len, 8, 8) == 1 ? UINT32_C(0x00000000) :
            sgn == 0 ? UINT32_C(0x7FFFFFFF) :
            UINT32_C(0x80000000);
    err = (bits(x_len, 8, 8) == 1) | (bits(x_len, 7, 5) != 0);
    u_frc_v2 = sgn == 0 ? u_frc_v : ~u_frc_v;
    return err ? i_err : u_frc_v2 + (sgn ^ round);
}

float fflr_circuit(float f) {
    uint32_t fu = float_as_uint(f);
    unsigned int len, len_raw;
    uint32_t x_mask, incr;
    uint32_t f_masked, f_incr;
    uint32_t f_out;

    len_raw = bits(fu, 30, 23) - 0x7F;
    len = bits(len_raw, 8, 8) == 1 ? 0 : bits(len_raw, 7, 5) != 0 ? 31 : bits(len_raw, 4, 0);
    x_mask = UINT32_C(0x007FFFFF) >> len;
    incr = (x_mask << 1) ^ 1 ^ x_mask;

    f_masked = bits(fu, 30, 0) & ~x_mask;
    f_incr = f_masked + incr;
    f_out = (bits(fu, 31, 31) == 0 || bits(fu, 30, 0) == f_masked) ? f_masked : f_incr;

    uint32_t ret =
        (bits(fu, 31, 31) == 0 || bits(fu, 30, 23) == 0) && bits(len_raw, 8, 8) == 1 ? bits(fu, 31, 31) << 31 | 0x00 << 23 | bits(f_out, 22, 0) :
        bits(fu, 31, 31) == 1 && bits(len_raw, 8, 8) == 1 ? bits(fu, 31, 31) << 31 | 0x7F << 23 | bits(f_out, 22, 0) :
        bits(fu, 31, 31) << 31 | f_out;
    return uint_as_float(ret);
}

/* 5ulp */
float finv_circuit(float f) {
    if (isinf(f)) return copysign(0, f);
    if (isnan(f)) return f;
    uint32_t u = float_as_uint(f);

    uint32_t sgn, exp_in, key, rest;
    uint32_t a0, a1, t1;
    uint32_t frc_out, exp_out;
    uint32_t frc_any, no_flow1, no_flow2;
    uint32_t ret;

    key = bits(u, 22, 13);

    sgn = bits(u, 31, 31);
    exp_in = bits(u, 30, 23);
    rest = bits(u, 12, 0);
    frc_any = bits(u, 22, 0) != 0;
    a0 = bits(finv_table[key], 35, 13);
    a1 = bits(finv_table[key], 12, 0);

    no_flow1 = exp_in != 0xFD;
    no_flow2 = exp_in != 0xFE;
    t1 = bits(a1 * rest, 25, 12);

    if (exp_in == 0) {
        exp_out = 0xFF;
    }
    else {
        exp_out = bits(0xFE - exp_in - (frc_any & no_flow2), 7, 0); /* when exp == 254, exp_out is fixed to 0 */
    }
    if (frc_any && no_flow1 && no_flow2) {
        frc_out =  bits(a0 - t1, 22, 0);
    } else {
        frc_out = 0;
    }
    ret = sgn << 31 | exp_out << 23 | frc_out;

    return uint_as_float(ret);
}

/* 3ulp */
float fsqr_circuit(float f) {
    if (f == INFINITY) return f;
    if (f == -INFINITY) return sqrt(f);
    if (isnan(f)) return f;
    uint32_t u = float_as_uint(f);

    uint32_t sgn_in, exp_in, key, rest;
    uint32_t a0, a1, t1;
    uint32_t frc_out, exp_out;
    uint32_t ret;

    key = bits(u, 23, 14);

    sgn_in = bits(u, 31, 31);
    exp_in = bits(u, 30, 23);
    rest = bits(u, 13, 0);
    a0 = bits(fsqr_table[key], 35, 13);
    a1 = bits(fsqr_table[key], 12, 0);

    t1 = bits(a1 * rest, 26, 13);

    if (exp_in == 0) {
        exp_out = 0x00;
        frc_out = 0;
    } else if (sgn_in == 1) {
        exp_out = 0xFF;
        frc_out = 1;
    } else {
        exp_out = bits(0x3F + bits(exp_in, 7, 1) + bits(exp_in, 0, 0), 7, 0);
        frc_out = bits(a0 + t1, 22, 0);
    }

    ret = exp_out << 23 | frc_out;
    return uint_as_float(ret);
}

/* x87との誤差2ulpを達成してた．非正規化数が絡むulp計算を手抜きするために2^-126より小さい結果になるなら（偶数丸めにせず）0に落としてしまっている． */
float finv_soft(float a) {
    if (a == 0) return copysign(INFINITY, a);
    if (fabs(a) >= scalbn(1.0f, 127)) return copysign(0.0f, a);
    uint32_t bin = float_as_uint(a);
    float x = uint_as_float(UINT32_C(0x7f000000) - bin);
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    x = fmul_native(x, fsub_native(2.0f, fmul_native(a, x)));
    return x;
}

/* x87との誤差3ulpを達成してた．aが0のときの処理はやってないけど何故かちゃんと動く． */
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
