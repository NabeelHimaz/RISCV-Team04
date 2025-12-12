#include <iostream>
#include <string>
#include <cstdlib>
#include <utility>

#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "gtest/gtest.h"

#include "vbuddy.cpp"

// f1 lights are visual, so we don't need millions of cycles.
// 1000 is plenty to watch the sequence loop a few times.
#define F1_SIM_CYCLES 1000 

class F1Testbench : public ::testing::Test {
public:
    void SetUp() override {
        context_ = new VerilatedContext;
        ticks_ = 0;
    }

    void TestBody() override {}

    void setupTest(const std::string &name) {
        name_ = name;
        std::cout << "assembling program: " << name_ << std::endl;
        std::ignore = system(("./assemble.sh asm/" + name_ + ".s").c_str());
        std::ignore = system("touch data.hex");
    }

    // f1 program generates patterns internally, so we don't need to load a data file.
    // kept empty for compatibility.
    void setData(const std::string &data_file) {
        // no-op
    }

    void initSimulation() {
        top_ = new Vdut(context_);
        tfp_ = new VerilatedVcdC;

        Verilated::traceEverOn(true);
        top_->trace(tfp_, 99);
        
        std::string vcd_path = "test_out/" + name_ + "/waveform.vcd";
        std::ignore = system(("mkdir -p test_out/" + name_).c_str());
        tfp_->open(vcd_path.c_str());

        // open vbuddy immediately for visual feedback
        if (vbdOpen() != 1) {
            std::cout << "error: failed to open vbuddy" << std::endl;
            exit(1);
        }
        
        vbdHeader("F1 Lights");

        top_->clk = 1;
        top_->rst = 1;
        top_->trigger = 0;
        
        for(int i=0; i<10; i++) {
            top_->eval(); 
            top_->clk = !top_->clk; 
            top_->eval(); 
            top_->clk = !top_->clk; 
            ticks_++;
        }
        
        top_->rst = 0;
    }

    void runSimulation(int cycles = 1) {
        for (int i = 0; i < cycles; i++) {
            // cycle the clock
            for (int clk = 0; clk < 2; clk++) {
                top_->eval();
                tfp_->dump(2 * ticks_ + clk);
                top_->clk = !top_->clk;
            }
            ticks_++;
            
            // display the value of a0 on the led bar.
            // masking with 0xFF ensures we only send the bottom 8 bits (since bar is 8-bit).
            vbdBar(top_->a0 & 0xFF);
            vbdCycle(i);

            if (Verilated::gotFinish()) {
                std::cout << "verilog $finish encountered" << std::endl;
                return;
            }
        }
    }

    void TearDown() override {
        vbdClose();

        top_->final();
        tfp_->close();

        // only move program.hex, data.hex might not exist or be empty
        std::ignore = system(("mv program.hex test_out/" + name_ + "/program.hex").c_str());
        // suppress error if data.hex is missing
        std::ignore = system(("mv data.hex test_out/" + name_ + "/data.hex 2>/dev/null").c_str());

        if (top_) delete top_;
        if (tfp_) delete tfp_;
        delete context_;
    }

    int getA0() { return (int)top_->a0; }

protected:
    VerilatedContext* context_;
    Vdut* top_;
    VerilatedVcdC* tfp_;
    std::string name_;
    unsigned int ticks_;
};

int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    
    F1Testbench tb;
    
    tb.SetUp();
    tb.setupTest("6_f1"); 
    
    tb.initSimulation();
    
    std::cout << "running f1 light sequence..." << std::endl;
    tb.runSimulation(F1_SIM_CYCLES);
    
    std::cout << "simulation finished." << std::endl;

    tb.TearDown();

    return 0;
}