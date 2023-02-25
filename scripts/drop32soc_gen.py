#!/usr/bin/env python

# Copyright (c) 2023 - present, Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

import re
import os
import sys
import subprocess

# Basic convenience script to bundle all example drop32soc example srcs together
if __name__ == "__main__":
    # Setup cmd
    core_gen_path   = os.path.abspath(os.path.join(os.path.dirname(__file__), "core_gen.py"))
    command         = f"{sys.executable} {core_gen_path} -if none -pc 0x0 -isa RV32I -name CPU -ilat 1".split()
    # Run core_gen.py
    core_rtl        = subprocess.run(command, stdout=subprocess.PIPE, encoding='utf-8').stdout
    # Concatenate [SoC srcs + core] to 1 file
    src_dir         = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "drop32soc"))
    soc_srcs        = [os.path.join(src_dir, "bootrom.v"), os.path.join(src_dir, "drop32soc.v")]
    # Output core RTL
    core_rtl        = re.sub(r"\[ core_gen.py \]", f"[ {os.path.basename(__file__)} ]", core_rtl)
    print(core_rtl)
    # Output SoC RTL
    for src_file in soc_srcs:
        with open(os.path.join(src_dir, src_file)) as src_file_fp:
            src_code = src_file_fp.read()

            # Remove unwanted items from final file
            src_code = re.sub(r"`include .*\n\n", "", src_code)
            src_code = re.sub(r"/\*verilator public\*/", "", src_code)
            src_code = re.sub(r"// Copyright.*" + (r"\n.*" * 2) + r"\n", "", src_code)
            src_code = re.sub(r"\[ core_gen.py \]", f"[ {__file__} ]", src_code)

            print("// " + "="*117)
            print(src_code)