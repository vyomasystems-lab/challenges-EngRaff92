# See LICENSE.vyoma for details

# SPDX-License-Identifier: CC0-1.0

import os
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly
import random as r

## FSM MODEL
import fsm_model as fsm

### test_seq_reset
@cocotb.test()
async def test_seq_reset(dut):
    """Test for seq detection on RESET only"""
    cocotb.log.info('#### starting test test_seq_reset ######')
    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk

    # FSM model
    m_fsm = fsm.fsm(1,False)

    ## Set input bit to 0
    dut.inp_bit.value = 0

    ## Reset checker
    @cocotb.coroutine
    async def detectReset():
        while True:
            await ReadOnly()
            if(dut.reset.value == 0):
                await RisingEdge(dut.reset)
            await ReadOnly()
            ## After state is stable, before lowering down the reset make sure the state is IDLE
            assert dut.current_state.value == self.m_fsm.get_state()
            if(dut.reset.value == 1):
                await FallingEdge(dut.reset)
            await ReadOnly()

    ## reset coro
    @cocotb.coroutine
    async def reset_coro():
        dut.reset.value = 1
        await FallingEdge(dut.clk)  
        dut.reset.value = 0
        await FallingEdge(dut.clk)

    # Start the clock
    cocotb.start_soon(clock.start())

    ## Start checking
    try:
        cocotb.start_soon(detectReset())
    except AssertionError as txt:
        print("After reset FSM is not in IDLE")

    # Start the reset
    cocotb.start_soon(reset_coro())

### test_seq_invalid
@cocotb.test()
async def test_seq_invalid(dut):
    """Test for seq detection for INVALID transitions"""
    cocotb.log.info('#### starting test test_seq_invalid ######')

    # Create a 10us period clock on port clk
    clock = Clock(dut.clk, 10, units="us") 

    # Internal 
    rtlDetect_cnt = 0

    # model
    m_fsm = fsm.fsm(1,False)

    ## reset coro
    @cocotb.coroutine
    async def reset_coro():
        ## INIT input to 0
        dut.inp_bit.value = 0
        dut.reset.value = 1
        await FallingEdge(dut.clk)  
        dut.reset.value = 0
        await FallingEdge(dut.clk)

    # Start the clock
    cocotb.start_soon(clock.start())        
    # Start the reset
    await reset_coro()

    # Get the valid pattern from the MODEL
    pattern = []
    m_fsm.getInvalid_pkt(pattern)
    cocotb.log.info("Rquired pattern found: {} times".format(m_fsm.getCNT()))
    cocotb.log.info("Pattern fetched is: {}".format(pattern))
    
    ## drive pattern
    for index,S in enumerate(pattern):
        cocotb.log.info("FSM: Current inital state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        cocotb.log.info("FSM: Pattern[{}] value driven is: {}".format(index,S))
        dut.inp_bit.value = S
        c_s = m_fsm.get_state()
        await FallingEdge(dut.clk)
        m_fsm.buttonTrans(pattern[S])
        n_s = m_fsm.get_state()
        cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2}".format(c_s.name,n_s.name,pattern[S]))
        cocotb.log.info("FSM: Current Driven state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        try:
            assert m_fsm.convertState(dut.current_state.value) == n_s
        except AssertionError as ex:
            cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2} not occuring".format(c_s.name,n_s.name,pattern[S]))
        if(m_fsm.convertState(dut.current_state.value) == fsm.states.SEQ_1011):
            assert m_fsm.convertState(dut.current_state.value) != fsm.states.SEQ_1011, "Error while in INVALID test case, sequence should not be detected"
            rtlDetect_cnt = rtlDetect_cnt + 1
        if(index == len(pattern)-1):
            assert rtlDetect_cnt == m_fsm.getCNT(), "Error Sequence not detected the right amount of time, Detected -> {} Expected -> {}".format(rtlDetect_cnt,m_fsm.getCNT())

