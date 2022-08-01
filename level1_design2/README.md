# LEVEL 1 report: Sequence Detector

## Verification Environment and GITPOD link

The following are all details about the verification approach taken to find bugs into the level 1 design (2). First off, as requested, attached is the gitpod link along with a screeshot of the environment:

- https://vyomasystem-challengese-qee4z1znmm9.ws-eu54.gitpod.io

![alt text](https://github.com/vyomasystems-lab/challenges-EngRaff92/blob/master/level1_design2/Screeshot.png)

## Test Scenario

Let's start off by describing how the design generally behaves, essentially is a **1011** overlapping sequence detector. No doubt that since overlapping the final bit of a sequencer is a starting bit of a new sequence. Every sequences different from the target one are called **Not Valid Sequence** which would lead to a stalling transition or sometimes to a "Back to Idle" transition. The FSM is a 2 processes FSM based on the following approach:

- The Flop will be taking care of STATE TRANSITIONING
- Combo logic is resposible for computing the next allowed space.
- A reset will Always result into an IDLE state
- A clock will be responsible for the sampling

There are in total 4 test scenarios (not running in parallel but just one after another):

1. **test_seq_reset**: Test for seq detection on RESET only
2. **test_seq_invalid**: Test for seq detection for INVALID transitions meaning we never be able to detect the 1011 sequence at all
3. **test_seq_valid**: Test for seq detection only VALID state transitions, we will be able to detect at least once the correct sequence
4. **test_seq_overlapping**: Test for seq detection runs a huge pattern which will contain the sequence to be detected a specific number of times

### test_seq_reset

```py
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

```

### test_seq_invalid

```py
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
```

### test_seq_valid

```py
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
```

### test_seq_overlapping

```py
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
```

A FSM model has been developed which will offer the prediction needed for the test checks. The FSM model provieds the following features:

1. countSequence: count the number of times the 1011 is in the sequence
2. getter methods: used to grab some info like the state or the seen if any occured 
3. getPattern: used to gather the randomized overlapping pattern if FSM is in RAND mode
4. convertState: used to grab the current predicted state
5. buttonTrans: is a press key transition anytime is invoke the internal model does a Transition according to the input provided
6. getValid_pkt: returns a valid PKT (seen here is expected)
7. getInvalid_pkt: returns an invaliud PKT where seen is not expected to occur whatoever 

## Design Bug

FSM was failing in detecting **overlapping** sequence was instead able tio detect non overlapping sequences (the following has been based on fixed RTL only):

|   Current    |     Next     | Input |
| :----------: | :----------: | :---: |
|   **IDLE**   |   **IDLE**   | **0** |
|   **IDLE**   |  **SEQ_1**   | **1** |
|  **SEQ_1**   |  **SEQ_10**  | **0** |
|  **SEQ_1**   |  **SEQ_1**   | **1** |
|  **SEQ_10**  |   **IDLE**   | **0** |
|  **SEQ_10**  | **SEQ_101**  | **1** |
| **SEQ_101**  |  **SEQ_10**  | **0** |
| **SEQ_101**  | **SEQ_1011** | **1** |
| **SEQ_1011** |  **SEQ_10**  | **0** |
| **SEQ_1011** |  **SEQ_1**   | **1** |

## Bug Fix (if any)

As already showed before here is the fixed RTL:

```verilog
// state transition based on the input and current state
  always @(inp_bit or current_state)
  begin
    case(current_state)
      IDLE:
      begin
        if(inp_bit == 1)
          next_state = SEQ_1;
        else
          next_state = IDLE;
      end
      SEQ_1:
      begin
        if(inp_bit == 1)
          next_state = SEQ_1;
        else
          next_state = SEQ_10;
      end
      SEQ_10:
      begin
        if(inp_bit == 1)
          next_state = SEQ_101;
        else
          next_state = IDLE;
      end
      SEQ_101:
      begin
        if(inp_bit == 1)
          next_state = SEQ_1011;
        else
          next_state = SEQ_10;
      end
      SEQ_1011:
      begin
        if(inp_bit)
          next_state = SEQ_1;
        else
          next_state = SEQ_10;
      end
    endcase
  end
```