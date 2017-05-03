#!/usr/bin/python

import random
from Adafruit_PWM_Servo_Driver import PWM
import time

# ===========================================================================
# Example Code
# ===========================================================================

# Initialise the PWM device using the default address
pwm = PWM(0x40)
# Note if you'd like more debug output you can instead run:
#pwm = PWM(0x40, debug=True)

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

servoMin=100
servoMax=600
servoSpread=servoMax-servoMin

def move(m,x):
	print(x)
	assert(x>=-1)
	assert(x<=1)
	mul=1
	if m%2==1:
		mul=-1
	pwm.setPWM(m,0,int((servoMin+servoMax)/2+mul*x*servoSpread/2))


hips=[0,1,2,3]
legs=[4,5,6,7]

while True:
		
	print "Set Initial positions"

	for c in legs:
	  move(c,0.9)
	  time.sleep(0.2)
	for c in hips:
	  move(c,0.5)
	  time.sleep(0.2)

	
	sys.exit(1)
	for c in legs:
		for cc in legs:
		    move(cc,0.8)
		time.sleep(0.2)
		for v in [0.3,0.4,0.5,0.55,0.6,0.65,0.70,0.75,0.8,0.85,0.9]:
			move(c,v)
			time.sleep(0.5)


	print "Initial positions set - trying hips"

	from math import sqrt

	for v in range(5):
	  x=float(v)/10
	  for c in hips:
	    move(c,x)
	  time.sleep(0.2)
	  for c in hips:
	    move(c,-x)
	  time.sleep(0.2)


	for c in hips:
	  for cc in hips:
	     move(c,0)
	  for v in range(5):
	    x=float(v)/10
	    move(c,x)
	    time.sleep(0.2)
	    move(c,-x)
	    time.sleep(0.2)

	print "Initial positions set - trying legs"

	for c in hips:
	  move(c,0.5)
	  time.sleep(0.2)

	for c in legs:
		for cc in legs:
		    move(cc,0.8)
		time.sleep(0.2)
		for v in [0.6,0.70,75,0.8,0.85,0.9]:
			move(c,v)
			time.sleep(1)
	
