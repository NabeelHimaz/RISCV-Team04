#pragma once

#include <memory>
#include "Vdut.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "gtest/gtest.h"

#define MAX_SIM_CYCLES 10000

class BaseTestbench : public ::testing::Test
{
public:
    void SetUp() override{
        top = std::make_unique<Vdut>();
        simulation_time = 0; // Reset time for every test

        #ifndef __APPLE__
                tfp = std::make_unique<VerilatedVcdC>();
                Verilated::traceEverOn(true);
                top->trace(tfp.get(), 99);
                tfp->open("waveform.vcd");
        #endif
                initializeInputs();
    }

    void TearDown() override{
        top->final();
        #ifndef __APPLE__
                if (tfp) {
                    tfp->close();
                }
        #endif
    }

    // This advances time and dumps the waveform
    void tick()
    {
        // 1. Evaluate the logic (calculate outputs)
        top->eval();

        #ifndef __APPLE__
            // 2. Dump the state to the VCD file at the current time
            if (tfp) {
                tfp->dump(simulation_time);
            }
        #endif
            // 3. Increment time for the next cycle
            simulation_time++;
    }

    virtual void initializeInputs() = 0;

    protected:
        std::unique_ptr<Vdut> top;
        // Keep time strictly local to the class instance
        unsigned long simulation_time = 0; 

    #ifndef __APPLE__
        std::unique_ptr<VerilatedVcdC> tfp;
    #endif
};