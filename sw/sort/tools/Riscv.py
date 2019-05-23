import sys

opcode_LOAD      = 0x03
opcode_OP_IMM    = 0x13
opcode_AUIPC     = 0x17
opcode_STORE     = 0x23
opcode_OP        = 0x33
opcode_LUI       = 0x37
opcode_BRANCH    = 0x63
opcode_JALR      = 0x67
opcode_JAL       = 0x6F

# -- LOAD sub-opcodes
funct3_LW  = 0x2
funct3_LWU = 0x6

# -- MISC_MEM sub-opcodes

# -- OP_IMM sub-opcodes
funct3_ADDI  = 0x0
funct3_SLLI  = 0x1
funct3_SLTI  = 0x2
funct3_SLTIU = 0x3
funct3_XORI  = 0x4
funct3_SRLI  = 0x5
funct3_SRAI  = 0x5
funct3_ORI   = 0x6
funct3_ANDI  = 0x7

# -- OP_IMM.SLLI/SRLI/SRAI for RV32
funct7_SLLI  = 0x00
funct7_SRLI  = 0x00
funct7_SRAI  = 0x20

# -- STORE sub-opcodes
funct3_SW = 0x2

# -- OP sub-opcodes
funct3_ADD  = 0x0
funct7_ADD  = 0x00
funct3_SUB  = 0x0
funct7_SUB  = 0x20
funct3_SLL  = 0x1
funct7_SLL  = 0x00
funct3_SLT  = 0x2
funct7_SLT  = 0x00
funct3_SLTU = 0x3
funct7_SLTU = 0x00
funct3_XOR  = 0x4
funct7_XOR  = 0x00
funct3_SRL  = 0x5
funct7_SRL  = 0x00
funct3_SRA  = 0x5
funct7_SRA  = 0x20
funct3_OR   = 0x6
funct7_OR   = 0x00
funct3_AND  = 0x7
funct7_AND  = 0x00

# -- BRANCH sub-opcodes
funct3_BEQ  = 0x0
funct3_BNE  = 0x1
funct3_BLT  = 0x4
funct3_BGE  = 0x5
funct3_BLTU = 0x6
funct3_BGEU = 0x7

def signExtend(bits,val):
        if (val & (1 << (bits -1))) != 0:
                val = val - ( 1<<bits)
        return val

def mod(a,b):
        return(a % b)

def unsigned(a):
        return (a & 0xFFFFFFFF)

def bit(a):
        beginning = bin(a)[2:][::-1]
        return beginning + '0'*(32-len(beginning))

def signed32(x):
    val32 = x & 0xFFFFFFFF
    if val32 & 0x80000000:
        return -((val32 ^ 0xFFFFFFFF) + 1)
    else:
        return val32

class BitString(int):
    def __getitem__(self,idx):
        if isinstance(idx, slice):
            assert isinstance(idx.start, int)
            assert isinstance(idx.stop, int)
            assert idx.start < idx.stop
            assert idx.step is None or idx.step == 1
            mask = (1 << (idx.stop - idx.start)) - 1
            return (self >> idx.start) & mask
        else:
            return 1 if self & (1 << idx) else 0


class Passed(BaseException):
    pass
class Failed(BaseException):
    pass
class Breakpoint(BaseException):
    pass
class Bug(BaseException):
    pass

def raiseException(a, b):
    raise Bug("\nError. Exception triggered: " + str(a) + ", " + str(b))

PASSED = 0;
FAILED = -1;
BREAKPOINT = 1;
NORMAL = 2;
BUG = 3;

