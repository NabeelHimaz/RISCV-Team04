#!/bin/bash

# This script runs the testbench
# Usage: ./doit.sh <file1.cpp> <file2.cpp>

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
TEST_FOLDER=$(realpath "$SCRIPT_DIR/tests")
RTL_FOLDER=$(realpath "$SCRIPT_DIR/../rtl")
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Variables
passes=0
fails=0

# Handle terminal arguments
if [[ $# -eq 0 ]]; then
    # If no arguments provided, run all tests
    files=(${TEST_FOLDER}/*.cpp)
else
    # If arguments provided, use them as input files
    files=("$@")
fi

# Cleanup
rm -rf obj_dir

cd "$SCRIPT_DIR" || exit

# Iterate through files
for file in "${files[@]}"; do

    name=$(basename "$file" _tb.cpp | cut -f1 -d\-)
    
    # If verify.cpp -> we are testing the top module
    if [ "$name" == "verify.cpp" ]; then
        name="top"
    fi

    # --- UBUNTU CONFIGURATION ---
    # We explicitly set the paths for Ubuntu/WSL
    GTEST_INCLUDE="/usr/include"
    GTEST_LIB="/usr/lib/x86_64-linux-gnu"

    # Check if GoogleTest is actually installed
    if [ ! -d "$GTEST_INCLUDE/gtest" ]; then
        echo "${RED}Error: GoogleTest headers not found.${RESET}"
        echo "Run: sudo apt-get install libgtest-dev cmake build-essential"
        exit 1
    fi
    
    # Translate Verilog -> C++ including testbench
    # Note: -CFLAGS has quotes fixed and the backslash added
    verilator   -Wall --trace \
                -cc "${RTL_FOLDER}/${name}.sv" \
                --exe "$file" \
                -y "$RTL_FOLDER" \
                --prefix "Vdut" \
                -o Vdut \
                -CFLAGS "-std=c++17" \
                -LDFLAGS "-L${GTEST_LIB} -lgtest -lgtest_main -lpthread"

    # Build C++ project with automatically generated Makefile
    make -j -C obj_dir/ -f Vdut.mk
    
    # Run executable simulation file
    ./obj_dir/Vdut
    
    # Check if the test succeeded or not
    if [ $? -eq 0 ]; then
        ((passes++))
    else
        ((fails++))
    fi
    
done

# Exit as a pass or fail (for CI purposes)
if [ $fails -eq 0 ]; then
    echo "${GREEN}Success! All ${passes} tests passed!${RESET}"
    exit 0
else
    total=$((passes + fails))
    echo "${RED}Failure! Only ${passes} tests passed out of ${total}.${RESET}"
    exit 1
fi
