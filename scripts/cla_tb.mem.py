#! /usr/bin/env python3

import os

test_vector =  f"{0xdeadbeef:x}\n"
test_vector += f"{0xbaddf00d:x}\n"
test_vector += f"{0xc0ffeeee:x}\n"

if __name__ == "__main__":
    outfile = f"{os.path.join('build', os.path.splitext(os.path.splitext(os.path.basename(__file__))[0])[0])}.mem"
    with open(outfile, 'w') as fp:
        print(test_vector, file=fp)
