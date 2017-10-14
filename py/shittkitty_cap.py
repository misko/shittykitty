#!/usr/bin/python

import random
from Adafruit_PWM_Servo_Driver import PWM
import time
from adxl345 import ADXL345
import Adafruit_MPR121.MPR121 as MPR121

# Initialise the PWM device using the default address
pwm = PWM(0x40)
# Note if you'd like more debug output you can instead run:
#pwm = PWM(0x40, debug=True)

AservoMin = 300+20  # Min pulse length out of 4096
AservoMax = 525-20  # Min pulse length out of 4096

def setServoPulse(channel, pulse):
  pulseLength = 1000000                   # 1,000,000 us per second
  pulseLength /= 60                       # 60 Hz
  print "%d us per period" % pulseLength
  pulseLength /= 4096                     # 12 bits of resolution
  print "%d us per bit" % pulseLength
  pulse *= 1000
  pulse /= pulseLength
  pwm.setPWM(channel, 0, pulse)

pwm.setPWMFreq(60)                        # Set frequency to 60 Hz

def usleep(x):
  time.sleep(x/1000.0)

state='?'
def motor(x):
  global state
  if x=='fastopen':
    pwm.setPWM(0,0,AservoMin)
    if state!='open':
      usleep(500)
      state='open'
  if x=='fastclose':
    if state!='close':
      pwm.setPWM(0,0,AservoMax)
      usleep(500)
      state='close'
  elif x=='open':
    pwm.setPWM(0,0,AservoMin)
    if state!='open':
      for a in range(AservoMax,AservoMin,-1):
        pwm.setPWM(0,0,a)
        usleep(10)
    else:
      pwm.setPWM(0,0,AservoMin)
      usleep(100)
    print "OPEN"
    usleep(500)
    state='open'
  elif x=='close':
    if state!='close':
      for a in range(AservoMin,AservoMax,1):
        pwm.setPWM(0,0,a)
        usleep(10)
    else:
      pwm.setPWM(0,0,AservoMax)
      usleep(100)
    usleep(500)
    state='close'
  pwm.setPWM(0,0,0)

adxl345 = ADXL345()
GAIN = 1

addresses=(0x5a,0x5b)
print('Adafruit MPR121 Capacitive Touch Sensor Test')
caps = []

# Create MPR121 instance.
for address in addresses:
    caps.append(MPR121.MPR121())
    ret = caps[-1].begin(address=address)
    if not ret:
        print('Error initializing MPR121.  Check your wiring!')
        sys.exit(1)
    #caps[-1].set_thresholds(7,3)

def get_touched():
    t=[False]*24
    idx=0
    for cap in caps:
        v=cap.touched()
        for i in xrange(12):
            pin_bit = 1 << i
            if v & pin_bit:
                if idx<12:
                    t[idx]=True
                else:
                    t[36-idx-1]=True
            idx+=1
    return t


def get_stat(d):
    total=sum(d)
    if total==0:
        return 0,0,-1
    lowest_touched=-1
    #try normal
    mn=-1
    mx=-1
    total=0
    for i in range(len(d)):
        if d[i]:
            if mn==-1:
                mn=i
            mx=i
    spread=mx-mn
    if mn>=0:
        lowest_touched=mn
    #lets try the other way
    mn=-1
    mx=-1
    for i in range(len(d)):
        ii=(i+len(d)/2)%len(d)
        if d[ii]:
            if mn==-1:
                mn=i
            mx=i
    if abs(mx-mn)<spread:
        spread=abs(mx-mn)
    return spread+1,sum(d),lowest_touched



poop=0
seat_up=0
delay=50
while (True):
  next_delay=delay
  #motor('open')
  #motor('close')
  axes = adxl345.getAxes(True)
  z=abs(axes['z'])
  if z<0.85 and seat_up<20:
    seat_up=min(seat_up+2,20)
    next_delay=0
    if seat_up>10:
      motor('fastopen')
      print "FAST OPEN SEAT"
  elif z>0.9 and seat_up>-10:
    seat_up=max(seat_up-1,-10)
    next_delay=0
    if seat_up<0:
      motor('fastclose')
      print "FAST CLOSE SEAT"
  #print "   z = %.3fG" % ( axes['z'] )
  # Check each pin's last and current state to see if it was pressed or released.
  if z>0.9 and next_delay>0:
    #filtered = [cap.filtered_data(i)<81 for i in range(12)]
    filtered = get_touched()
    spread,total,lowest = get_stat(filtered)
    spread_inner,total_inner,lowest_inner = get_stat([filtered[x*2+1] for x in xrange(12)])
    spread_outter,total_outter,lowest_outter = get_stat([filtered[x*2+0] for x in xrange(12)])
    spread_full,total_full,lowest_full = get_stat(filtered)
    print "SPREAD",spread_inner,lowest_inner,spread_outter,lowest_outter,spread_full
    #check the sensors
    inner_check=(spread_inner in (3,4) and total_inner in (2,3,4))
    outter_check=spread_outter<=3 # or ((spread_outter==2 and total==2) or (spread_outter==3 and total==3))i

    if inner_check and outter_check and spread_full<=8:
        if poop>=30 and state!='open':
            motor('open')
            next_delay=10
        elif poop==30:
            motor('fastopen')
            next_delay=3000
        poop=min(30,poop+3)
    else:
        if poop<0 and state!='close':
            motor('close')
        elif poop<0 and total>1:
            motor('close')
        poop=max(poop-1,-25)
        next_delay=10

  usleep(next_delay)


