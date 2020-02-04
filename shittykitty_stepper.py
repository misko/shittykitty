import sys
import time


import time
from DRV8825 import DRV8825

#GPIO.setmode(GPIO.BCM)
    
Motor1 = DRV8825(dir_pin=13, step_pin=19, enable_pin=12, mode_pins=(16, 17, 20))
Motor1.SetMicroStep('hardward','fullstep')
import RPi.GPIO as GPIO
button_pin=26
GPIO.setup(button_pin, GPIO.IN,pull_up_down = GPIO.PUD_UP)

if len(sys.argv)!=2:
    print(sys.argv[0],"open/close")
    sys.exit(1)
#kit.continuous_servo[1].throttle = -1
cmd=sys.argv[1].lower()

s=220*8
s=100
d=0.00001*8

from time import sleep

print("WTF",GPIO.input(button_pin))
#
#button = Button(4)
#button = Button(2)
#
while GPIO.input(button_pin)==True:
    #print("X")
    Motor1.TurnStep(Dir='forward', steps=10, stepdelay = d)
#sleep(1)
Motor1.Stop()

s=220*8
s=100
d=0.00001*8
if cmd in ('open',):
    print("open")
    Motor1.TurnStep(Dir='backward', steps=s, stepdelay = d)
elif cmd in ('close',):
    print("close")
    Motor1.TurnStep(Dir='forward', steps=s, stepdelay = d)
elif cmd in ('eject',):
    print("eject")
    Motor1.TurnStep(Dir='backward', steps=10, stepdelay = d)
elif cmd in ('insert',):
    print("insert")
    Motor1.TurnStep(Dir='forward', steps=10, stepdelay = d)
elif cmd in ('openc',):
    kit.continuous_servo[0].throttle = 1
    time.sleep(1.7)
    kit.continuous_servo[0].throttle = 0
elif cmd in ('closec',):
    kit.continuous_servo[0].throttle = -1
    time.sleep(1.7)
    kit.continuous_servo[0].throttle = 0
elif cmd in ('ejectc',):
    kit.continuous_servo[0].throttle = 1
    time.sleep(0.4)
    kit.continuous_servo[0].throttle = 0
elif cmd in ('insertc',):
    kit.continuous_servo[0].throttle = -1
    time.sleep(0.4)
    kit.continuous_servo[0].throttle = 0
else:
    print("unknown command",cmd)

Motor1.Stop()

