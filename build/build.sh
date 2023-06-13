#!/bin/bash
export CXXFLAGS=" -pthread"
export BUILD_DIR=_build

mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

cmake ..
make -j $(nproc)

# EOF
