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

button_pin=26
GPIO.setup(button_pin, GPIO.IN,pull_up_down = GPIO.PUD_UP)

#d=0.00001*8
def exit_handler():
        print('exit handler')
        Motor1.Stop()
        print('exit handler done')

atexit.register(exit_handler)


class MPRboard:
    motor_steps=285*8
    motor_delay=0.00001*8/2
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
        self.state_change('open')

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

    def get_spread(self,touched,sensors_per_ring=24):
        touched = sorted(touched)
        l=len(touched)
        if l==0:
            return 0,0
        if l==1:
            return 1,1

        spreads = [ sensors_per_ring-((touched[(idx+1)%l]-touched[idx])%sensors_per_ring-1) for idx in range(l) ]
        return min(spreads),l

    def get_spreads(self,touched):
        inner_spread,inner_total = self.get_spread([ x/2 for x in touched if x%2==1 ] )
        outer_spread,outer_total = self.get_spread([ x/2 for x in touched if x%2==0 ] )
        total_spread,total = self.get_spread([ x/2 for x in touched ], 24)
        return {'inner_spread':inner_spread,'inner_total':inner_total,'outer_spread':outer_spread,'outer_total':outer_total, 'total_spread':total_spread, 'total':total}

    def state_change(self,to_state):
        if to_state==self.state:
            return
        if to_state=='close':
            while GPIO.input(button_pin)==True:
                Motor1.TurnStep(Dir='forward', steps=20, stepdelay = self.motor_delay)
        if to_state=='open':
            Motor1.TurnStep(Dir='backward', steps=self.motor_steps, stepdelay = self.motor_delay)
        Motor1.Stop()
        self.state=to_state

accel = ADXL345.ADXL345()


# Main loop to print a message every time a pin is touched.
b = MPRboard()
print('Press Ctrl-C to quit.')


acc_z=0
business_time=0

threshold_max=130
threshold_high=100
threshold_low=20
threshold_min=0

up_down_ratio=1.0 # how much faster to move the cup up or down, higher number means moves up faster

accel_ratio=2.0/3.0

hist=[]

def get_log_entry(d,business_time,current_touched):
    t=time.time()
    cols=['total_spread','inner_spread','outer_spread','inner_total','outer_total']
    return [t]+[ d[col] if col in d else -1 for col in cols ] + [str(current_touched).replace(',',' ')]


while True:
    d={}
    Motor1.Stop()
    #get which sensors are enabled
    current_touched = b.get_sense()
    if len(current_touched)>0:
        d=b.get_spreads(current_touched)
        #print(d,business_time)
        if d['total_spread']<=9 and d['inner_spread']<=9 and d['outer_spread']<=6 and d['inner_total']>=3 and d['outer_total']>=2:
            #looks good!
            business_time=min(threshold_max, business_time+up_down_ratio) 
        else:
            business_time=max(business_time-1.0/up_down_ratio,threshold_min)
    else:
        business_time=max(business_time-1.0/up_down_ratio,threshold_min)


    if business_time>0 or len(current_touched)>0:
        hist.append(get_log_entry(d,business_time,current_touched))
    elif len(hist)>0 and (time.time()-hist[-1][0])>10:
        print("writting hist")
        f = open("shittykittylog.csv", "a")
        f.write("\n".join([ ",".join(map(str,line)) for line in hist])+"\n")
        f.close()
        hist=[]

    if business_time>=threshold_high:
        b.state_change('close')
    elif business_time>0 and business_time<threshold_low:
        b.state_change('open')


    #check the angle of the device
    x, y, z = accel.read()
    
    if z>10:
        acc_z=min(acc_z+40*accel_ratio,threshold_max)
    else:
        acc_z=max(threshold_min,acc_z-40*(1.0/accel_ratio))

    if acc_z>threshold_high:
        b.state_change('close')
    elif acc_z>threshold_min and acc_z<threshold_low:
        b.state_change('open')

    time.sleep(0.01)

