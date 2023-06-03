#include <stdio.h>
#include <stdlib.h>
#include "defs.h"

/* 
 * Please fill in the following struct with your name and the name you'd like to appear on the scoreboard
 */
who_t who = {
    "InsaneVayne",           /* Scoreboard name */

    "Sidhardh Sai Burre",   /* Full name */
    "ssb3vk@virginia.edu",  /* Email address */
};

/***************
 * ROTATE KERNEL
 ***************/

/******************************************************
 * Your different versions of the rotate kernel go here
 ******************************************************/

/* 
 * naive_rotate - The naive baseline version of rotate 
 */
char naive_rotate_descr[] = "naive_rotate: Naive baseline implementation";
void naive_rotate(int dim, pixel *src, pixel *dst) 
{
    for (int i = 0; i < dim; i++)
	for (int j = 0; j < dim; j++)
	    dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)];
}
/* 
 * rotate - Your current working version of rotate
 *          Our supplied version simply calls naive_rotate
 */
char another_rotate_descr[] = "another_rotate: Another version of rotate";
void another_rotate(int dim, pixel *src, pixel *dst) 
{
  //int dim1 = dim - 1; 
  for (int i = 0; i < dim; i++){
    for (int j = 0; j < dim; j+=4){
      pixel src1 = src[RIDX(i, j, dim)];
      pixel src2 = src[RIDX(i, j+1, dim)];
      pixel src3 = src[RIDX(i, j+2, dim)];
      pixel src4 = src[RIDX(i, j+3, dim)];

      dst[RIDX(dim-1-j, i, dim)] = src1; 
      dst[RIDX(dim-1-(j+1), i, dim)] = src2;
      dst[RIDX(dim-1-(j+2), i, dim)] = src3; 
      dst[RIDX(dim-1-(j+3), i, dim)] = src4;
      //dst[RIDX(dim-1-(j+4), i, dim)] = src[RIDX(i, j + 4, dim)]; 
      //dst[RIDX(dim-1-(j+5), i, dim)] = src[RIDX(i, j + 5, dim)];
      //dst[RIDX(dim-1-(j+6), i, dim)] = src[RIDX(i, j + 6, dim)]; 
      //dst[RIDX(dim-1-(j+7), i, dim)] = src[RIDX(i, j + 7, dim)];
    }
  }

}

char rotate_unrolled4_description[] = "rotate_unrolled4: rotate unrolled to 4 terms per loop"; 
void rotate_unrolled4(int dim, pixel *src, pixel *dst){
  for (int i = 0; i < dim; i++){
    for (int j = 0; j < dim; j+=4){
      dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)]; 
      dst[RIDX(dim-1-(j+1), i, dim)] = src[RIDX(i, j+1, dim)];
      dst[RIDX(dim-1-(j+2), i, dim)] = src[RIDX(i, j+2, dim)]; 
      dst[RIDX(dim-1-(j+3), i, dim)] = src[RIDX(i, j+3, dim)];
      //dst[RIDX(dim-1-(j+4), i, dim)] = src[RIDX(i, j + 4, dim)]; 
      //dst[RIDX(dim-1-(j+5), i, dim)] = src[RIDX(i, j + 5, dim)];
      //dst[RIDX(dim-1-(j+6), i, dim)] = src[RIDX(i, j + 6, dim)]; 
      //dst[RIDX(dim-1-(j+7), i, dim)] = src[RIDX(i, j + 7, dim)];
    }
  }

}

char rotate_swapped_description[] = "rotate_swapped: rotate but switched loop order"; 
void rotate_swapped(int dim, pixel *src, pixel *dst){
  for (int j = 0; j < dim; j++){
    for (int i = 0; i < dim; i++){
      dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)]; 
    }
  }

}

//this one will be interesting. What I know is that we have 8 ways and 64 byte blocks. We also have 32KB total cache. This indicates that we have a total of 64 sets. Another problem is that we have a variable dimension input value. This is kind of a pickle because I'm lazy and don't want to optimize for each size individually. Instead I'm going to seek to divide the dim value by a factor and work from there. 

