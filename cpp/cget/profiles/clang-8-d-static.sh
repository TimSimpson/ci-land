#!/bin/bash
export CI_C=clang-8.0
export CI_CXX=clang++-8.0
export CI_BUILD_TYPE=Debug

# cget init clang-8-d-static --std=c++17 -DCMAKE_C_COMPILER:none=${CI_C} -DCMAKE_CXX_COMPILER:none=${CI_CXX} -DCMAKE_BUILD_TYPE:none=${CI_BUILD_TYPE} -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=NO

cenv init clang-8-d-static --std=c++17 -DCMAKE_C_COMPILER:none=clang-8 -DCMAKE_CXX_COMPILER:none=clang++-8 -DCMAKE_BUILD_TYPE:none=Debug -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=NO
