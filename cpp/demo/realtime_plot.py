#!/usr/bin/python3

import sys
sys.path.append('./..')
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import pyattyscomm

# read from channel 7
channel = 7

s = pyattyscomm.AttysScan()
s.scan()
c = s.getAttysComm(0)
c.start()

# now let's plot the data
fig, ax = plt.subplots()
# that's our plotbuffer
plotbuffer = np.zeros(500)
# plots an empty line
line, = ax.plot(plotbuffer)
# axis
ax.set_ylim(-2, 2)


# receives the data from the generator below
def update(data):
    global plotbuffer
    plotbuffer=np.append(plotbuffer,data)
    # only keep the 500 newest ones and discard the old ones
    plotbuffer=plotbuffer[-500:]
    # set the new 500 points of channel 9
    line.set_ydata(plotbuffer)
    return line,

# this checks in an endless loop if there is data in the ringbuffer
# of there is data then emit it to the update funnction above
def data_gen():
    #endless loop which gets data
    while True:
        data = np.zeros(0)
        while (c.hasSampleAvilabale()):
            sample = c.getSampleFromBuffer()
            data = np.append(data,sample[channel])
        yield data

# start the animation
ani = animation.FuncAnimation(fig, update, data_gen, interval=100)

# show it
plt.show()

c.quit()

print("finished")