INSTR_LIMIT = 300000
class RVMachine:
        def __init__(self):
                self.registers = [0]*32
                self.memory = [0]*16*16384
                self.pc = 0
                self.nextPc = 0
                self.inst = 0
                # Argument passing
                self.app = ''
                self.arg = 0
                # Debugging
                self.breakpoints = []
                self.justTaken = False
                # Stats
                self.instrs = 0;
        def restart(self):
            self.__init__()

        def getInstrs(self):
            return self.instrs

        def getRegister(self,idx):
                return self.registers[idx]
        def setRegister(self,idx,value):
                if idx > 0:
                        self.registers[idx]=signed32(value)
        def loadWord(self,addr):
                if (addr == 0x40003000): # sync with src/main.c
                    return self.arg
                else:
                    return self.memory[addr>>2]
        def storeWord(self,addr,val):
                if (addr == 0x40000000):
                        sys.stdout.write(chr(val))
                elif (addr == 0x40001000):
                        if (val == 0):
                            raise Passed()
                        else:
                            raise Failed()
                elif (addr == 0x40002000):
                    raise Breakpoint() # TODO: not used
                else:
                        self.memory[addr>>2] = signed32(val)
        def setPC(self,newpc):
                if (self.pc < 0 or self.pc >= 2**16):
                    raise Bug("\nError: PC out of bound")
                self.nextPc = newpc

        def loadHex(self,filename):
                self.app = filename
                with open(filename,'r') as f:
                        position = 0
                        for i in f.readlines():
                                if i[0]=="@" :
                                        position = int(i[1:],16)
                                else:
                                        self.memory[position>>2]=signed32(int(i,16))
                                        position = position + 4
        def loadArg(self,arg):
            self.arg = arg

        def setBreakpoints(self, bps):
            for bp in bps:
                if bp % 4 != 0:
                    raise Bug("\nError: Bad break point: " + str(hex(bp)) + " is not a multiple of 4!")
            self.breakpoints = bps
        def addBreakpoints(self, bps):
            for bp in bps:
                if bp % 4 != 0:
                    raise Bug("\nError: Bad break point: " + str(hex(bp)) + " is not a multiple of 4!")
            self.breakpoints += bps
        def clearBreakpoints(self, bps=[]):
            if bps == []:
                self.breakpoints = []
            else:
                self.breakpoints = [i for i in self.breakpoints if i not in bps]

        @property
        def getPC(self):
                if (self.pc < 0 or self.pc >= 2**16):
                    raise Bug("\nError: PC out of bound")
                return self.pc

        @property
        def opcode(self): return  (BitString(self.inst)[0:7])
        @property
        def funct3(self): return  (BitString(self.inst)[12:15])
        @property
        def funct7(self): return  (BitString(self.inst)[25:32])
        @property
        def funct10(self): return  (( ((BitString(self.inst)[25:32])) << 3)) | ((BitString(self.inst)[12:15]))
        @property
        def funct12(self): return  (BitString(self.inst)[20:32])
        @property
        def rd(self): return  (BitString(self.inst)[7:12])
        @property
        def rs1(self): return  (BitString(self.inst)[15:20])
        @property
        def rs2(self): return  (BitString(self.inst)[20:25])
        @property
        def rs3(self): return  (BitString(self.inst)[27:32])
        @property
        def succ(self): return  (BitString(self.inst)[20:24])
        @property
        def pred(self): return  (BitString(self.inst)[24:28])
        @property
        def msb4(self): return  (BitString(self.inst)[28:32])
        @property
        def imm20(self): return  signExtend(32, ( ((BitString(self.inst)[12:32])) << 12))
        @property
        def oimm20(self): return  signExtend(32, ( ((BitString(self.inst)[12:32])) << 12))
        @property
        def jimm20(self): return  signExtend(21, (( ((BitString(self.inst)[31:32])) << 20)  | ( ((BitString(self.inst)[21:31])) << 1)  | ( ((BitString(self.inst)[20:21])) << 11) | ( ((BitString(self.inst)[12:20])) << 12)))
        @property
        def imm12(self): return  signExtend(12, (BitString(self.inst)[20:32]))
        @property
        def oimm12(self): return  signExtend(12, (BitString(self.inst)[20:32]))
        @property
        def csr12(self): return  (BitString(self.inst)[20:32])
        @property
        def simm12(self): return  signExtend(12, ( ((BitString(self.inst)[25:32])) << 5) | (BitString(self.inst)[7:12]))
        @property
        def sbimm12(self): return  signExtend(13, (( ((BitString(self.inst)[31:32])) << 12) | ( ((BitString(self.inst)[25:31])) << 5) | ( ((BitString(self.inst)[8:12])) << 1)  | ( ((BitString(self.inst)[7:8])) << 11)))
        @property
        def shamt5(self): return  (BitString(self.inst)[20:25])
        @property
        def shamt6(self): return  (BitString(self.inst)[20:26])
        @property
        def funct6(self): return  (BitString(self.inst)[26:32])
        @property
        def zimm(self): return  (BitString(self.inst)[15:20])


        def fetch(self):
                if not self.justTaken and self.pc in self.breakpoints:
                    self.justTaken = True
                    raise Breakpoint()
                self.justTaken = False
                self.inst = self.memory[self.pc >> 2]

        def execute(self):
                #add a try statement if you don't know
                if self.opcode==opcode_LOAD and self.funct3==funct3_LW  : self.executeLw()
                elif self.opcode==opcode_AUIPC  : self.executeAuipc()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_ADDI                                : self.executeAddi()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_SLLI and self.funct7==funct7_SLLI : self.executeSlli()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_SLTI                                : self.executeSlti()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_SLTIU                               : self.executeSltiu()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_XORI                                : self.executeXori()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_ORI                                 : self.executeOri()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_ANDI                                : self.executeAndi()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_SRLI and self.funct7==funct7_SRLI : self.executeSrli()
                elif self.opcode==opcode_OP_IMM and self.funct3==funct3_SRAI and self.funct7==funct7_SRAI : self.executeSrai()
                elif self.opcode==opcode_STORE and self.funct3==funct3_SW : self.executeSw()
                elif self.opcode==opcode_OP and self.funct3==funct3_ADD and  self.funct7==funct7_ADD  : self.executeAdd()
                elif self.opcode==opcode_OP and self.funct3==funct3_SUB and  self.funct7==funct7_SUB  : self.executeSub()
                elif self.opcode==opcode_OP and self.funct3==funct3_SLL and  self.funct7==funct7_SLL  : self.executeSll()
                elif self.opcode==opcode_OP and self.funct3==funct3_SLT and  self.funct7==funct7_SLT  : self.executeSlt()
                elif self.opcode==opcode_OP and self.funct3==funct3_SLTU and self.funct7==funct7_SLTU : self.executeSltu()
                elif self.opcode==opcode_OP and self.funct3==funct3_XOR and  self.funct7==funct7_XOR  : self.executeXor()
                elif self.opcode==opcode_OP and self.funct3==funct3_SRL and  self.funct7==funct7_SRL  : self.executeSrl()
                elif self.opcode==opcode_OP and self.funct3==funct3_SRA and  self.funct7==funct7_SRA  : self.executeSra()
                elif self.opcode==opcode_OP and self.funct3==funct3_OR and   self.funct7==funct7_OR   : self.executeOr()
                elif self.opcode==opcode_OP and self.funct3==funct3_AND and  self.funct7==funct7_AND  : self.executeAnd()
                elif self.opcode==opcode_LUI : self.executeLui()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BEQ  : self.executeBeq()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BNE  : self.executeBne()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BLT  : self.executeBlt()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BGE  : self.executeBge()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BLTU : self.executeBltu()
                elif self.opcode==opcode_BRANCH and self.funct3==funct3_BGEU : self.executeBgeu()
                elif self.opcode==opcode_JALR : self.executeJalr()
                elif self.opcode==opcode_JAL  : self.executeJal()
                else                     : self.executeInvalidInstruction()

        def updatePc(self):
                self.pc = self.nextPc
                # Stats
                self.instrs += 1
                if self.instrs > INSTR_LIMIT:
                    raise Bug("\nError: Time out. Potentially an infinite loop is encountered.")

        def step(self):
            try:
                self.fetch()
                self.nextPc = self.pc+4
                self.execute()
                self.updatePc()
                return NORMAL
            except Passed:
                return PASSED
            except Failed:
                return FAILED
            except Breakpoint as e:
                print("\nBreak point reached at " + str(hex(self.getPC)) + "...\n")
                return BREAKPOINT
            except Bug as e:
                print(e)
                print("PC = " + str(hex(self.getPC)))
                return BUG

        def run(self, program_name):
            while True:
                code = self.step()
                if code in [PASSED, FAILED, BREAKPOINT, BUG]:
                    if code == PASSED:
                        print("Project."+program_name+str(self.arg)+": PASSED\n")
                    if code == FAILED:
                        if (self.arg != 0):
                            print("Project."+program_name+str(self.arg)+": FAILED - Failed Test " + str(self.arg) + "\n")
                        else:
                            print("Project."+program_name+": FAILED - Ran all tests and failed at least 1\n")
                    if code == BUG:
                        print("Project."+program_name+str(self.arg)+": FAILED due to a bug. Consult your local VM.\n")
                    return code
                    return code

                ########################
                ###   Instructions   ###
                ########################

        def executeInvalidInstruction(self):
            raise Bug("\nError: Invalid instruction at pc(" + str(hex(self.pc)) + ") encountered.")


        def executeAuipc(self):
                 pc = self.getPC
                 (self.setRegister(self.rd, self.oimm20 + pc))

        def executeLui(self):
                (self.setRegister(self.rd,self.imm20))


        def executeJal(self):
                pc  =  self.getPC
                newPC = (pc + ((self.jimm20)))
                if ((mod(newPC,4)) != 0) :
                        (raiseException(0,0))
                else:
                        (self.setRegister(self.rd,(((pc)) + 4)))
                        (self.setPC(newPC))


        def executeJalr(self):
                x  =  (self.getRegister(self.rs1))
                pc  =  self.getPC
                newPC = (x + ((self.oimm12)))
                if ((mod(newPC,4)) != 0) :
                        (raiseException(0,0))
                else:
                        (self.setRegister(self.rd,(((pc)) + 4)))
                        (self.setPC(newPC))


        def executeBeq(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if (x == y) :
                        newPC = (pc + ((self.sbimm12)))
                        if ((mod(newPC,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(newPC))
                else:
                        pass


        def executeBne(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if (x != y) :
                        addr = (pc + ((self.sbimm12)))
                        if ((mod(addr,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(addr))
                else:
                        pass


        def executeBlt(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if (x < y) :
                        addr = (pc + ((self.sbimm12)))
                        if ((mod(addr,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(addr))
                else:
                        pass


        def executeBge(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if ( x >= y) :
                        addr = (pc + ((self.sbimm12)))
                        if ((mod(addr,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(addr))
                else:
                        pass


        def executeBltu(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if ((unsigned(x)) < (unsigned(y))) :
                        addr = (pc + ((self.sbimm12)))
                        if ((mod(addr,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(addr))
                else:
                        pass


        def executeBgeu(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                pc  =  self.getPC
                if ( (unsigned(x)) >= (unsigned(y))) :
                        addr = (pc + ((self.sbimm12)))
                        if ((mod(addr,4)) != 0) :
                                (raiseException(0,0))
                        else:
                                (self.setPC(addr))
                else:
                        pass


        def executeLw(self):
                a  =  (self.getRegister(self.rs1))
                addr = (a + ((self.oimm12)))
                if ((mod(addr,4)) != 0) :
                        (raiseException(0,4))
                else:
                        x  =  (self.loadWord(addr))
                        (self.setRegister(self.rd,x))



        def executeSw(self):
                a  =  (self.getRegister(self.rs1))
                addr = (a + ((self.simm12)))
                if ((mod(addr,4)) != 0) :
                        (raiseException(0,6))
                else:
                        x  =  (self.getRegister(self.rs2))
                        (self.storeWord(addr,x))


        def executeAddi(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(x + ((self.imm12)))))


        def executeSlti(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(1 if (x < ((self.imm12))) else 0)))


        def executeSltiu(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(1 if ((unsigned(x)) < ((self.imm12))) else 0)))


        def executeXori(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(x ^ ((self.imm12)))))


        def executeOri(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(x | ((self.imm12)))))


        def executeAndi(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,( x & ((self.imm12)))))


        def executeSlli(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(unsigned(x)<<self.shamt6)))


        def executeSrli(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(unsigned(x)>>self.shamt6)))


        def executeSrai(self):
                x  =  (self.getRegister(self.rs1))
                (self.setRegister(self.rd,(x>>self.shamt6)))


        def executeAdd(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(x + y)))


        def executeSub(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(x - y)))


        def executeSll(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(unsigned(x)<<y)))


        def executeSlt(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(1 if (x < y) else 0)))


        def executeSltu(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(1 if ((unsigned(x)) < (unsigned(y))) else 0)))


        def executeXor(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(x^y)))


        def executeOr(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(x | y)))


        def executeSrl(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(unsigned(x)>>y)))


        def executeSra(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,(x>>y)))


        def executeAnd(self):
                x  =  (self.getRegister(self.rs1))
                y  =  (self.getRegister(self.rs2))
                (self.setRegister(self.rd,( x & y)))
