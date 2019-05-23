import tools.wrapper as w
import argparse
import ctypes, os

program_name = ""
def interactive_inspect_mode():
    flagPtr = ctypes.cast(ctypes.pythonapi.Py_InteractiveFlag, 
    ctypes.POINTER(ctypes.c_int))
    return flagPtr.contents.value > 0 or bool(os.environ.get("PYTHONINSPECT",False))

def help():
    helpList = [
            ['run()', 'Run program until it either finishes or reaches',   ''],
            ['', 'a break point.',                   ''], #TODO: explain outputs
            ['step(<n>)', 'Run <n> more instructions and stop.','step() # same as step(1)'],
            ['setBps([<pc0>, ...])', 'Clear previous break points and new ones.', 'setBps([0x4c]) # Break when pc == 0x4c'],
            ['', '',                                            'setBps([76]) # Break when pc == 76'],
            ['addBps([<pc0>, ...])', 'Add break points.',       ''],
            ['clearBps([<pc0>, ...])', 'Clear break points.',   'clearBps() # Clear all break points'],
            ['showStats()', 'List statistics, e.g. instruction counts', ''],
            ['showRegs()', 'List registers including pc register',      ''],
            ['showMem(<start>, <end>)', 'List memory layout from address <start> to <end>', 'showMem(0x8) # show the word at 0x8 only'],
            ['showStack()', 'List memory layout of the stack specified by', ''],
            ['', 'register x2(sp)', ''],
            ['showInstr(<pc>)', 'Display the instruction at <pc>', 'showInstr() # show next instruction'],
            ['showLablePC(<label>)', 'Display the PC of <label>', 'showLabelPC("sort") # show address of <sort>'],
            ['restart()', 'Restart the execution.', ''],
    ]
    print(w.display(helpList, ['Command', 'Description', 'Example'], 'lll'))

## Functions that control the simulation
def run():
    ret = w.run(program_name)
    showStats()

def step(n=1):
    w.step(n)
    showStats()

def restart():
    w.restart()
    w.loadHex(args.program_name + ".vmh")
    w.loadArg(args.test_number)
    showStats()

## Functions that handle break points
def setBps(bps):
    w.setBps(bps)

def addBps(bps):
    w.addBps(bps)

def clearBps(bps=[]):
    w.clearBps(bps)

## Functions that print stuff
def showStats():
    print(w.showStats())

def showRegs():
    print(w.showRegs())

def showMem(start, end=''):
    print(w.showMem(start, end))

def showStack():
    print(w.showStack())

# Functions that check the dump file
def showInstr(pc=''):
    print(w.showInstr(pc))

def showLabelPC(label=''):
    print(w.showLabelPC(label))

## Run the program
parser = argparse.ArgumentParser(description='Run the program on a simulated RISC-V machine.')
parser.add_argument("program_name", nargs="?", type=str, default="", help='Program name. There should exist a corresponding .vmh file.')
parser.add_argument("test_number", nargs="?", type=int, default=0, help='Test number, from 1 to 5.')
parser.add_argument("--auto", action="store_true", help='AUTOGRADER use only')
args = parser.parse_args()

program_name = args.program_name
w.setAuto(args.auto)
w.loadHex(args.program_name + ".vmh")
w.loadArg(args.test_number)

if not interactive_inspect_mode():
    run()

