import sys
import time
import MPR121 
import RPi.GPIO as GPIO
from time import sleep
import atexit

def exit_handler():
        print('exit handler')
        print('exit handler done')

atexit.register(exit_handler)

class MPRboard:
    def __init__(self):
        self.caps = []
        for addy in [(0x5B,False,False),(0x5C,True,False),(0x5A,False,False),(0x5D,False,False)]:
            self.caps.append( {'sense':MPR121.MPR121(), 'flip_in_out':addy[1], 'flip_front_back':addy[2] } )
            if not self.caps[-1]['sense'].begin(addy[0]):
                print("Failed to start",addy[0])
                sys.exit(1)

    def get_sense(self):
        res=[]
        for chip_n in range(4):
            out = self.caps[chip_n]['sense'].touched()
            for x in range(12):
                if (1<<x) &  out:
                    if self.caps[chip_n]['flip_in_out']:
                        if x%2==0:
                            x+=1
                        else:
                            x-=1
                    if self.caps[chip_n]['flip_front_back']:
                        x=11-x
                    res.append(x+chip_n*12)
        return res



# Main loop to print a message every time a pin is touched.
b = MPRboard()
print('Press Ctrl-C to quit.')




while True:
    d={}
    #get which sensors are enabled
    current_touched = b.get_sense()
    if len(current_touched)>0:
        print(current_touched)
    time.sleep(0.01)

