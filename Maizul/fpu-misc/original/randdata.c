/* written by panooz */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
  
#define DATANUM 100000

int rand_int() {
  int i,r=0;

  for (i=0; i<32; i++) {
    r += rand()%2 * (0x1 << i);
  }
  return r;
}

void printBit(FILE *fp, int n) {
  int i;
  for (i=31; i>=0; i--) {
    int b = (n >> i) & 0x1;
    fprintf(fp, "%d", b);
  }

}

int main(int argc, char *argv[]) {
  FILE *fp;
  if ((fp = fopen("testdata.txt", "w")) == NULL) {
    perror("file open error");
    exit(1);
  }

  int a,b,i;
  float fa,fb,fc;

  srand((unsigned)time(NULL));

  printf("%s\n", argv[1]);

  for (i=0; i<DATANUM; i++) {
    a = rand_int();
    b = rand_int();
    union {
      int i;
      float f;
    } u;
    u.i = a;
    fa = u.f;
    u.i = b;
    fb = u.f;

    if (strcmp(argv[1], "add") == 0) {
      fc = fa+fb;
    } else if (strcmp(argv[1], "mul") == 0) {
      fc = fa*fb;
    } else if (strcmp(argv[1], "inv") == 0) {
      fc = 1/fa;
    }
      
    u.f = fc;
   
    printBit(fp,a);
    fprintf(fp, " ");
    if (strcmp(argv[1], "inv") != 0) {
      printBit(fp,b);
      fprintf(fp, " ");
    }
    printBit(fp,u.i);
    fprintf(fp,"\n");

  }
  fclose(fp);

  return 0;
}
