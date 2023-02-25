# Copyright (c) 2022 - present, Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

FROM devbored/riscv-gnu-toolchain:2022.02.25

ARG UID=1000
ARG GID=1000

RUN addgroup --gid $GID user
RUN adduser --disabled-password --gecos '' --uid $UID --ingroup user user
USER user