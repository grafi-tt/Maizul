#include <stdio.h>
int main() {
    union {
        float f;
        unsigned int i;
    } box;
    while (scanf("%f", &box.f) == 1)
        printf("%u\n", box.i);
    return 0;
}
