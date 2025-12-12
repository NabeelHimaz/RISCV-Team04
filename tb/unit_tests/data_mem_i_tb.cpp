#include "base_testbench.h"

class DataMemITestbench : public BaseTestbench
{
protected:
    void initializeInputs() override
    {
        top->read_data_i = 0;
        top->write_data_i = 0;
        top->addr_i = 0;
        top->mem_type_i = 0;
    }
};

// Test that writing a full word (32-bit) replaces the data entirely
TEST_F(DataMemITestbench, WordWrite_PassThrough)
{
    top->mem_type_i = 0b00; // Word
    top->read_data_i = 0xFFFFFFFF; // Existing garbage
    top->write_data_i = 0xDEADBEEF; // New data
    top->addr_i = 0x0; 

    tick(); // Eval and dump

    EXPECT_EQ(top->write_data_o, 0xDEADBEEF);
}

// Test writing a single byte [7:0] into different positions
TEST_F(DataMemITestbench, ByteWrite_Offsets)
{
    top->mem_type_i = 0b01; // Byte
    uint32_t existing = 0x88776655; 
    uint32_t new_byte = 0xAA; // We want to insert AA

    // Case 0: Offset 0 (Bottom byte) -> Expect 0x887766AA
    top->addr_i = 0x0;
    top->read_data_i = existing;
    top->write_data_i = new_byte;
    tick();
    EXPECT_EQ(top->write_data_o, 0x887766AA);

    // Case 1: Offset 1 (Second byte) -> Expect 0x8877AA55
    top->addr_i = 0x1;
    top->read_data_i = existing;
    top->write_data_i = new_byte;
    tick();
    EXPECT_EQ(top->write_data_o, 0x8877AA55);

    // Case 2: Offset 2 (Third byte) -> Expect 0x88AA6655
    top->addr_i = 0x2;
    top->read_data_i = existing;
    top->write_data_i = new_byte;
    tick();
    EXPECT_EQ(top->write_data_o, 0x88AA6655);

    // Case 3: Offset 3 (Top byte) -> Expect 0xAA776655
    top->addr_i = 0x3;
    top->read_data_i = existing;
    top->write_data_i = new_byte;
    tick();
    EXPECT_EQ(top->write_data_o, 0xAA776655);
}

// Test writing a half-word [15:0] into bottom or top positions
TEST_F(DataMemITestbench, HalfWrite_Offsets)
{
    top->mem_type_i = 0b10; // Half
    uint32_t existing = 0x88776655;
    uint32_t new_half = 0xAABB; 

    // Case 0: Offset 0 (Bottom half) -> Expect 0x8877AABB
    top->addr_i = 0x0;
    top->read_data_i = existing;
    top->write_data_i = new_half;
    tick();
    EXPECT_EQ(top->write_data_o, 0x8877AABB);

    // Case 2: Offset 2 (Top half) -> Expect 0xAABB6655
    top->addr_i = 0x2;
    top->read_data_i = existing;
    top->write_data_i = new_half;
    tick();
    EXPECT_EQ(top->write_data_o, 0xAABB6655);
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}