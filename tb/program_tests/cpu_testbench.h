#pragma once

#include <utility>

#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "gtest/gtest.h"

#define MAX_SIM_CYCLES 1000000

class CpuTestbench : public ::testing::Test
{
public:
    void SetUp() override
    {
        // Create new context for simulation
        context_ = new VerilatedContext;
        ticks_ = 0;
        last_trigger_ = 0;
    }

    void setupTest(const std::string &name)
    {
        name_ = name;
        // Assemble the program
        std::ignore = system(("./assemble.sh asm/" + name_ + ".s").c_str());
        // Create default empty file for data memory
        std::ignore = system("touch data.hex");
    }

    // CPU instantiated outside of SetUp to allow for correct
    // program to be assembled and loaded into instruction memory
    void initSimulation()
    {
        top_ = new Vdut(context_);
        tfp_ = new VerilatedVcdC;

        // Initialise trace and simulation
        Verilated::traceEverOn(true);
        top_->trace(tfp_, 99);
        tfp_->open(("test_out/" + name_ + "/waveform.vcd").c_str());

        // Initialise inputs
        top_->clk = 1;
        top_->rst = 1;
        top_->trigger = 0;
        runSimulation(10);  // Process reset
        top_->rst = 0;
    }

    // Runs the simulation for a clock cycle, evaluates the DUT, dumps waveform.
    void runSimulation(int cycles = 1)
    {
        for (int i = 0; i < cycles; i++)
        {
            for (int clk = 0; clk < 2; clk++)
            {
                top_->eval();
                tfp_->dump(2 * ticks_ + clk);
                top_->clk = !top_->clk;
            }
            ticks_++;

             if (top_->trigger && !last_trigger_) {
        std::cout << name_ << " completed in " << ticks_ 
                  << " cycles" << std::endl;
        return;  // Stop immediately
    }
        last_trigger_ = top_->trigger;
        }
    }

    void TearDown() override
    {
        // End trace and simulation
        top_->final();
        tfp_->close();

        // Free memory
        if (top_) delete top_;
        if (tfp_) delete tfp_;
        delete context_;

        // Save data and program memory files to test_out directory
        std::ignore = system(("mv data.hex test_out/" + name_ + "/data.hex").c_str());
        std::ignore = system(("mv program.hex test_out/" + name_ + "/program.hex").c_str());
    }

    void setData(const std::string &data_file)
    {
        // Fill data.hex with program data
        std::ignore = system(("cp " + data_file + " data.hex").c_str());
    }

protected:
    VerilatedContext* context_;
    Vdut* top_;
    VerilatedVcdC* tfp_;
    std::string name_;
    unsigned int ticks_;
    uint8_t last_trigger_;
};