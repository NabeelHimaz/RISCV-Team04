#!/bin/bash

# RISC-V Processor Verification Script
# Automates compilation and testing of all reference programs

# Colors for output
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Get script directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")
TEST_DIR="${SCRIPT_DIR}"
ASM_DIR="${TEST_DIR}/asm"

# Counters
total_tests=0
passed_tests=0
failed_tests=0

# Array to store failed test names
declare -a failed_test_names

echo "${BLUE}========================================${RESET}"
echo "${BLUE}RISC-V Processor Verification${RESET}"
echo "${BLUE}========================================${RESET}"
echo

# Check if required directories exist
if [ ! -d "$ASM_DIR" ]; then
    echo "${RED}Error: asm directory not found at $ASM_DIR${RESET}"
    exit 1
fi

# Get all assembly files in numerical order
asm_files=($(ls ${ASM_DIR}/*.s 2>/dev/null | sort -V))

if [ ${#asm_files[@]} -eq 0 ]; then
    echo "${RED}Error: No .s files found in $ASM_DIR${RESET}"
    exit 1
fi

echo "${BLUE}Found ${#asm_files[@]} test programs${RESET}"
echo

# Function to run a single test
run_test() {
    local asm_file=$1
    local test_name=$(basename "$asm_file" .s)
    
    echo -n "${YELLOW}Testing: ${test_name}...${RESET} "
    
    # Step 1: Compile the assembly file
    ./assemble.sh "$asm_file" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "${RED}COMPILE FAILED${RESET}"
        ((failed_tests++))
        failed_test_names+=("$test_name (compile error)")
        return 1
    fi
    
    # Step 2: Run the testbench
    ./doit.sh > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}PASSED${RESET}"
        ((passed_tests++))
        return 0
    else
        echo "${RED}FAILED${RESET}"
        ((failed_tests++))
        failed_test_names+=("$test_name")
        return 1
    fi
}

# Main test loop
for asm_file in "${asm_files[@]}"; do
    ((total_tests++))
    run_test "$asm_file"
done

# Print summary
echo
echo "${BLUE}========================================${RESET}"
echo "${BLUE}Test Summary${RESET}"
echo "${BLUE}========================================${RESET}"
echo "Total Tests:  $total_tests"
echo "${GREEN}Passed:       $passed_tests${RESET}"
echo "${RED}Failed:       $failed_tests${RESET}"

# Print failed test details
if [ $failed_tests -gt 0 ]; then
    echo
    echo "${RED}Failed Tests:${RESET}"
    for test in "${failed_test_names[@]}"; do
        echo "  - $test"
    done
    echo
    echo "${YELLOW}Tip: Run individual tests with:${RESET}"
    echo "  ./compile.sh asm/<test>.s && ./doit.sh"
    exit 1
else
    echo
    echo "${GREEN}🎉 All tests passed! 🎉${RESET}"
    exit 0
fi