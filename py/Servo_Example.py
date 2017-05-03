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

AservoMin = 200  # Min pulse length out of 4096
AservoMax = 500  # Min pulse length out of 4096
BservoMin = 200  # Max pulse length out of 4096
BservoMax = 500  # Max pulse length out of 4096

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
while (True):
  # Change speed of continuous servo on channel O
  for x in range(10):
	for y in [0,1,2,3]:
		pwm.setPWM(y, 0, BservoMin)
		time.sleep(1)
		pwm.setPWM(y, 0, BservoMax)
		time.sleep(1)
  #pwm.setPWM(1, 0, BservoMin)
  #time.sleep(0.5)
  #pwm.setPWM(1, 0, BservoMax)



