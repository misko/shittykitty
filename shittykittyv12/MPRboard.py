import sys
import time
import MPR121 
import ADXL345
from DRV8825 import DRV8825
import RPi.GPIO as GPIO
from time import sleep
   

Motor1 = DRV8825(dir_pin=13, step_pin=19, enable_pin=12, mode_pins=(16, 17, 20))
Motor1.SetMicroStep('hardward','fullstep')

button_pin=26
GPIO.setup(button_pin, GPIO.IN,pull_up_down = GPIO.PUD_UP)

s=285*8
#d=0.00001*8
d=0.00001*8/2


class MPRboard:
    def __init__(self):
        self.caps = []
        for addy in [(0x5B,False,False),(0x5C,True,False),(0x5A,False,False),(0x5D,False,False)]:
            self.caps.append( {'sense':MPR121.MPR121(), 'flip_in_out':addy[1], 'flip_front_back':addy[2] } )
            if not self.caps[-1]['sense'].begin(addy[0]):
                print("Failed to start",addy[0])
                sys.exit(1)
        Motor1.Stop()
        self.state='open'
        self.state_change('close')


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

    def get_range(self):
        touched=self.get_sense()
        selected=[]


    def state_change(self,to_state):
        if to_state==self.state:
            return
        if to_state=='close':
            while GPIO.input(button_pin)==True:
                Motor1.TurnStep(Dir='forward', steps=20, stepdelay = d)
        if to_state=='open':
            Motor1.TurnStep(Dir='backward', steps=s, stepdelay = d)
        Motor1.Stop()
        self.state=to_state

accel = ADXL345.ADXL345()


state = 'open'
# Main loop to print a message every time a pin is touched.
b = MPRboard()
print('Press Ctrl-C to quit.')


last_touched = b.get_sense()
acc_y=0
while True:
    Motor1.Stop()
    #get which sensors are enabled
    current_touched = b.get_sense()
    if len(current_touched)>0:
        print(current_touched)
    last_touched = current_touched

    #check the angle of the device
    x, y, z = accel.read()
    #print(x,y,z,acc_y)
    if y>10:
        acc_y=min(acc_y+1,10)
    else:
        acc_y=max(0,acc_y-3)
    if acc_y>5:
        b.state_change('close')
    if acc_y==0:
        b.state_change('open')

    time.sleep(0.01)

