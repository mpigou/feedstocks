FROM mambaorg/micromamba:ubuntu24.04
USER root

RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
      pkg-config \
      software-properties-common \
      sudo \
    && rm -rf /var/lib/apt/lists/* \
    && userdel -r -f ubuntu \
    && ln -s micromamba /usr/bin/conda
