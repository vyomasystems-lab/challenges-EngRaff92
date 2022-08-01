# LEVEL 1 report: MUX

## Verification Environment and GITPOD link

The following are all details about the verification approach taken to find bugs into the level 1 design. First off, as requested, attached is the gitpod link along with a screeshot of the environment:

- https://vyomasystem-challengese-qee4z1znmm9.ws-eu54.gitpod.io

![alt text](https://github.com/vyomasystems-lab/challenges-EngRaff92/blob/master/level1_design1/Screeshot.png)

## Test Scenario

Let's start off by describing how the design generally behaves, essentially is a 32 to 1 MUX. No doubt that if one of the 5 bits selector is high the one and only 1 of the input will be directly forwarded to the output. Is a fully combo design with no clock and no register holding the result once selected. Here is a list of key points:

1. bit selector.
2. 31 input rooted to the unique output.
3. if selector reaches the MAX output will be 0 on the 32nd iteration.

There is only 1 test scenario, **no multiple cocotb.test() async tasks**, where basically we loop through all possible input and check all possible values matches the result. The currect test scenario will cover the following:

1. Set input to 0 (this will be useful to check if any of the input is eventually not properly driving the output which would be X or not resolvable as consequence)
2. Set input to 1 and check by stepping through the selector that the output value is 0
3. Set input to a random value from 0 to 1, select a random port and finally select a random selector value. This will be repeated at least 2 times the number of possible combination.

### Start with all zero

```py
## as inital value let's zeroing out all the input
    for inp in range(MAX_LEN):
        if(inp != MAX_LEN):
            reduce(getattr, "inp{}".format(inp).split("."), dut).value = 0
    
    ## Wait few ns
    await Timer(SEP_TIME)

```

### Test all 1 on the input

```py
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
```

### Test Random

```py
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
```

Test Are generallyi parametrized according to the Number of inputs and number of ns we would be waiting before applying stimulus.

## Design Bug

Few Design bugs have been found:

```verilog
      case(sel)
      5'b00000: out = inp0;  
      5'b00001: out = inp1;  
      5'b00010: out = inp2;  
      5'b00011: out = inp3;  
      5'b00100: out = inp4;  
      5'b00101: out = inp5;  
      5'b00110: out = inp6;  
      5'b00111: out = inp7;  
      5'b01000: out = inp8;  
      5'b01001: out = inp9;  
      5'b01010: out = inp10;
      5'b01011: out = inp11;
      /** Fixed from 5'b01101: out = inp12; */
      5'b01100: out = inp12;
      5'b01101: out = inp13;
      5'b01110: out = inp14;
      5'b01111: out = inp15;
      5'b10000: out = inp16;
      5'b10001: out = inp17;
      5'b10010: out = inp18;
      5'b10011: out = inp19;
      5'b10100: out = inp20;
      5'b10101: out = inp21;
      5'b10110: out = inp22;
      5'b10111: out = inp23;
      5'b11000: out = inp24;
      5'b11001: out = inp25;
      5'b11010: out = inp26;
      5'b11011: out = inp27;
      5'b11100: out = inp28;
      5'b11101: out = inp29;
      /** Added */
      5'b11110: out = inp30;
      /** In case of SEL is 31 */
      default: out = 0;
```

1. The **INP30** once selected would falling into the default state
2. The **INP12** wa not correcly selected, the selector rooting the **inp12** was **5'b01101** and not **5'b01100**

## Bug Fix (if any)

As already showed before here is the fixed RTL:

```verilog
   case(sel)
      5'b00000: out = inp0;  
      5'b00001: out = inp1;  
      5'b00010: out = inp2;  
      5'b00011: out = inp3;  
      5'b00100: out = inp4;  
      5'b00101: out = inp5;  
      5'b00110: out = inp6;  
      5'b00111: out = inp7;  
      5'b01000: out = inp8;  
      5'b01001: out = inp9;  
      5'b01010: out = inp10;
      5'b01011: out = inp11;
      /** Fixed from 5'b01101: out = inp12; */
      5'b01100: out = inp12;
      5'b01101: out = inp13;
      5'b01110: out = inp14;
      5'b01111: out = inp15;
      5'b10000: out = inp16;
      5'b10001: out = inp17;
      5'b10010: out = inp18;
      5'b10011: out = inp19;
      5'b10100: out = inp20;
      5'b10101: out = inp21;
      5'b10110: out = inp22;
      5'b10111: out = inp23;
      5'b11000: out = inp24;
      5'b11001: out = inp25;
      5'b11010: out = inp26;
      5'b11011: out = inp27;
      5'b11100: out = inp28;
      5'b11101: out = inp29;
      /** Added */
      5'b11110: out = inp30;
      /** In case of SEL is 31 */
      default: out = 0;
```