### test_seq_valid
@cocotb.test()
async def test_seq_valid(dut):
    """Test for seq detection only VALID state transitions"""
    cocotb.log.info('#### starting test test_seq_valid ######')

    # Create a 10us period clock on port clk
    clock = Clock(dut.clk, 10, units="us") 

    # model
    m_fsm = fsm.fsm(1,False)

    ## reset coro
    @cocotb.coroutine
    async def reset_coro():
        ## INIT input to 0
        dut.inp_bit.value = 0
        dut.reset.value = 1
        await FallingEdge(dut.clk)  
        dut.reset.value = 0
        await FallingEdge(dut.clk)

    # Start the clock
    cocotb.start_soon(clock.start())        
    # Start the reset
    await reset_coro()

    # Get the valid pattern from the MODEL
    pattern = m_fsm.getValid_pkt()
    cocotb.log.info("Pattern fetched is: {}".format(pattern))

    ## drive pattern
    for S in pattern.keys():
        cocotb.log.debug("FSM: Current inital state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        cocotb.log.debug("FSM: Pattern value driven is: {}".format(pattern[S]))
        dut.inp_bit.value = pattern[S]
        c_s = m_fsm.get_state()
        await FallingEdge(dut.clk)
        m_fsm.buttonTrans(pattern[S])
        n_s = m_fsm.get_state()
        cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2}".format(c_s.name,n_s.name,pattern[S]))
        cocotb.log.debug("FSM: Current Driven state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        try:
            assert m_fsm.convertState(dut.current_state.value) == n_s
        except AssertionError as ex:
            cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2} not occuring".format(c_s.name,n_s.name,pattern[S]))
        if(S == fsm.states.SEQ_1011):
            assert dut.seq_seen.value == m_fsm.getSeen(), "Error while in SEQ_1011, sequence not detected"

## Test overlapping mechanims
@cocotb.test()
async def test_seq_overlapping(dut):
    """Test for seq detection runs a huge pattern which will contain the sequence to be detected"""
    cocotb.log.info('#### starting test test_seq_overlapping ######')

    # Create a 10us period clock on port clk
    clock = Clock(dut.clk, 10, units="us") 

    # Internal 
    rtlDetect_cnt = 0

    # model
    m_fsm = fsm.fsm(1,True)

    ## reset coro
    @cocotb.coroutine
    async def reset_coro():
        ## INIT input to 0
        dut.inp_bit.value = 0
        dut.reset.value = 1
        await FallingEdge(dut.clk)  
        dut.reset.value = 0
        await FallingEdge(dut.clk)

    # Start the clock
    cocotb.start_soon(clock.start())        
    # Start the reset
    await reset_coro()

    # Get the valid pattern from the MODEL
    pattern = m_fsm.getPattern()
    cocotb.log.info("Rquired pattern found: {} times".format(m_fsm.getCNT()))
    cocotb.log.info("Pattern fetched is: {}".format(pattern))

    ## drive pattern
    for index,S in enumerate(pattern):
        cocotb.log.debug("FSM: Current inital state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        cocotb.log.debug("FSM: Pattern[{}] value driven is: {}".format(index,S))
        dut.inp_bit.value = S
        c_s = m_fsm.get_state()
        await FallingEdge(dut.clk)
        m_fsm.buttonTrans(pattern[S])
        n_s = m_fsm.get_state()
        cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2}".format(c_s.name,n_s.name,pattern[S]))
        cocotb.log.debug("FSM: Current Driven state in RTL: {}".format(m_fsm.convertState(dut.current_state.value)))
        try:
            assert m_fsm.convertState(dut.current_state.value) == n_s
        except AssertionError as ex:
            cocotb.log.debug("FSM: transition from {0} to {1} while input is: {2} not occuring".format(c_s.name,n_s.name,pattern[S]))
        if(m_fsm.convertState(dut.current_state.value) == fsm.states.SEQ_1011):
            assert dut.seq_seen.value, "Error while in SEQ_1011, sequence not detected"
            rtlDetect_cnt = rtlDetect_cnt + 1
        if(index == len(pattern)-1):
            assert rtlDetect_cnt == m_fsm.getCNT(), "Error Sequence not detected the right amount of time, Detected -> {} Expected -> {}".format(rtlDetect_cnt,m_fsm.getCNT())
