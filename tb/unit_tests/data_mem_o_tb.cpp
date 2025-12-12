#include <iostream>
#include <verilated.h>
#include "Vdata_mem_o.h"

// Reference to the Data Width defined in SystemVerilog
#define DATA_WIDTH 32

// Helper function to assert equality and print debug info on failure
void check_result(Vdata_mem_o* dut, const char* test_name, uint32_t expected) {
    if (dut->read_data_o != expected) {
        std::cerr << "[FAIL] " << test_name << std::endl;
        std::cerr << "  Input Data: 0x" << std::hex << dut->read_data_i << std::endl;
        std::cerr << "  Addr:       0x" << std::hex << dut->addr_i << std::endl;
        std::cerr << "  Type:       " << (int)dut->mem_type_i << " (00=W, 01=B, 10=H)" << std::endl;
        std::cerr << "  Sign:       " << (int)dut->mem_sign_i << " (0=Signed, 1=Unsigned)" << std::endl;
        std::cerr << "  Expected:   0x" << std::hex << expected << std::endl;
        std::cerr << "  Got:        0x" << std::hex << dut->read_data_o << std::endl;
        exit(1);
    } else {
        // Uncomment for verbose output
        // std::cout << "[PASS] " << test_name << std::endl;
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vdata_mem_o* dut = new Vdata_mem_o;

    // ---------------------------------------------------------
    // TEST PATTERN: 0xAABBCCDD
    // Byte 0 (LSB) = DD (Negative in signed 8-bit)
    // Byte 1       = CC (Negative in signed 8-bit)
    // Byte 2       = BB (Negative in signed 8-bit)
    // Byte 3 (MSB) = AA (Negative in signed 8-bit)
    // ---------------------------------------------------------
    uint32_t TEST_VAL = 0xAABBCCDD;
    dut->read_data_i = TEST_VAL;

    // =========================================================
    // 1. TEST WORD ACCESS (LW) - Type 00
    // =========================================================
    // Should return raw data regardless of address or sign
    dut->mem_type_i = 0; // Word
    dut->mem_sign_i = 0; // Signed (Ignored for Word, usually)
    dut->addr_i = 0x0;
    dut->eval();
    check_result(dut, "LW (Word Access)", 0xAABBCCDD);

    // =========================================================
    // 2. TEST LOAD BYTE SIGNED (LB) - Type 01, Sign 0
    // =========================================================
    // Logic: Extract byte, Sign Extend to 32 bits
    dut->mem_type_i = 1; // Byte
    dut->mem_sign_i = 0; // Signed

    // Byte 0: 0xDD -> 11011101 (Neg) -> 0xFFFFFFDD
    dut->addr_i = 0x0; dut->eval();
    check_result(dut, "LB Byte 0 (Signed)", 0xFFFFFFDD);

    // Byte 1: 0xCC -> 11001100 (Neg) -> 0xFFFFFFCC
    dut->addr_i = 0x1; dut->eval();
    check_result(dut, "LB Byte 1 (Signed)", 0xFFFFFFCC);

    // Byte 2: 0xBB -> 10111011 (Neg) -> 0xFFFFFFBB
    dut->addr_i = 0x2; dut->eval();
    check_result(dut, "LB Byte 2 (Signed)", 0xFFFFFFBB);

    // Byte 3: 0xAA -> 10101010 (Neg) -> 0xFFFFFFAA
    dut->addr_i = 0x3; dut->eval();
    check_result(dut, "LB Byte 3 (Signed)", 0xFFFFFFAA);

    // =========================================================
    // 3. TEST LOAD BYTE UNSIGNED (LBU) - Type 01, Sign 1
    // =========================================================
    // Logic: Extract byte, Zero Extend to 32 bits
    dut->mem_type_i = 1; // Byte
    dut->mem_sign_i = 1; // Unsigned

    // Byte 0: 0xDD -> 0x000000DD
    dut->addr_i = 0x0; dut->eval();
    check_result(dut, "LBU Byte 0 (Unsigned)", 0x000000DD);

    // Byte 3: 0xAA -> 0x000000AA
    dut->addr_i = 0x3; dut->eval();
    check_result(dut, "LBU Byte 3 (Unsigned)", 0x000000AA);

    // =========================================================
    // 4. TEST LOAD HALFWORD SIGNED (LH) - Type 10, Sign 0
    // =========================================================
    // Logic: Extract halfword, Sign Extend
    dut->mem_type_i = 2; // Halfword
    dut->mem_sign_i = 0; // Signed

    // Half 0: 0xCCDD -> 1100... (Neg) -> 0xFFFFCCDD
    dut->addr_i = 0x0; dut->eval();
    check_result(dut, "LH Half 0 (Signed)", 0xFFFFCCDD);

    // Half 1: 0xAABB -> 1010... (Neg) -> 0xFFFFAABB
    // Note: Address bit [1] selects the halfword (0x2)
    dut->addr_i = 0x2; dut->eval();
    check_result(dut, "LH Half 1 (Signed)", 0xFFFFAABB);

    // =========================================================
    // 5. TEST LOAD HALFWORD UNSIGNED (LHU) - Type 10, Sign 1
    // =========================================================
    // Logic: Extract halfword, Zero Extend
    dut->mem_type_i = 2; // Halfword
    dut->mem_sign_i = 1; // Unsigned

    // Half 0: 0xCCDD -> 0x0000CCDD
    dut->addr_i = 0x0; dut->eval();
    check_result(dut, "LHU Half 0 (Unsigned)", 0x0000CCDD);

    // Half 1: 0xAABB -> 0x0000AABB
    dut->addr_i = 0x2; dut->eval();
    check_result(dut, "LHU Half 1 (Unsigned)", 0x0000AABB);

    // =========================================================
    // 6. POSITIVE NUMBER TEST (Verify we don't always sign extend)
    // =========================================================
    dut->read_data_i = 0x11223344;
    
    // Test LB Signed with Positive Byte (0x44) -> 0x00000044
    dut->mem_type_i = 1; 
    dut->mem_sign_i = 0; 
    dut->addr_i = 0x0; 
    dut->eval();
    check_result(dut, "LB Positive (0x44)", 0x00000044);

    std::cout << "------------------------------------------------" << std::endl;
    std::cout << "SUCCESS: All data_mem_o tests passed." << std::endl;
    std::cout << "------------------------------------------------" << std::endl;

    delete dut;
    return 0;
}