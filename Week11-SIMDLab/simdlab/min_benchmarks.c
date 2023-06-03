#include <stdlib.h>
#include <limits.h>  /* for USHRT_MAX */

#include <immintrin.h>

#include "min.h"
/* reference implementation in C */
short min_C(long size, short * a) {
    short result = SHRT_MAX;
    for (int i = 0; i < size; ++i) {
        if (a[i] < result)
            result = a[i];
    }
    return result;
}

short min_AVX(long size, short * a) {
  __m256i partial_sums = _mm256_set1_epi16(32767); 
  
  for (int i = 0; i < size; i += 16) {
    partial_sums = _mm256_min_epi16(partial_sums, _mm256_loadu_si256((__m256i*) &a[i]) ); 

  }

  short partial_sum_array[16]; 
  _mm256_storeu_si256((__m256i*) partial_sum_array, partial_sums); 

  int result = partial_sum_array[0]; 

  for (int i = 1; i < 16; i++) {
    if (result > partial_sum_array[i]){
      result = partial_sum_array[i]; 
    }
  }

  return result; 

}


/* This is the list of functions to test */
function_info functions[] = {
    {min_C, "C (local)"},
    // add entries here!
    {min_AVX, "AVX implementation of min"}, 
    {NULL, NULL},
};
