FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential cmake git pkg-config \
    # Eigen (header-only)
    libeigen3-dev \
    # OpenCV (3.2 on 18.04)
    libopencv-dev \
    # BLAS / LAPACK / SuiteSparse (for Ceres & g2o)
    liblapack-dev libblas-dev libsuitesparse-dev \
    # Logging / flags / testing (for ch13 & Ceres)
    libgoogle-glog-dev libgflags-dev libgtest-dev \
    # Boost (format used in ch8, ch12, ch13)
    libboost-dev libboost-filesystem-dev libboost-program-options-dev \
    # OpenGL / GLEW / X11 (for Pangolin)
    libgl1-mesa-dev libglew-dev freeglut3-dev \
    libxkbcommon-dev libxkbcommon-x11-dev libxrandr-dev libxinerama-dev \
    # Image I/O (for Pangolin / OpenCV)
    libpng-dev libjpeg-dev libtiff-dev \
    # PCL & Octomap (ch12 dense mapping)
    libpcl-dev liboctomap-dev \
    # OpenMP runtime
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /slambook2

# ── Copy sources ─────────────────────────────────────────────────────────────
COPY . .

# Remove any stale CMake caches that may have been copied in
RUN find . -name CMakeCache.txt -delete && \
    find . -name cmake_install.cmake -delete && \
    find . -type d -name CMakeFiles -exec rm -rf {} + 2>/dev/null || true


# 1) Sophus (skip tests – they fail with -Werror on GCC 7)
RUN cd 3rdparty/Sophus && mkdir -p build && cd build && \
    cmake .. -DBUILD_TESTS=OFF && make -j$(nproc) && make install

# 2) g2o
RUN cd 3rdparty/g2o && mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install

# 3) Ceres-solver
RUN cd 3rdparty/ceres-solver && mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DBUILD_TESTING=OFF \
             -DBUILD_EXAMPLES=OFF && \
    make -j$(nproc) && make install

# 4) DBoW3 (build static – ch11 hardcodes libDBoW3.a)
RUN cd 3rdparty/DBoW3 && mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF && \
    make -j$(nproc) && make install

# 5) Pangolin
RUN cd 3rdparty/Pangolin && mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && make install

# Make sure the linker can find newly installed libs
RUN ldconfig

# Build Google Test from source (libgtest-dev on 18.04 only ships source)
RUN cd /usr/src/gtest && cmake . && make -j$(nproc) && \
    cp *.a /usr/lib/

# # ch2  – hello SLAM (no special deps)
# RUN cd ch2 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch3  – Eigen geometry, Pangolin visualisation
# RUN cd ch3 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch4  – Sophus
# RUN cd ch4 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch5  – OpenCV image basics, stereo, RGBD
# RUN cd ch5 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch6  – Curve fitting: Ceres, g2o, Gauss-Newton
# RUN cd ch6 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch7  – Feature matching & pose estimation (g2o, Sophus)
# RUN cd ch7 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch8  – Optical flow & direct methods (Sophus, Pangolin)
# RUN cd ch8 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch9  – Bundle adjustment (g2o, Ceres, Sophus, CSparse)
# RUN cd ch9 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch10 – Pose graph optimisation (g2o, Sophus)
# RUN cd ch10 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch11 – Loop closure (DBoW3, OpenCV)
# RUN cd ch11 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch12 – Dense mapping (PCL, Octomap, OpenCV, Sophus)
# RUN cd ch12 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# # ch13 – Full SLAM system (all deps + glog, gtest, gflags)
# RUN cd ch13 && mkdir -p build && cd build && cmake .. && make -j$(nproc)

WORKDIR /slambook2
CMD ["/bin/bash"]