#include <iostream>
#include <string>
#include <cstdlib>
#include <utility>

#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "gtest/gtest.h"

#include "vbuddy.cpp"

#define PDF_SIM_CYCLES 2000000

//fast forward thresholds allow us to skip execution on vbuddy to a target
//in order to speed up uneventful part of simulation with cpu initialising/data is being loaded in

// gaussian
#define FAST_FORWARD_THRESHOLD 123500
//noisy #define FAST_FORWARD_THRESHOLD 204700
//triangle #define FAST_FORWARD_THRESHOLD 317000
//sine #define FAST_FORWARD_THRESHOLD 38500

class PdfTestbench : public ::testing::Test {
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

    void setData(const std::string &data_file) {
        std::cout << "loading data file: " << data_file << std::endl;
        std::ignore = system(("cp " + data_file + " data.hex").c_str());
    }

    void initSimulation() {
        top_ = new Vdut(context_);
        tfp_ = new VerilatedVcdC;

        Verilated::traceEverOn(true);
        top_->trace(tfp_, 99);
        
        std::string vcd_path = "test_out/" + name_ + "/waveform.vcd";
        std::ignore = system(("mkdir -p test_out/" + name_).c_str());
        tfp_->open(vcd_path.c_str());

        top_->clk = 1;
        top_->rst = 1;
        top_->trigger = 0;
        
        //run a few reset cycles (using the basic clock loop manually here to avoid triggering plot logic)
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
        bool vbuddy_connected = false;

        for (int i = 0; i < cycles; i++) {
            //standard clocking
            for (int clk = 0; clk < 2; clk++) {
                top_->eval();
                tfp_->dump(2 * ticks_ + clk);
                top_->clk = !top_->clk;
            }
            ticks_++;
            
            //check if we just hit the threshold
            if (ticks_ == FAST_FORWARD_THRESHOLD) {
                std::cout << "fast forward complete. connecting to vbuddy..." << std::endl;
                
                if (vbdOpen() != 1) {
                    std::cout << "error: failed to open vbuddy" << std::endl;
                    exit(1);
                }
                vbdHeader("pdf program");
                vbuddy_connected = true;
            }

            //only plot if we are past the threshold and connected
            if (vbuddy_connected) {
                //plot a0 (0-255)
                vbdPlot(int(top_->a0), 0, 255);
                vbdCycle(i);
                //std::cout << int(top_->a0) << std::endl;
            }

            //check for exit
            if (Verilated::gotFinish()) {
                std::cout << "verilog $finish encountered" << std::endl;
                return;
            }
        }
    }

    void TearDown() override {
        //close vbuddy if it was opened
        vbdClose();

        top_->final();
        tfp_->close();

        std::ignore = system(("mv data.hex test_out/" + name_ + "/data.hex").c_str());
        std::ignore = system(("mv program.hex test_out/" + name_ + "/program.hex").c_str());

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
    
    PdfTestbench tb;
    
    tb.SetUp();
    tb.setupTest("5_pdf");
    tb.setData("reference/gaussian.mem");
    tb.initSimulation();
    
    std::cout << "running simulation..." << std::endl;
    std::cout << "fast forwarding first " << FAST_FORWARD_THRESHOLD << " cycles..." << std::endl;
    
    tb.runSimulation(PDF_SIM_CYCLES);
    
    std::cout << "simulation finished." << std::endl;
    std::cout << "final result in a0: " << tb.getA0() << std::endl;
    
    if (tb.getA0() == 15363) {
        std::cout << "PASSED: output matches expected pdf sum." << std::endl;
    } else {
        std::cout << "FAILED: output does not match." << std::endl;
    }

    tb.TearDown();

    return 0;
}