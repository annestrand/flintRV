FROM devbored/riscv-gnu-toolchain:2022.02.25

ARG UID
ARG GID

RUN apk add build-base cmake

RUN addgroup --gid $GID user
RUN adduser --disabled-password --gecos '' --uid $UID --ingroup user user
USER user