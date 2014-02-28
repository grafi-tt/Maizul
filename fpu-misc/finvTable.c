/* written by panooz */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main() {
  int i, cons[1024], grad[1024];
  for (i=0; i<1024; i++) {
    float A0 = i+1024, x0 = (1/A0 + 1/(A0+1)) / (1<<14);
    cons[i] = pow(2,48) * x0 - pow(2,60) * x0 * x0 * A0;
    grad[i] = pow(2,47) * x0 * x0 * (1<<12);
  }

  int A0, A1;
  int diffMax = 0;
  for (A0=0; A0<(1<<10); A0++) {
    for (A1=0; A1<(1<<13); A1++) {
      union {
        int i;
        float f;
      } u;
      u.i = (127 << 23) | (A0 << 13) | A1;
      u.f = 1/u.f;
      int M = (1<<23) + (u.i & ((1<<23)-1));
      int finvman;
      if (A0 || A1) {
        finvman = cons[A0] - ((grad[A0]*A1) >> 12);
      } else {
        finvman = (1<<23);
      }
      int diff = M - finvman;
      if (diffMax < diff) diffMax = diff;
    }
  }
  fprintf(stderr, "diffMax = %d\n", diffMax);

  for (i=0; i<1024; i++) {
    int a, b;
    a = (cons[i] << 9) | (grad[i] >> 4);
    b = grad[i] & ((1<<4)-1);
    printf("%08X%X\n", a, b);
  }

  return 0;
}