char rotate_blocked4_description[] = "rotate_blocked4: rotate with cache blocking"; 
void rotate_blocked4(int dim, pixel *src, pixel *dst){
  for (int jj = 0; jj < dim; jj+=4){
    for (int ii = 0; ii < dim; ii+=4){
      int comp1 = jj+4; 
      for (int j = jj; j < comp1; j+=1){
	int comp2 = ii+4; 
	for (int i = ii; i < comp2; i+=1){
	  dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)]; 
	}
      }
    }
  }

}

char rotate_blocked8_description[] = "rotate_blocked8: rotate with cache blocking 8"; 
void rotate_blocked8(int dim, pixel *src, pixel *dst){
  for (int jj = 0; jj < dim; jj+=8){
    for (int ii = 0; ii < dim; ii+=8){
      int comp1 = jj+8; 
      for (int j = jj; j < comp1; j+=1){
	int comp2 = ii+8; 
	for (int i = ii; i < comp2; i+=1){
	  dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)]; 
	}
      }
    }
  }

}

char rotate_blocked16_description[] = "rotate_blocked16: rotate with cache blocking 16"; 
void rotate_blocked16(int dim, pixel *src, pixel *dst){
  for (int jj = 0; jj < dim; jj+=16){
    for (int ii = 0; ii < dim; ii+=16){
      int comp1 = jj+16; 
      for (int j = jj; j < comp1; j+=1){
	int comp2 = ii+16; 
	for (int i = ii; i < comp2; i+=1){
	  dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)];
	  //dst[RIDX(dim-1-j, i+1, dim)] = src[RIDX(i+1, j, dim)];
	  //dst[RIDX(dim-1-j, i+2, dim)] = src[RIDX(i+2, j, dim)];
	  //dst[RIDX(dim-1-j, i+3, dim)] = src[RIDX(i+3, j, dim)];
	}
      }
    }
  }

}

char rotate_blocked32_description[] = "rotate_blocked32: rotate with cache blocking 32"; 
void rotate_blocked32(int dim, pixel *src, pixel *dst){
  for (int jj = 0; jj < dim; jj+=32){
    for (int ii = 0; ii < dim; ii+=32){
      int comp1 = jj+32; 
      for (int j = jj; j < comp1; j+=1){
	int comp2 = ii+32; 
	for (int i = ii; i < comp2; i+=1){
	  dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)]; 
	}
      }
    }
  }

}

char rotate_preprimed_description[] = "rotate_preprimed: case-based selection of methods";
void rotate_preprimed(int dim, pixel *src, pixel *dst){
  if (dim < 672) {
    return rotate_unrolled4(dim, src, dst); 
  } else {
    return rotate_blocked16(dim, src, dst); 
  }

}

/*********************************************************************
 * register_rotate_functions - Register all of your different versions
 *     of the rotate function by calling the add_rotate_function() for
 *     each test function. When you run the benchmark program, it will
 *     test and report the performance of each registered test
 *     function.  
 *********************************************************************/

void register_rotate_functions() {
    add_rotate_function(&naive_rotate, naive_rotate_descr);
    add_rotate_function(&another_rotate, another_rotate_descr);
    add_rotate_function(&rotate_unrolled4, rotate_unrolled4_description);
    add_rotate_function(&rotate_swapped, rotate_swapped_description); 
    //add_rotate_function(&rotate_blocked4, rotate_blocked4_description); 
    //add_rotate_function(&rotate_blocked8, rotate_blocked8_description); 
    add_rotate_function(&rotate_blocked16, rotate_blocked16_description); //16 appears to be the fastest
    add_rotate_function(&rotate_blocked32, rotate_blocked32_description); 
    add_rotate_function(&rotate_preprimed, rotate_preprimed_description); 
}
