import sys
import time
import MPR121 
import ADXL345
from DRV8825 import DRV8825
import RPi.GPIO as GPIO
from time import sleep
   

import atexit

Motor1 = DRV8825(dir_pin=13, step_pin=19, enable_pin=12, mode_pins=(16, 17, 20))
Motor1.SetMicroStep('hardward','fullstep')

def exit_handler():
        print('exit handler')
        Motor1.Stop()
        print('exit handler done')

atexit.register(exit_handler)

motor_delay=0.00001*8/2

# Main loop to print a message every time a pin is touched.
print('Press Ctrl-C to quit.')
print("spin forward")
Motor1.TurnStep(Dir='forward', steps=20*100, stepdelay = motor_delay)
Motor1.Stop()
print('wait 5 seconds')
time.sleep(5)
print('spin backward')
Motor1.TurnStep(Dir='backward', steps=20*100, stepdelay = motor_delay)
Motor1.Stop()

