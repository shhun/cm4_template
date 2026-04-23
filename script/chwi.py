import subprocess

import chipwhisperer as cw
import time

scope = cw.scope()
target = cw.target(scope, cw.targets.SimpleSerial)
prog = cw.programmers.STM32FProgrammer

CODEDIR = "../"
HEXDIR = "../hex/"
FILE = "stm.hex"

time.sleep(0.05)
scope.default_setup()

def build(*args):
    subprocess.run(["make", "-C", CODEDIR, *args])

def program():
    path = HEXDIR + FILE
    cw.program_target(scope, prog, path)

def reset():
    scope.target_pwr = False
    time.sleep(1)
    scope.target_pwr = True 

def disconnect():
    scope.dis()
    target.dis()

def poll_target_until(endmsg, debug=False):
    read_data = ""
    while not(read_data.__contains__(endmsg)): # why not
        read_now = target.read(timeout=100)
        if (read_now.strip() != "") and debug: print(read_now)
        read_data += read_now
        
    return read_data
    
def program_and_poll_eof():
    program()
    return poll_target_until("EOF")
