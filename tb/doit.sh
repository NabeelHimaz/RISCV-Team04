#!/bin/bash

# This script runs the testbench
# Usage: ./doit.sh <file1.cpp> <file2.cpp>

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# Added specific folders for unit vs program tests
TEST_FOLDER=$(realpath "$SCRIPT_DIR/tests")
UNIT_TEST_FOLDER=$(realpath "$SCRIPT_DIR/unit_tests")
PROG_TEST_FOLDER=$(realpath "$SCRIPT_DIR/program_tests")
VBUDDY_TEST_FOLDER=$(realpath "$SCRIPT_DIR/vbuddy_tests")
RTL_FOLDER=$(realpath "$SCRIPT_DIR/../rtl")
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Variables
passes=0
fails=0

chmod +x attach_usb.sh
./attach_usb.sh

# Handle terminal arguments
if [[ $# -eq 0 ]]; then
    echo "Which tests would you like to run?"
    echo "1) Unit Tests"
    echo "2) Program Tests"
    echo "3) VBuddy Tests"
    read -p "Select option (1-3): " option

    case $option in
        1) files=(${UNIT_TEST_FOLDER}/*.cpp) ;;
        2) files=(${PROG_TEST_FOLDER}/*.cpp) ;;
        3) files=(${VBUDDY_TEST_FOLDER}/*.cpp) ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
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

    # skip vbuddy.cpp
    if [ "$name" == "vbuddy.cpp" ]; then
        continue
    fi
    
    # we are testing the top module if working with any of these files
    if [[ "$name" == "verify.cpp" || "$name" == "execute_pdf.cpp" || "$name" == "execute_f1.cpp" ]]; then
        name="top"
    fi

    # --- UBUNTU CONFIGURATION ---
    # We explicitly set the paths for Ubuntu/WSL
    GTEST_INCLUDE="/usr/include"
    GTEST_LIB="/usr/lib/x86_64-linux-gnu"

    
    # Translate Verilog -> C++ including testbench
    # Note: -CFLAGS has quotes fixed and the backslash added
    verilator   -Wall --trace \
                -cc "${RTL_FOLDER}/${name}.sv" \
                --exe "$file" \
                -y "$RTL_FOLDER" \
                --prefix "Vdut" \
                -o Vdut \
                -Wno-UNUSED \
                -CFLAGS "-std=c++17" \
                -LDFLAGS "-L${GTEST_LIB} -lgtest -lgtest_main -lpthread"
                > /dev/null

    # Build C++ project with automatically generated Makefile
    make -j -C obj_dir/ -f Vdut.mk > /dev/null
    
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
    echo "${RED}Failure! Only ${passes} tests passed out of ${total}. Check vbuddy is connected if running vbuddy tests.${RESET}"
    exit 1
fi