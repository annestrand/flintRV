# Copyright (c) 2022 Austin Annestrand
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#! /usr/bin/env python3

import os
import sys

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"[{os.path.basename(__file__)} - Error]: No input file given.")
        exit(1)
    if not os.path.exists(sys.argv[1]):
        print(f"[{os.path.basename(__file__)} - Error]: Input file does not exist: [ {sys.argv[1]} ]")
        exit(1)

    # Perform the byteswap and update file in-place
    count = 0
    swapped_machine_words = ""
    with open(sys.argv[1], 'r') as fp:
        machine_words = fp.read().split()
        if not machine_words[0].startswith('@'):
            print(f"[{os.path.basename(__file__)} - Error]: Input file is not a Verilog mefile: [ {sys.argv[1]} ]")
            exit(1)
        for word in machine_words:
            if word.startswith('@'):
                swapped_machine_words += (word + os.linesep) if count == 0 else (os.linesep + word + os.linesep)
            else:
                swapped_machine_words += word[6:8] + word[4:6] + word[2:4] + word[0:2] + " "
                count += 1
                if count >= 4:
                    swapped_machine_words += os.linesep
                    count = 0
    with open(sys.argv[1], 'w') as fp:
        fp.write(swapped_machine_words)
