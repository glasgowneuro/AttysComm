#!/usr/bin/python3
import sys
sys.path.append('./..')
import pyattyscomm
s = pyattyscomm.AttysScan()
s.scan()
c = s.getAttysComm(0)
c.start()
while True:
    while (not c.hasSampleAvilabale()):
        a = 1
    sample = c.getSampleFromBuffer()
    print(sample)
