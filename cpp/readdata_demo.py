import pyattyscomm
s = pyattyscomm.AttysScan()
s.debug = 1
s.scan()
c = s.getAttysComm(0)
c.start()
while True:
    while (not c.hasSampleAvilabale()):
        a = 1
    sample = c.getSampleFromBuffer()
    print(sample)
