#include "base_testbench.h"

class DataMemTestbench : public BaseTestbench
{
protected:
    void initializeInputs() override
    {
        top->clk_i = 0;
        top->write_en_i = 0;
        top->addr_i = 0;
        top->write_data_i = 0;
    }
    void stepClock()
    {
        // Rising edge (setup)
        top->clk_i = 1;
        tick(); 
        
        // Falling edge (write trigger)
        top->clk_i = 0;
        tick(); 
    }
};

TEST_F(DataMemTestbench, BasicWriteRead)
{
    top->write_en_i = 1;
    top->addr_i = 0x00000100;      // Arbitrary address
    top->write_data_i = 0xDEADBEEF; // Test pattern

    // 2. Clock it to commit write (negedge)
    stepClock();

    // 3. Disable Write
    top->write_en_i = 0;
    
    // 4. Verify Read (Combinational)
    // Even though read is combinational, we step simply to move time forward
    tick(); 
    
    EXPECT_EQ(top->read_data_o, 0xDEADBEEF);
}

TEST_F(DataMemTestbench, OverwriteTest)
{
    uint32_t addr = 0x00000200;

    // Write Initial Value
    top->write_en_i = 1;
    top->addr_i = addr;
    top->write_data_i = 0xAAAAAAAA;
    stepClock();

    // Check Initial
    EXPECT_EQ(top->read_data_o, 0xAAAAAAAA);

    // Write New Value
    top->write_data_i = 0x55555555;
    stepClock();

    // Disable write
    top->write_en_i = 0;
    tick();

    // Check New Value
    EXPECT_EQ(top->read_data_o, 0x55555555);
}


TEST_F(DataMemTestbench, WriteEnableLowTest)
{
    // Ensure that data is NOT written when write_en_i is 0
    uint32_t addr = 0x00000300;

    // 1. Write a known value first
    top->write_en_i = 1;
    top->addr_i = addr;
    top->write_data_i = 0x11111111;
    stepClock();

    // 2. Try to write new value with write_en = 0
    top->write_en_i = 0;
    top->write_data_i = 0xFFFFFFFF; // Should be ignored
    stepClock();

    // 3. Verify original value remains
    EXPECT_EQ(top->read_data_o, 0x11111111);
}

// --- Sequential Logic Tests ---

// This test writes a sequence of data to consecutive addresses
// and then reads them back sequentially using clock ticks.


// --- Edge Case Tests ---

// The RTL uses [16:0] slicing for the address. 
// Addresses 0x00000 and 0x20000 (bit 17 high) should map to the same physical RAM index.
TEST_F(DataMemTestbench, AddressAliasingTest)
{
    // Write to standard address
    top->write_en_i = 1;
    top->addr_i = 0x00001000; 
    top->write_data_i = 0xCAFEBABE;
    stepClock();

    top->write_en_i = 0;

    // Read from Aliased address (0x1000 + 0x20000)
    // 0x21000 should map to 0x1000 internally due to [16:0] slice
    top->addr_i = 0x00021000; 
    tick();

    EXPECT_EQ(top->read_data_o, 0xCAFEBABE);
}

// Verify Little Endian byte packing
// RTL: {ram[+3], ram[+2], ram[+1], ram[0]}
TEST_F(DataMemTestbench, BytePackingTest)
{
    // Write a full word
    top->write_en_i = 1;
    top->addr_i = 0x00000000;
    top->write_data_i = 0x12345678; // MSB: 12, LSB: 78
    stepClock();

    top->write_en_i = 0;

    // If we read the word back, we get the full value
    top->addr_i = 0x00000000;
    tick();
    EXPECT_EQ(top->read_data_o, 0x12345678);

    // Note: To strictly test individual bytes, you would need to read 
    // at addr+1, addr+2, etc., but since the RTL reads 4 bytes starting 
    // from addr_i, reading at addr+1 results in unaligned data from 
    // the perspective of the original word write.
    
    // Example: Reading at address 1 should give {ram[4], ram[3], ram[2], ram[1]}
    // ram[0]=78, ram[1]=56, ram[2]=34, ram[3]=12, ram[4]=? (0 or uninit)
    // Expect: 0x??123456
    
    top->addr_i = 0x00000001;
    tick();
    // Mask out the top byte because ram[4] wasn't written
    EXPECT_EQ(top->read_data_o & 0x00FFFFFF, 0x00123456);
}

TEST_F(DataMemTestbench, SequentialReadTest)
{
    const int NUM_ITEMS = 5;
    uint32_t start_addr = 0x400;
    uint32_t data_values[NUM_ITEMS] = {10, 20, 30, 40, 50};

    // 1. Fill Memory sequentially
    top->write_en_i = 1;
    
    for(int i = 0; i < NUM_ITEMS; i++) {
        top->addr_i = start_addr + (i * 4); // Increment by 4 bytes (32-bit word)
        top->write_data_i = data_values[i];
        stepClock();
    }

    // 2. Read Memory sequentially
    top->write_en_i = 0; // Turn off write

    for(int i = 0; i < NUM_ITEMS; i++) {
        top->addr_i = start_addr + (i * 4);
        
        // Tick simply to advance simulation time (read is combinational)
        // But this mimics a CPU cycle fetching data
        tick();

        EXPECT_EQ(top->read_data_o, data_values[i]) 
            << "Mismatch at index " << i << " address " << top->addr_i;
    }
}


int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
