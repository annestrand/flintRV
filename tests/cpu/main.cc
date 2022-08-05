#include <gtest/gtest.h>
#include "boredcore.hh"

const int* g_argc;
const char** g_argv;

int main(int argc, char *argv[]) {
  g_argc = &argc;
  g_argv = (const char**)argv;
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
