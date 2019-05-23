import tools.Riscv as Riscv
import os, sys, argparse

autograde = False

def hex32(a):
    return hex(a & (2**32-1))

def getConsoleCols():
    rows, columns = os.popen('stty size', 'r').read().split()
    return columns

def display(table, header, format, width=0):
    global autograde
    if autograde:
        return ""
    assert(len(table[0]) == len(header))
    numRows = len(table)
    numCols = len(header)
    widths = [0] * numCols
    for row in table:
        for i in range(numCols):
            widths[i] = max(widths[i], len(row[i]))
    for i in range(numCols):
        widths[i] = max(widths[i], len(header[i]))
    warning = False
    if width == 0:
        width = int(getConsoleCols())
    maxIRep = width // (sum(widths) + numCols * 3 + 1)
    if (maxIRep < 1):
        warning = True
        maxIRep = 1
    jRep = (numRows + maxIRep - 1) // maxIRep
    iRep = numRows // jRep
    iRepLong = iRep + 1
    iRepLongNum = numRows % jRep

    res = ""
    for i in range(iRepLong if iRepLongNum != 0 else iRep):
        for c in range(numCols):
            half = (widths[c] + 1 - len(header[c])) // 2
            res += ("|" + " " * (half + 1) + header[c] + " " * (widths[c] + 1 - len(header[c]) - half))
        res += ("|")
    res += ("\n")
    i = j = 0
    while (j < jRep - 1 or (j == jRep - 1 and i < iRep)):
        if (j < iRepLongNum and i == iRepLong) or (j >= iRepLongNum and i == iRep):
            res += ("\n")
            j += 1
            i = 0
        for c in range(numCols):
            newR = i * jRep + j
            if format[c] == "r":
                res += ("|" + " " * (widths[c] + 1 - len(table[newR][c])) + table[newR][c] + " ")
            elif format[c] == "l":
                res += ("|" + " " + table[newR][c] + " " * (widths[c] + 1 - len(table[newR][c])))
        res += ("|")
        i += 1
    res += ("\n\n")
    if (warning):
        res += "Please increase the width of the console for a better display.\n"
    return res

## Functions that control the simulation
def run(program_name):
    return m.run(program_name)
    #sys.stdout.flush()

def step(n=1):
    for n in range(n):
        code = m.step()
    #sys.stdout.flush()
    return code

## Functions that handle break points
def setBps(bps):
    m.setBreakpoints(bps)

def addBps(bps):
    m.addBreakpoints(bps)

def clearBps(bps=[]):
    m.clearBreakpoints(bps)

## Functions that print stuff
def showStats(width=0):
    return display([["Executed Instrs", str(m.instrs)]], ["", "Value"], 'rl', width)

def showRegs(width=0):
    res = display([['pc', str(hex32(m.getPC))]], ['Register', 'Value(HEX)'], 'rr', width)
    regNames = ['x' + str(i) for i in range(32)]
    regABINames = ['zero', 'ra', 'sp', 'gp', 'tp', 't0', 't1', 't2', 's0/fp', 's1']
    regABINames.extend(['a' + str(i) for i in range(8)])
    regABINames.extend(['s' + str(i) for i in range(2, 12)])
    regABINames.extend(['t' + str(i) for i in range(3, 7)])
    regHeader = ['Register', 'ABI name', 'Value(DEC)', 'Value(HEX)']
    table_data = [[regNames[i], regABINames[i], str(m.registers[i]), str(hex32(m.registers[i]))] for i in range(32)]
    res += display(table_data, regHeader, 'rrrr', width)
    return res

def showMem(start, end='', width=0):
    if end == '':
        end = start + 4
    header = ['Address', 'Value(HEX)']
    table_data = [[str(hex32(i)), str(hex32(m.memory[i >> 2]))] for i in range(start, end, 4)]
    return display(table_data, header, 'rr', width)

def showStack(width=0):
    sp = m.registers[2]
    if (sp > 0x10000):
        return "Stack pointer out of bound."
    if (sp == 0):
        return "Stack pointer has not been initialized. Check it out later."
    res = display([['x2', 'sp', str(hex32(sp))]], ['Register', 'ABI name', 'Value(HEX)'], 'rrr', width)
    return res + showMem(sp, 0x10004, width)

# Functions that check the dump file
def showInstr(pc=''):
    if pc == '':
        pc = m.getPC
    pc = str(hex32(pc)).split('x')[-1]
    res = ""
    dumpFile = m.app.split('.')[0] + ".dump"
    try:
        with open(dumpFile, 'r') as f:
            skip = False
            for line in f:
                if "Disassembly of section .comment" in line:
                    skip = True
                elif "Disassembly of section" in line:
                    skip = False
                elif not skip and " " + pc + ":" in line:
                    res += "Instruction at 0x" + pc + ":\n"
                    res += line
    except IOError:
        return "File " + dumpFile + " does not exist."
    return res

def showLabelPC(label='', width=0):
    label = str(label)
    res = ""
    dumpFile = m.app.split('.')[0] + ".dump"
    try:
        with open(dumpFile, 'r') as f:
            for line in f:
                if "<" + label + ">:" in line:
                    pc = int(line.split(' ')[0], 16)
                    res += display([['<' + label + '>', str(hex32(pc))]], ['Label', 'PC(HEX)'], 'rr', width)
    except IOError:
        return "File " + dumpFile + " does not exist."
    return res
def restart():
    m.restart()

def loadHex(app):
    m.loadHex(app)

def loadArg(arg):
    m.loadArg(arg)

def setAuto(auto):
    global autograde
    autograde = auto
    

def getInstrs():
    return m.getInstrs()

def getPC():
    return m.getPC
## Run the program
m = Riscv.RVMachine()
