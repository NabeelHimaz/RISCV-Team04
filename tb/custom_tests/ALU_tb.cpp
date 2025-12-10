#include "base_testbench.h"

class ALUTestbench : public BaseTestbench
{
protected:
    void initializeInputs() override
    {
        top->ALUCtrl_i = 0;
        top->srcA_i = 0;
        top->srcB_i = 0;
        // output: ALUResult_o
    }
};

//waiting on changes from NH & AT to test
TEST_F(ALUTestbench, ZeroFlagSet)
{
    top->ALUCtrl_i = 0b0001;
    top->srcA_i = 0b0011;
    top->srcB_i = 0b0011;

    tick();

    //EXPECT_EQ(top->ALU zero flag out, 0b1);
}

TEST_F(ALUTestbench, ALU0WorksTest)
{
    top->ALUCtrl_i = 0b0000;
    top->srcA_i = 0b0011;
    top->srcB_i = 0b1100;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0b1111);
}

TEST_F(ALUTestbench, ALU1WorksTest)
{
    top->ALUCtrl_i = 0b0010;
    top->srcA_i = 0b0110;
    top->srcB_i = 0b1100;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0b0100);
}

//--- addition tests (0000) ---

//basic addition test to verify 3 + 12 = 15
TEST_F(ALUTestbench, ADD_Basic)
{
    top->ALUCtrl_i = 0b0000;
    top->srcA_i = 0b0011; //3
    top->srcB_i = 0b1100; //12

    tick();

    EXPECT_EQ(top->ALUResult_o, 15);
}

//edge case: addition overflow
//adding 1 to the max 32-bit integer (0xffffffff) should wrap around to 0
TEST_F(ALUTestbench, ADD_Overflow)
{
    top->ALUCtrl_i = 0b0000;
    top->srcA_i = 0xFFFFFFFF; 
    top->srcB_i = 0x00000001; 

    tick();

    EXPECT_EQ(top->ALUResult_o, 0x00000000);
}

//--- subtraction tests (0001) ---

//basic subtraction test: 12 - 3 = 9
TEST_F(ALUTestbench, SUB_Basic)
{
    top->ALUCtrl_i = 0b0001;
    top->srcA_i = 12;
    top->srcB_i = 3;

    tick();

    EXPECT_EQ(top->ALUResult_o, 9);
}

//edge case: negative result (underflow)
//0 - 1 should result in 0xffffffff (-1 in 2's complement representation)
TEST_F(ALUTestbench, SUB_NegativeResult)
{
    top->ALUCtrl_i = 0b0001;
    top->srcA_i = 0;
    top->srcB_i = 1;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0xFFFFFFFF);
}

//--- logical tests (and: 0010, or: 0011, xor: 0100) ---

//and test: 0x00ff & 0x0f0f should be 0x000f
TEST_F(ALUTestbench, AND_Basic)
{
    top->ALUCtrl_i = 0b0010;
    top->srcA_i = 0x000000FF; 
    top->srcB_i = 0x00000F0F; 

    tick();

    EXPECT_EQ(top->ALUResult_o, 0x0000000F);
}

//or test: 0x00f0 | 0x0f00 should be 0x0ff0
TEST_F(ALUTestbench, OR_Basic)
{
    top->ALUCtrl_i = 0b0011;
    top->srcA_i = 0x000000F0;
    top->srcB_i = 0x00000F00;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0x00000FF0);
}

//xor test: xoring a value with itself should always result in 0
TEST_F(ALUTestbench, XOR_Identity)
{
    top->ALUCtrl_i = 0b0100;
    top->srcA_i = 0x12345678;
    top->srcB_i = 0x12345678;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0);
}

//--- comparison tests (slt: 0101, sltu: 0110) ---

//slt (signed less than): -1 (0xff...) is less than 1. result should be 1 (true)
//this tests if the alu correctly interprets 0xffffffff as a negative number
TEST_F(ALUTestbench, SLT_SignedCheck)
{
    top->ALUCtrl_i = 0b0101;
    top->srcA_i = 0xFFFFFFFF; //-1 in signed
    top->srcB_i = 0x00000001; // 1 in signed

    tick();

    EXPECT_EQ(top->ALUResult_o, 1);
}

//slt edge case: 10 is not less than 5. result should be 0 (false)
TEST_F(ALUTestbench, SLT_FalseCheck)
{
    top->ALUCtrl_i = 0b0101;
    top->srcA_i = 10;
    top->srcB_i = 5;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0);
}

//sltu (unsigned less than): 0xff... (max unsigned) is not less than 1. result 0
//this is the inverse of the slt_signedcheck test. 0xff... is huge in unsigned
TEST_F(ALUTestbench, SLTU_UnsignedCheck)
{
    top->ALUCtrl_i = 0b0110;
    top->srcA_i = 0xFFFFFFFF; //max int in unsigned
    top->srcB_i = 0x00000001; //1

    tick();

    EXPECT_EQ(top->ALUResult_o, 0);
}

//--- shift tests (srl: 0111, sll: 1000, sra: 1001) ---

//sll (shift left logical): shift 1 left by 4 bits. result should be 16
TEST_F(ALUTestbench, SLL_Basic)
{
    top->ALUCtrl_i = 0b1000;
    top->srcA_i = 0x00000001;
    top->srcB_i = 4;

    tick();

    EXPECT_EQ(top->ALUResult_o, 16);
}

//srl (shift right logical): shift 0xf00...00 right by 4
//zeros should fill the new bits. result: 0x0f0...00
TEST_F(ALUTestbench, SRL_ZeroFill)
{
    top->ALUCtrl_i = 0b0111;
    top->srcA_i = 0xF0000000; //negative number if signed
    top->srcB_i = 4;

    tick();

    //expecting 0 filler bits at the top (logical shift)
    EXPECT_EQ(top->ALUResult_o, 0x0F000000);
}

//sra (shift right arithmetic): shift 0xf00...00 right by 4
//the sign bit (1) should fill the new bits. result: 0xff0...00
TEST_F(ALUTestbench, SRA_SignExtension)
{
    top->ALUCtrl_i = 0b1001;
    top->srcA_i = 0xF0000000; //negative number (sign bit 1)
    top->srcB_i = 4;

    tick();

    //expecting 1 filler bits at the top (arithmetic shift)
    EXPECT_EQ(top->ALUResult_o, 0xFF000000);
}

//--- default case ---

//test undefined control code. should result in 0 based on default case
TEST_F(ALUTestbench, Default_Case)
{
    top->ALUCtrl_i = 0b1111; //undefined instruction
    top->srcA_i = 0xFFFFFFFF;
    top->srcB_i = 0xFFFFFFFF;

    tick();

    EXPECT_EQ(top->ALUResult_o, 0);
}

int main(int argc, char **argv)
{

    Verilated::commandArgs(argc, argv);
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
    /*
    top = new Vdut;
    tfp = new VerilatedVcdC;

    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    testing::InitGoogleTest(&argc, argv);
    auto res = RUN_ALL_TESTS();

    top->final();
    tfp->close();

    delete top;
    delete tfp;

    return res;
    */
}
