/* per-call timing of im_engine_process_interleaved on a WAV, block N */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "im_engine.h"
#include "wav.h"
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}
static int cmp(const void*a,const void*b){double x=*(double*)a,y=*(double*)b;return x<y?-1:x>y;}
int main(int argc,char**argv){
  const char*model=argv[1],*in=argv[2]; int block=atoi(argv[3]); int mono=argc>4?atoi(argv[4]):0; int reps=argc>5?atoi(argv[5]):3;
  char err[256]; wav_t w; if(!wav_read(in,&w,err,sizeof err)){puts(err);return 1;}
  im_config c={model,w.channels,w.rate,1,mono,NULL}; im_engine*e; if(im_engine_create(&c,&e,err,sizeof err)){puts(err);return 1;}
  long nb=w.frames/block; double*t=malloc(sizeof(double)*nb*reps); float*o=malloc(sizeof(float)*block*w.channels); long k=0; double tot=0;
  for(int r=0;r<reps;r++) for(long i=0;i<nb;i++){double a=now(); im_engine_process_interleaved(e,w.data+(size_t)i*block*w.channels,o,block); t[k]=now()-a; tot+=t[k++];}
  qsort(t,k,sizeof(double),cmp);
  double audio=(double)k*block/w.rate;
  printf("block=%d mono=%d calls=%ld rtf=%.3f mean=%.3fms p50=%.3fms p99=%.3fms p99.9=%.3fms max=%.3fms (block period %.2fms)\n",
    block,mono,k,tot/audio,1e3*tot/k,1e3*t[k/2],1e3*t[(long)(k*0.99)],1e3*t[(long)(k*0.999)],1e3*t[k-1],1e3*block/w.rate);
  return 0;}
