/*
 *  Verifies the results of the alu, exits with a 0 on success.
 */

#include "base_testbench.h"

Vdut *top;
VerilatedVcdC *tfp;
unsigned int ticks = 0;

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

TEST_F(ALUTestbench, ALU0WorksTest)
{
    top->ALUCtrl_i = 0b0000;
    top->srcA_i = 0b0011;
    top->srcB_i = 0b1100;

    top->eval();

    EXPECT_EQ(top->ALUResult_o, 0b1111);
}

TEST_F(ALUTestbench, ALU1WorksTest)
{
    top->ALUCtrl_i = 0b0010;
    top->srcA_i = 0b0110;
    top->srcB_i = 0b1100;

    top->eval();

    EXPECT_EQ(top->ALUResult_o, 0b0100);
}

int main(int argc, char **argv)
{
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
}
