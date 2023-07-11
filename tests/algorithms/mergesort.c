// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

#include <stdio.h>
#include <stdlib.h>

void _start(void);
void _drop32_start(void) {
    _start();
    for(;;);
}

// Need to define our own implementation for this system call since we use Newlib for libc
void* _sbrk(int incr) {
  extern char _end; // From linker script
  static char *heap = NULL;

  if (heap == NULL) { heap = (char*)&_end; }
  char* prev_heap = heap;

  // Collision check
  register long sp asm("sp");
  if ((heap + incr) > (char*)sp) { return NULL; }

  heap += incr;
  return (void*)prev_heap;
}

void mergeHalves(int* arr, int* tmpArr, int l, int m, int r) {
    int len     = (r-l)+1;
    int tmpM    = m;
    int start   = l;
    if (len == 2) {
        if (arr[l] < arr[tmpM]) { tmpArr[start] = arr[l]; tmpArr[start+1] = arr[r]; }
        else                    { tmpArr[start] = arr[r]; tmpArr[start+1] = arr[l]; }
    } else {
        for (int i=0; i<len; ++i) {
            if      (l >= m)                { tmpArr[start+i] = arr[tmpM++];    }
            else if (tmpM > r)              { tmpArr[start+i] = arr[l++];       }
            else if (arr[l] < arr[tmpM])    { tmpArr[start+i] = arr[l++];       }
            else                            { tmpArr[start+i] = arr[tmpM++];    }
        }
    }
    // Update the original array
    for (int i=0; i<len; ++i) { arr[start+i] = tmpArr[start+i]; }
}

void recursiveMergesort(int* arr, int* tmpArr, int l, int r) {
    if (l < r) {
        int m = (l+r)/2;
        recursiveMergesort(arr, tmpArr, l, m);
        recursiveMergesort(arr, tmpArr, m+1, r);
        mergeHalves(arr, tmpArr, l, m+1, r);
    }
}

void myMergesort(int* arr, int len) {
    int* tmpStore = (int*)malloc(len*sizeof(int));
    recursiveMergesort(arr, tmpStore, 0, len-1);
    free(tmpStore);
}

// ====================================================================================================================
int main() {
    // Gold (sorted) data
    const int testArrSorted[] = {
        4, 5, 8, 9, 10, 12, 14, 18, 20, 21, 23, 24, 26, 29, 32, 33, 35, 36, 37,
        38, 38, 39, 40, 42, 43, 47, 49, 50, 51, 61, 64, 65, 70, 71, 72, 74, 75,
        76, 77, 79, 80, 84, 86, 87, 89, 90, 91, 92, 93, 101, 102, 103, 109, 111,
        112, 113, 114, 116, 117, 121, 122, 123, 124, 128, 129, 131, 134, 135, 136,
        138, 141, 144, 148, 150, 151, 152, 153, 155, 157, 158, 161, 162, 163, 164,
        166, 167, 169, 170, 177, 179, 180, 184, 185, 190, 191, 194, 196, 198, 199,
        200
    };
    int testArr[] = {
        151, 65, 101, 38, 102, 157, 89, 191, 21, 36, 64, 5, 91, 200, 37, 84,
        117, 14, 162, 109, 23, 10, 148, 128, 136, 185, 135, 121, 35, 79, 61,
        122, 131, 90, 153, 199, 71, 103, 38, 179, 70, 124, 18, 114, 150, 196,
        50, 87, 169, 138, 144, 163, 111, 134, 42, 32, 164, 74, 113, 141, 116,
        72, 123, 39, 29, 20, 194, 170, 161, 49, 75, 9, 198, 24, 76, 190, 33,
        80, 167, 180, 51, 177, 112, 40, 8, 184, 43, 26, 158, 155, 47, 166,
        129, 86, 12, 93, 77, 92, 4, 152
    };
    int len = sizeof(testArr)/sizeof(int);
    myMergesort(testArr, len);

    // Pass back both array addresses and array length to simulator
    register long s8  asm("s8")     = len;
    register long s9  asm("s9")     = (long int)testArr;
    register long s10 asm("s10")    = (long int)testArrSorted;
    asm("ebreak");
    return 0;
}