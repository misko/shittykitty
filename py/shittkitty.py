#!/usr/bin/python

import random
from Adafruit_PWM_Servo_Driver import PWM
import time
import Adafruit_ADS1x15
from adxl345 import ADXL345

# Initialise the PWM device using the default address
pwm = PWM(0x40)
# Note if you'd like more debug output you can instead run:
#pwm = PWM(0x40, debug=True)

AservoMin = 300  # Min pulse length out of 4096
AservoMax = 525  # Min pulse length out of 4096

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
    if state!='open':
      pwm.setPWM(0,0,AservoMin)
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
adc = Adafruit_ADS1x15.ADS1115()

def read_adc():
    r={}
    r['a']=adc.read_adc(2, gain=GAIN)
    r['b']=adc.read_adc(0, gain=GAIN)
    r['c']=adc.read_adc(1, gain=GAIN)
    r['d']=adc.read_adc(3, gain=GAIN)
    return r

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

  if z>0.9 and next_delay>0:
    #check the sensors
    s=read_adc()
    s_a=s['a']>8000 and s['a']<18000
    s_b=s['b']>6000 and s['a']<18000
    s_c=s['c']>8000 and s['a']<18000
    s_d=s['d']>9000
    #if (s_a or s_c) and s_b and s_d:
    if (s_a or s_c) and s_d:
        if poop>=30 and state!='open':
            motor('open')
        poop=min(30,poop+1)
        next_delay=10
    else:
        if poop<0 and state!='close':
            motor('close')
        elif poop<0 and (s_a or s_b or s_c or s_d):
            motor('close')
        poop=max(poop-1,-10)
        next_delay=10
    print poop,s_a,s_b,s_c,s_d

  usleep(next_delay)


