#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/stat.h>
#include <stdint.h>

#define	syscall_exit            1
#define	syscall_read            4
#define	syscall_write           5

// syscall helper =====================================================================================================

static long syscall(long syscall_type, long arg0, long arg1, long arg2) {
  // Setup argument regs and perform the syscall
  register long a0          asm("a0") = arg0;
  register long a1          asm("a1") = arg1;
  register long a2          asm("a2") = arg2;
  register long syscall_id  asm("a7") = syscall_type;
  asm volatile("scall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(syscall_id));

  // Error handling
  if (a0 < 0) {
    errno = -a0;
    return -1;
  }

  return a0;
}

// Stubs ==============================================================================================================

void _exit(int status) {
  syscall(syscall_exit, status, 0, 0);
  for(;;);
}

ssize_t _write(int file, const void *ptr, size_t len) {
  syscall(syscall_write, (long)file, (long)ptr, (long)len);
  return len; // rISA writes all the chars here, so we just return len (finished)
}

ssize_t _read(int file, void *ptr, size_t len) {
  return syscall(syscall_read, (long)file, (long)ptr, (long)len);
}

int _fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

void *_sbrk(int incr) {
  extern char _end;
  static char *heap = NULL;
  char *prev_heap;

  if (heap == NULL) {
    heap = (char*)&_end;
  }
  prev_heap = heap;

  // Collision check
  register long sp asm("sp");
  if ((long)(heap + incr) > sp) {
    return NULL;
  }

  heap += incr;
  return (void*)prev_heap;
}

int _getpid(void)                       { return 1;     }
int _close(int file)                    { return -1;    }
int _isatty(int file)                   { return 1;     }
int _lseek(int file, int ptr, int dir)  { return 0;     }
void _kill(int pid, int sig)            { return;       }
