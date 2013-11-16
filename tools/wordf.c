#include <stdio.h>
int main() {
    union {
        float f;
        unsigned int i;
    } box;
    unsigned int temp[4];
    while (scanf("%x %x %x %x", temp, temp+1, temp+2 ,temp+3) == 4) {
        box.i = 0;
        int i;
        for (i = 0; i < 4; i++) {
            box.i <<= 8;
            box.i |= temp[i] & 255;
        }
        printf("%f\n", box.f);
    }
    return 0;
}
