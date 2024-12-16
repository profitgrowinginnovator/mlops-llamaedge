FROM ubuntu:24.04 AS ubuntu-base
RUN apt update && apt install -y wget
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
RUN dpkg -i cuda-keyring_1.1-1_all.deb
RUN rm cuda-keyring_1.1-1_all.deb
FROM ubuntu-base AS ubuntu-cuda
RUN apt update && apt upgrade -y \
 && apt install -y \
 software-properties-common \
 wget \
 cmake \
 ninja-build \
 curl \
 git \
 dpkg-dev \
 libedit-dev \
 libcurl4-openssl-dev \
 llvm-18-dev \
 liblld-18-dev \
 libpolly-18-dev \
 gcc \
 rpm \
 ccache \
 dpkg-dev \
 zlib1g-dev \
 g++ \                 
 cuda-nvcc-12-6 \
 cuda-cudart-12-6 \
        libcublas-dev-12-6 \
 libcublas-12-6 \
 libtinfo6
RUN rm -rf /var/lib/apt/lists/*

ENV CC=gcc
ENV CXX=g++
RUN find / -name nvcc
RUN git clone https://github.com/WasmEdge/WasmEdge.git
RUN cd WasmEdge
RUN mkdir -p /build
RUN export CXXFLAGS="-Wno-error"
RUN export CUDAARCHS="80;90"
RUN cmake -S /WasmEdge -B /build -G Ninja \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_CUDA_ARCHITECTURES="80;90" \
 -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
 -DWASMEDGE_PLUGIN_WASI_NN_GGML_LLAMA_BLAS=OFF \
   -DWASMEDGE_PLUGIN_WASI_NN_GGML_LLAMA_CUBLAS=ON \
 -DWASMEDGE_BUILD_TESTS=OFF  \
 -DWASMEDGE_PLUGIN_WASI_LOGGING=ON \
 -DWASMEDGE_BUILD_PLUGINS=ON \
 -DWASMEDGE_PLUGIN_WASI_NN_BACKEND=GGML \
 -DWASMEDGE_BUILD_EXAMPLE=OFF \
 -DWASMEDGE_BUILD_STATIC_LIB=ON \
 -DWASMEDGE_LINK_LLVM_STATIC=OFF \
 -DWASMEDGE_LINK_TOOLS_STATIC=OFF 
RUN cmake --build /build -- install
FROM ubuntu-base AS ubuntu-run
RUN apt update &&  \
      apt install -y --no-install-recommends \
      cuda-cudart-12-6 \
      libcublas-12-6
RUN rm -rf /var/lib/apt/lists/*
COPY --from=ubuntu-cuda /usr/local/bin /wasmedge/bin
COPY --from=ubuntu-cuda /usr/local/lib/libwasmedge.* /wasmedge/lib/libwasmedge.so.0
COPY --from=ubuntu-cuda /usr/lib/x86_64-linux-gnu/libbsd.so.0 /usr/lib/x86_64-linux-gnu/libbsd.so.0
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libLLVM.so.18.1 /lib/x86_64-linux-gnu/libLL.so.18.1
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libffi.so.8 /lib/x86_64-linux-gnu/libffi.so.8
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libedit.so.2 /lib/x86_64-linux-gnu/libedit.so.2
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.6
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libxml2.so.2 /lib/x86_64-linux-gnu/libxml2.so.2
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libbsd.so.0 /lib/x86_64-linux-gnu/libbsd.so.0
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libicuuc.so.74 /lib/x86_64-linux-gnu/libicuuc.so.74
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/liblzma.so.5 /lib/x86_64-linux-gnu/liblzma.so.5
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libmd.so.0 /lib/x86_64-linux-gnu/libmd.so.0
COPY --from=ubuntu-cuda /lib/x86_64-linux-gnu/libicudata.so.74 /lib/x86_64-linux-gnu/libicudata.so.74
COPY --from=ubuntu-cuda /usr/local/lib/wasmedge /wasmedge/plugin
ENTRYPOINT ["/wasmedge/bin/wasmedge" ]
