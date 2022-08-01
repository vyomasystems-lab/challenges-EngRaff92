# LEVEL 2 report: Bit Manipulator

## Verification Environment and GITPOD link

The following are all details about the verification approach taken to find bugs into the level 2 design. First off, as requested, attached is the gitpod link along with a screeshot of the environment:

- https://vyomasystem-challengese-qee4z1znmm9.ws-eu54.gitpod.io

![alt text](https://github.com/vyomasystems-lab/challenges-EngRaff92/blob/master/level2_design/Screeshot.png)

## Test Scenario

Let's start off by describing how the design generally behaves, essentially is a kind of extensive **ALU** supporting several operation from R type, which would require operands to be filled, up to IMM instruction, whcih instead would require immediate value to be fed. No doubt that one of the main approach would be a looping one. Once we have the instruction we just loop trhough all possible values the instruction target requires till we get a failure (if any). 

The upper limit might change according to the instruction, as said a simple R-type instruction requires only 5 bit operand (2 power of 5 possible values) instead an immediate one would require more (up tio 2 power of 7) 

Few considerations before starting describing the design behaviour:

- There is not use of the RS1-RS2-RS3 operand selector, when required it just uses the value straight (same as the model provided)
- The RTL is autogenerate which makes overly complicated the fix eventually
- The instruction to be fed changes according to the type (the change would be big enough sometimes)
- There are some instruction that are not needed to be tested (model doesn't implement those)
- The model has no concept of ENABLE output as RTL does

There is one unique test scenario which basically loop through:

1. All possible Instruction type
    1. Loops through again all possible instruction belonging to the same TYPE
        1. loops trhough all possible values of the inputs which are basically shoufled. Just a note here we might have a huge space made by {32,32,32} total element to be looping through for all possible computation and repetition. Anyway testing along just a small space is more then enough.
2. By updating the spacelimit the simulation would probably take longer but ther coverage will increase (ideally we should have 1 test to be ran in parallel with a huge space per instructions but this would require an additional test suite)

### run_test

```py
for Itype in IIstr.keys():
        print("Testing TYPE: {}".format(Itype))
        for instr in IIstr[Itype].keys():
            iis = IIstr[Itype][instr]
            ## Testing only instruction not to be ingnored
            if(iis[3] == False):
                print("Testing Instruction: {}".format(instr))
                ######### CTB : Modify the test to expose the bug #############
                # input transaction make them as a list and fill them out with all possible values
                mav_putvalue_src1 = []
                mav_putvalue_src2 = []
                mav_putvalue_src3 = []
                placeholderInstr  = []

                # Each SRC is a 5 bit register, SRC3 is not always used for all the instructions same for SRC2
                for tot in range(SpaceLimit):
                    mav_putvalue_src1.append(random.randrange(0,2**32-1))
                    ## For an ITYPE instruction RS2 becomes a Immediate value
                    if(Itype == "ITYPE" or instr == "FSRI"):
                        mav_putvalue_src2.append(random.randrange(0,2**7-1))
                    else:
                        mav_putvalue_src2.append(random.randrange(0,2**32-1))
                    ## TEST out that RS3 is not used while not required
                    if(Itype != "R4TYPE"):
                        ## F7
                        mav_putvalue_src3.append(iis[0])
                    else:
                        ## DATA
                        mav_putvalue_src3.append(random.randrange(0,2**32-1))

                ## Compute the instruction
                if(Itype == "RTYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))]))
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))]))
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00000,5))]))
                    placeholderInstr[20:24] = list(reversed([d for d in str('{0:0{1}b}'.format(0b01000,5))]))
                    placeholderInstr[25:31] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 7))]))
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)        
                if(Itype == "ITYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))]))
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))]))
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[20:26] = list(reversed([d for d in str('{0:0{1}b}'.format(mav_putvalue_src2[tot],7))]))
                    placeholderInstr[27:32] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 5))]))
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)
                if(Itype == "R4TYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))])) ## OPCODE
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RD
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))])) ## F3
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RS1
                    if(instr == "FSRI"):
                        placeholderInstr[20:25] = list(reversed([d for d in str('{0:0{1}b}'.format(mav_putvalue_src2[tot],6))])) ## IMM
                        placeholderInstr[26:26] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 0))])) ## F2
                    else:
                        placeholderInstr[20:24] = list(reversed([d for d in str('{0:0{1}b}'.format(0b01000,5))])) ## RS2
                        placeholderInstr[25:26] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 2))])) ## F2
                    placeholderInstr[27:31] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RS3
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)

                ## Shuffle the lists so that if we loop into we do not align data
                random.shuffle(mav_putvalue_src1)
                random.shuffle(mav_putvalue_src2)
                random.shuffle(mav_putvalue_src3)

                ## looping: 
                # -> if we have an IMM instruction we skip SRC2 and we get IMM
                # -> if we have a not FUNC7 used instruction then we use SRC1-2-3
                # -> if we one of the remaining instruction instead we do used only SRC1-2
                for tot in range(SpaceLimit):
                    # PRINT STATE
                    cocotb.log.debug("SRC1: {}".format(bin(mav_putvalue_src1[tot])))
                    cocotb.log.debug("SRC2: {}".format(bin(mav_putvalue_src2[tot])))
                    cocotb.log.debug("SRC3: {}".format(bin(mav_putvalue_src3[tot])))
                    cocotb.log.debug("INSTRUCTION: {}".format(bin(mav_putvalue_instr)))

                    # expected output from the model
                    expected_mav_putvalue = bitmanip(mav_putvalue_instr, mav_putvalue_src1[tot], mav_putvalue_src2[tot], mav_putvalue_src3[tot])

                    # driving the input transaction
                    dut.mav_putvalue_src1.value     = mav_putvalue_src1[tot]
                    dut.mav_putvalue_src2.value     = mav_putvalue_src2[tot]
                    dut.mav_putvalue_src3.value     = mav_putvalue_src3[tot]
                    dut.EN_mav_putvalue.value       = 1
                    dut.mav_putvalue_instr.value    = mav_putvalue_instr
                
                    await Timer(1) 

                    # obtaining the output
                    dut_output = dut.mav_putvalue.value
                    
                    # comparison
                    error_message = f'Value mismatch DUT = {bin(dut_output)} does not match MODEL = {bin(expected_mav_putvalue)}'
```

### Error collector

To avoid having many error being printed I made a simple error collector being filled anytime there was an error per instruction. This helps out to avoid stopping the sim once the Instruction is on going due the enxtensive nature of the above test bench.

```python
                    try:
                        assert dut_output == expected_mav_putvalue
                    except AssertionError as ex:
                        ##ErrorCNT[instr] = ErrorCNT[instr] + 1
                        ErrorCNT = ErrorCNT + 1
                        cocotb.log.error(error_message)
                        ## Final print
                        cocotb.log.info(f'DUT OUTPUT={bin(dut_output)}')
                        cocotb.log.info(f'EXPECTED OUTPUT={bin(expected_mav_putvalue)}')

            ## Update the Instruction error dictionary
            ErrorDict[instr]    = ErrorCNT
            ErrorCNT            = 0 ## Needs to be zeroinit again
    ## Final Check
    for FailInstr in ErrorDict.keys():
        ## Make test fail
        if(ErrorDict[FailInstr] != 0): 
            assert 0,"TEST FAILING for instruction: {}".format(FailInstr)
```

### Dictionary Approach

A dictionary for instruction and an instruction glue logic has been added into the tesbench to make the looping machanism more consistent:

```python
## Dictionary of each instruction to be easy looped
IIstr = {
    "RTYPE": {
        ## OP:      F7 ------ F3 -- OPCODE -- Ignore               
        "AND":      [0b0000000,0b111,0b0110011,True],
        "OR" :      [0b0000000,0b110,0b0110011,True],
        "XOR":      [0b0000000,0b100,0b0110011,True],
        "ANDN":     [0b0100000,0b111,0b0110011,False],
        "ORN":      [0b0100000,0b110,0b0110011,False],
        "XORN":     [0b0100000,0b100,0b0110011,False],
        "SLL":      [0b0000000,0b001,0b0110011,True],
        "SRL":      [0b0000000,0b101,0b0110011,True],
        "SRA":      [0b0100000,0b101,0b0110011,True],
        "SLO":      [0b0010000,0b001,0b0110011,False],
        "SRO":      [0b0010000,0b101,0b0110011,False],
        "ROL":      [0b0110000,0b001,0b0110011,True],
        "ROR":      [0b0110000,0b101,0b0110011,False],
        "SBCLR":    [0b0100100,0b001,0b0110011,True],
        "SBSET":    [0b0010100,0b001,0b0110011,True],
        "SBINV":    [0b0110100,0b001,0b0110011,True],
        "SBEXT":    [0b0100100,0b101,0b0110011,False],
        "GORC":     [0b0010100,0b101,0b0110011,False],
        "GREV":     [0b0110100,0b101,0b0110011,False]        
    },
    "ITYPE": {
        ## OP:       F7 ---- F3 -- OPCODE -- Ignore               
        "SLLI":     [0b00000,0b111,0b0010011,True],
        "SRLI" :    [0b00000,0b110,0b0010011,True],
        "SRAI":     [0b01000,0b100,0b0010011,True],
        "SLOI":     [0b00100,0b001,0b0010011,False],
        "SROI":     [0b00100,0b101,0b0010011,False],
        "RORI":     [0b01100,0b101,0b0010011,False],
        "SBCLRI":   [0b01001,0b001,0b0010011,True],
        "SBSETI":   [0b00101,0b001,0b0010011,True],
        "SBINVI":   [0b01101,0b001,0b0010011,True],
        "SBEXTI":   [0b01001,0b101,0b0010011,False],
        "GORCI":    [0b00101,0b101,0b0010011,False],
        "GREVI":    [0b01101,0b101,0b0010011,False]         
    },
    "R4TYPE": {
        ## OP:       F2 - F3 -- OPCODE -- Ignore
        "CMIX":     [0b11,0b001,0b0110011,False],
        "CMOV" :    [0b11,0b101,0b0110011,False],
        "FSL":      [0b10,0b001,0b0110011,False],
        "FSR":      [0b10,0b101,0b0110011,False],
        "FSRI":     [0b1,0b101,0b0110011,False]         
    }    
}
```

and as stated the glue instruction maker:

```python
                ## Compute the instruction
                if(Itype == "RTYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))]))
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))]))
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00000,5))]))
                    placeholderInstr[20:24] = list(reversed([d for d in str('{0:0{1}b}'.format(0b01000,5))]))
                    placeholderInstr[25:31] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 7))]))
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)        
                if(Itype == "ITYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))]))
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))]))
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))]))
                    placeholderInstr[20:26] = list(reversed([d for d in str('{0:0{1}b}'.format(mav_putvalue_src2[tot],7))]))
                    placeholderInstr[27:32] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 5))]))
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)
                if(Itype == "R4TYPE"):
                    placeholderInstr[0:6]   = list(reversed([d for d in str('{0:0{1}b}'.format(iis[2], 7))])) ## OPCODE
                    placeholderInstr[7:11]  = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RD
                    placeholderInstr[12:14] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[1], 3))])) ## F3
                    placeholderInstr[15:19] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RS1
                    if(instr == "FSRI"):
                        placeholderInstr[20:25] = list(reversed([d for d in str('{0:0{1}b}'.format(mav_putvalue_src2[tot],6))])) ## IMM
                        placeholderInstr[26:26] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 0))])) ## F2
                    else:
                        placeholderInstr[20:24] = list(reversed([d for d in str('{0:0{1}b}'.format(0b01000,5))])) ## RS2
                        placeholderInstr[25:26] = list(reversed([d for d in str('{0:0{1}b}'.format(iis[0], 2))])) ## F2
                    placeholderInstr[27:31] = list(reversed([d for d in str('{0:0{1}b}'.format(0b00001,5))])) ## RS3
                    placeholderInstr = list(reversed(placeholderInstr))
                    mav_putvalue_instr = int("".join(placeholderInstr),2)
```

## Design Bug

Since the RTL was autogenerated was hard to figure out where the bug could be. Nevertheless the bug found was related to the ANDN.

## Bug Fix (if any)

Since the RTL was autogenerated was hard to figure out where the bug could be. Nevertheless the bug found was related to the ANDN (this is the only one found), fixing the logic for the ANDN was resulting into an additional BUG for CMIX so i just gave up due to how hard was to manually tweak the file.