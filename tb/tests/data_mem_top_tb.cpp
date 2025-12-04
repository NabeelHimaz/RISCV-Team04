#include "base_testbench.h"

class DataMemTopTestbench : public BaseTestbench
{
protected:
    void initializeInputs() override
    {
        top->clk_i = 0;
        top->write_en_i = 0;
        top->addr_i = 0;
        top->write_data_i = 0;
        top->mem_type_i = 0; // Default to Word
        top->mem_sign_i = 0; // Default to Signed
    }

    void stepClock()
    {
        // Rising edge
        top->clk_i = 1;
        tick(); 
        
        // Falling edge (write trigger in underlying mem)
        top->clk_i = 0;
        tick(); 
    }
};

// ==========================================
// 1. WORD ACCESS TESTS (mem_type = 00)
// ==========================================

TEST_F(DataMemTopTestbench, WordReadWrite)
{
    // Write 0xDEADBEEF to address 0x100
    top->write_en_i = 1;
    top->mem_type_i = 0b00; // Word
    top->addr_i = 0x100;
    top->write_data_i = 0xDEADBEEF;
    stepClock();

    // Read back
    top->write_en_i = 0;
    tick(); // Propagate logic

    EXPECT_EQ(top->read_data_o, 0xDEADBEEF);
}

// ==========================================
// 2. BYTE ACCESS TESTS (mem_type = 01)
// ==========================================

// Test storing bytes at different offsets within a word
// Logic Byte 0: [7:0], 1: [15:8], 2: [23:16], 3: [31:24]
TEST_F(DataMemTopTestbench, StoreLoadByte_Offsets)
{
    uint32_t base_addr = 0x200;

    // --- WRITE PHASE ---
    top->write_en_i = 1;
    top->mem_type_i = 0b01; // Byte
    
    // Write 0x11 at Offset 0
    top->addr_i = base_addr + 0;
    top->write_data_i = 0x11; 
    stepClock();

    // Write 0x22 at Offset 1
    top->addr_i = base_addr + 1;
    top->write_data_i = 0x22; 
    stepClock();

    // Write 0x33 at Offset 2
    top->addr_i = base_addr + 2;
    top->write_data_i = 0x33; 
    stepClock();

    // Write 0x44 at Offset 3
    top->addr_i = base_addr + 3;
    top->write_data_i = 0x44; 
    stepClock();

    // --- READ PHASE (Byte Level) ---
    top->write_en_i = 0;
    top->mem_sign_i = 1; // Unsigned read (LBU) to avoid sign extension confusion here

    // Check Offset 0
    top->addr_i = base_addr + 0;
    tick();
    EXPECT_EQ(top->read_data_o, 0x11);

    // Check Offset 1
    top->addr_i = base_addr + 1;
    tick();
    EXPECT_EQ(top->read_data_o, 0x22);

    // Check Offset 2
    top->addr_i = base_addr + 2;
    tick();
    EXPECT_EQ(top->read_data_o, 0x33);

    // Check Offset 3
    top->addr_i = base_addr + 3;
    tick();
    EXPECT_EQ(top->read_data_o, 0x44);

    // --- VERIFY FULL WORD ---
    // Reading as a Word (00) should show the composite value
    // Assuming Little Endian logic in underlying mem structure
    top->mem_type_i = 0b00; 
    top->addr_i = base_addr;
    tick();
    EXPECT_EQ(top->read_data_o, 0x44332211); 
}

// Test Sign Extension for Bytes (LB vs LBU)
TEST_F(DataMemTopTestbench, LoadByte_SignExtension)
{
    // Write 0xFF (negative in 8-bit) to address
    top->write_en_i = 1;
    top->mem_type_i = 0b01; // Byte
    top->addr_i = 0x300;
    top->write_data_i = 0xFF; 
    stepClock();

    top->write_en_i = 0;

    // 1. Test Signed Load (LB) -> mem_sign_i = 0
    // Expect 0xFFFFFFFF (-1)
    top->mem_sign_i = 0; 
    tick();
    EXPECT_EQ(top->read_data_o, 0xFFFFFFFF);

    // 2. Test Unsigned Load (LBU) -> mem_sign_i = 1
    // Expect 0x000000FF (255)
    top->mem_sign_i = 1; 
    tick();
    EXPECT_EQ(top->read_data_o, 0x000000FF);
}

// ==========================================
// 3. HALF-WORD ACCESS TESTS (mem_type = 10)
// ==========================================

TEST_F(DataMemTopTestbench, StoreLoadHalf_Offsets)
{
    uint32_t base_addr = 0x400;

    // --- WRITE PHASE ---
    top->write_en_i = 1;
    top->mem_type_i = 0b10; // Half
    
    // Write 0xAAAA at Offset 0 (covers bytes 0 and 1)
    top->addr_i = base_addr;
    top->write_data_i = 0xAAAA;
    stepClock();

    // Write 0xBBBB at Offset 2 (covers bytes 2 and 3)
    top->addr_i = base_addr + 2;
    top->write_data_i = 0xBBBB;
    stepClock();

    // --- READ PHASE (Half Level) ---
    top->write_en_i = 0;
    top->mem_sign_i = 1; // Unsigned (LHU)

    // Check Offset 0
    top->addr_i = base_addr;
    tick();
    EXPECT_EQ(top->read_data_o, 0xAAAA);

    // Check Offset 2
    top->addr_i = base_addr + 2;
    tick();
    EXPECT_EQ(top->read_data_o, 0xBBBB);

    // --- VERIFY FULL WORD ---
    top->mem_type_i = 0b00;
    top->addr_i = base_addr;
    tick();
    EXPECT_EQ(top->read_data_o, 0xBBBBAAAA); 
}

TEST_F(DataMemTopTestbench, LoadHalf_SignExtension)
{
    // Write 0xF00D (negative in 16-bit)
    top->write_en_i = 1;
    top->mem_type_i = 0b10; // Half
    top->addr_i = 0x500;
    top->write_data_i = 0xF00D;
    stepClock();

    top->write_en_i = 0;

    // 1. Test Signed Load (LH) -> mem_sign_i = 0
    // Expect 0xFFFFF00D
    top->mem_sign_i = 0;
    tick();
    EXPECT_EQ(top->read_data_o, 0xFFFFF00D);

    // 2. Test Unsigned Load (LHU) -> mem_sign_i = 1
    // Expect 0x0000F00D
    top->mem_sign_i = 1;
    tick();
    EXPECT_EQ(top->read_data_o, 0x0000F00D);
}

// ==========================================
// 4. READ-MODIFY-WRITE INTEGRITY
// ==========================================

// Ensure that writing a single byte does not corrupt the other bytes in the word
TEST_F(DataMemTopTestbench, ReadModifyWrite_Integrity)
{
    uint32_t addr = 0x600;

    // 1. Initialize Word with 0xFFFFFFFF
    top->write_en_i = 1;
    top->mem_type_i = 0b00; // Word
    top->addr_i = addr;
    top->write_data_i = 0xFFFFFFFF;
    stepClock();

    // 2. Overwrite only Byte 1 (offset 1) with 0x00
    top->mem_type_i = 0b01; // Byte
    top->addr_i = addr + 1;
    top->write_data_i = 0x00;
    stepClock();

    // 3. Read back full Word
    top->write_en_i = 0;
    top->mem_type_i = 0b00; // Word
    top->addr_i = addr;
    tick();

    // Expected: 0xFF00FFFF (Byte 1 is 00, others FF)
    EXPECT_EQ(top->read_data_o, 0xFF00FFFF);
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}