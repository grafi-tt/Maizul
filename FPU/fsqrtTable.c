#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main() {
  FILE *fp;
  char filename[] = "fsqrtTable.txt";
  if ((fp = fopen(filename, "w")) == NULL) {
    exit(1);
  }
  
  int i, cons[1024], grad[1024];
  for (i=0; i<512; i++) { // 指数が偶数
    float A0 = i+512, x0 = (sqrt(A0) + sqrt(A0+1)) * (1<<6);
    cons[i] = A0/x0 * (1<<25) + x0 * (1<<11);
    grad[i] = (1<<24) / x0;
  }
  for (i=512; i<1024; i++) { // 指数が奇数
    float A0 = i, x0 = (sqrt(A0) + sqrt(A0+1)) * (1<<6) * sqrt(2);
    cons[i] = A0/x0 * (1<<25) + x0 * (1<<10);
    grad[i] = (1<<24) / x0;
  }

  int A0, A1;
  int diffMax = 0;
  for (A0=0; A0<(1<<10); A0++) {
    for (A1=0; A1<(1<<14); A1++) {
      union {
	int i;
	float f;
      } u;
      u.i = (63 << 24) | (A0 << 14) | A1;
      u.f = sqrt(u.f);
      int M = (1<<23) + (u.i & ((1<<23)-1));
      int fsqrtman;
      fsqrtman = cons[A0] + ((grad[A0]*A1) >> 13);
      int diff = abs(M - fsqrtman);
      if (diffMax < diff) diffMax = diff;
    }
  }
  printf("diffMax = %d\n", diffMax);

  for (i=0; i<1024; i++) {
    int a, b;
    a = (cons[i] << 9) | (grad[i] >> 4);
    b = grad[i] & ((1<<4)-1);
    fprintf(fp, "x\"%08X%X\",\n", a, b);
  }

  return 0;
}
