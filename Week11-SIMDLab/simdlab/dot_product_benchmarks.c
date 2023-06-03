#include <stdlib.h>

#include <immintrin.h>

#include "dot_product.h"
/* reference implementation in C */
unsigned int dot_product_C(long size, unsigned short * a, unsigned short *b) {
    unsigned int sum = 0;
    for (int i = 0; i < size; ++i) {
        sum += a[i] * b[i];
    }
    return sum;
}

unsigned int dot_product_AVX(long size, unsigned short * a, unsigned short *b) {
  __m256i partial_sum = _mm256_setzero_si256(); 

  for (int i = 0; i < size; i += 8) {
    __m256i partial_a = _mm256_cvtepu16_epi32(_mm_loadu_si128( (__m128i*) &a[i]) ); 
    __m256i partial_b = _mm256_cvtepu16_epi32(_mm_loadu_si128( (__m128i*) &b[i]) ); 
    partial_sum = _mm256_add_epi32( partial_sum, _mm256_mullo_epi32( partial_a, partial_b) ); 
				   
  }

  int partial_sum_array[8]; 
  _mm256_storeu_si256( (__m256i*) partial_sum_array, partial_sum ); 
    
  int result = 0; 

  for (int i = 0; i < 8; i++) {
    result += partial_sum_array[i]; 
  }
    
  return result; 

}

// add prototypes here!
extern unsigned int dot_product_gcc7_O3(long size, unsigned short * a, unsigned short *b);

/* This is the list of functions to test */
function_info functions[] = {
    {dot_product_C, "C (local)"},
    {dot_product_gcc7_O3, "C (compiled with GCC7.2 -O3 -mavx2)"},
    // add entries here!
    {NULL, NULL},
};
