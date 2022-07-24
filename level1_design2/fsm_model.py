from enum import Enum
from random import randrange

class states(Enum):
    IDLE        = 0,
    SEQ_1       = 1, 
    SEQ_10      = 2,
    SEQ_101     = 3,
    SEQ_1011    = 4,
    INVALID     = 5

class fsm:
    def __init__(self, init_val: int, randomize: bool):
        if(init_val == 1):
            self.state = states.IDLE
        else:
            assert 1, "Init FSM model with a 0 reset"
        self.randomize = randomize
        ## Init internal pattern LIST
        self.pattern        = [1,1,1,0,1,1,1,0,1,0,1,0,1,1,0,0,1,0,1,1]
        self.Rand_pattern   = []
        self.cnt            = 0
    
    def countSequence(self, s: str) -> int:
        cnt = 0
        for ii in range(len(s)):
            if(s[ii:ii+4] == "1011"):
               cnt = cnt + 1 
        return cnt

    def set_state(self, in_s: int):
        self.state = in_s

    def get_state(self) -> states:
        return self.state

    def getSeen(self) -> bool:
        return (self.get_state() == states.SEQ_1011)
    
    def getCNT(self) -> int:
        return self.cnt

    def getPattern(self) -> list:
        ## Randomize the pattern
        for el in range(10):
            self.Rand_pattern.append(bin(randrange(0,15)).replace("0b", ""))
        # Converting integer list to string list split each element of the pattern
        if(self.randomize == True):
            tmp = "".join([i for i in self.Rand_pattern])
            self.cnt = self.countSequence(tmp)
            return ([int(i,2) for i in tmp])
        else:
            self.cnt = ''.join([str(i) for i in self.pattern]).count('1011')
            return self.pattern

    def convertState(self, inp_state: int) -> states:
        if(inp_state == 0):
            return states.IDLE
        if(inp_state == 1):
            return states.SEQ_1
        if(inp_state == 2):
            return states.SEQ_10
        if(inp_state == 3):
            return states.SEQ_101
        if(inp_state == 4):
            return states.SEQ_1011

    def buttonTrans(self, bin: int):
        ## IDLE -> SEQ_1
        if(self.get_state() == states.IDLE):
            if(bin == 1):
                self.set_state(states.SEQ_1)
            else:
                self.set_state(states.IDLE)
        ## SEQ_1 -> SEQ_10
        elif(self.get_state() == states.SEQ_1):
            if(bin == 1):
                self.set_state(states.SEQ_1)
            else:
                self.set_state(states.SEQ_10)
        ## SEQ_10 -> SEQ_101
        elif(self.get_state() == states.SEQ_10):
            if(bin == 1):
                self.set_state(states.SEQ_101)
            else:
                self.set_state(states.IDLE)
        ## SEQ_101 -> SEQ_1011
        elif(self.get_state() == states.SEQ_101):
            if(bin == 1):
                self.set_state(states.SEQ_1011)
            else:
                self.set_state(states.SEQ_101)
        ## SEQ_1011 -> IDLE regardless
        elif(self.get_state() == states.SEQ_1011):
            ## Once the SEQ is seen just incr the counter if needed
            if(bin == 1):
                self.set_state(states.SEQ_10)
            else:
                self.set_state(states.SEQ_1)

    def getValid_pkt(self) -> dict:
        return {    states.SEQ_1    :   1,    
                    states.SEQ_10   :   0,
                    states.SEQ_101  :   1,
                    states.SEQ_1011 :   1}
    
    def getInvalid_pkt(self, outP: list):
        ## Randomize the pattern to avoid getting the right sequence in it
        for el in range(20):
            self.Rand_pattern.append(bin(randrange(0,15)).replace("0b", ""))
        # Converting integer list to string list split each element of the pattern
        tmp = "".join([i for i in self.Rand_pattern])
        for el in range(len(tmp)):
            tmp.replace("1011", "")
        if(self.cnt == 0):
            outP = ([int(i,2) for i in tmp])
        else:
            assert 0, "Not able to generate an INVALID pattern"