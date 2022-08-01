# See LICENSE.vyoma for details

import cocotb
from cocotb.triggers import Timer
from functools import reduce
from random import randrange
from math import log

MAX_LEN = 31
STD_TIME= 1
SEP_TIME= 10

@cocotb.test()
async def test_mux(dut):
    """
    Test for mux2: 
    -> 5 bit selector
    -> 31 input rooted to the unique output
    -> if selector reaches the MAX output will be 0 on the 32nd iteration
    """
    cocotb.log.info('#### START TEST #####')

    ## as inital value let's zeroing out all the input
    for inp in range(MAX_LEN):
        if(inp != MAX_LEN):
            reduce(getattr, "inp{}".format(inp).split("."), dut).value = 0
    
    ## Wait few ns
    await Timer(SEP_TIME)

    ## Define signal name as string and set all values
    for inp in range(MAX_LEN):
        ## Set all input to 1
        if(inp != MAX_LEN):
            reduce(getattr, "inp{}".format(inp).split("."), dut).value = 1
        ## Set the selector
        dut.sel.value = inp
        await Timer(STD_TIME)
        if(inp != MAX_LEN):
            assert dut.out.value == 1, "For input {0:b} value selected is not 1 as expected".format(inp)
        else:
            assert dut.out.value == 0, "For input {0:b} value selected is not 0 as expected".format(inp)
        assert dut.out.value.is_resolvable, "For input {0:b} value is UNKNOWN".format(inp)

    ## as separator value let's zeroing out all the input
    for inp in range(MAX_LEN):
        if(inp != MAX_LEN):
            reduce(getattr, "inp{}".format(inp).split("."), dut).value = 0
    
    ## Wait few ns
    await Timer(SEP_TIME)

    ## Define signal name as string and play with random values
    for i in range(2*MAX_LEN):
        ## Set al input to random
        result = randrange(0,1)
        ##result = 1
        select = randrange(0,int(log(MAX_LEN, 2)))
        port_s = randrange(0,MAX_LEN)
        if(port_s != MAX_LEN):
            reduce(getattr, "inp{}".format(port_s).split("."), dut).value = result
        ## Set the selector
        dut.sel.value = select
        await Timer(STD_TIME)
        ## DEBUG prints
        if(port_s != MAX_LEN):
            cocotb.log.debug("TESTING --- For input port: {0:d} selector is: {0:b} value sampled is: {0:b} value expected is: {0:b}".format(port_s,select,dut.out.value,result))
        else:
            cocotb.log.debug("TESTING --- Last Element selector is: {0:b} value sampled is: {0:b} value expected is: {0:b}".format(port_s,select,dut.out.value,0))
        ## TEST
        if(port_s != MAX_LEN):
            assert dut.out.value == result, "For input port: {0:d} selector is: {0:b} value sampled is: {0:b} value expected is: {0:b}".format(port_s,select,dut.out.value,result)
        else:
            assert dut.out.value == 0, "Last Element selector is: {0:b} value sampled is: {0:b} value expected is: {0:b}".format(port_s,select,dut.out.value,0)            
        assert dut.out.value.is_resolvable, "For input {0:b} value is UNKNOWN".format(port_s)