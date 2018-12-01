# AttysCOMM

The C++, Python and JAVA API for the Attys: http://www.attys.tech

![alt tag](ecu_attys_daq_board.png)

## C++

The files are in the `cpp` subdirectory.

### Installation/compilation is with cmake under Linux

```
cmake .
make
sudo make install
```

This will generate: a dynamic library libattyscomm.so, a static
one called libattyscomm_static.a and a python module called
pyattyscomm which contains exactly the class members of AttysComm
and AttysScan.


### Installation under Windows:
Under windows only the static library is generated which
should be used for your code development.
```
cmake -G "Visual Studio 15 2017 Win64" .
```
and then start Visual C++ and compile it.

### Usage

A small demo program is in the `demo` directory which scans
for an Attys and then prints the incoming data to stdout.
Type `cmake .`, `make` and then `./attysdemo` to run it.

Here is a step by guide how to code it:

1. scan for Attys
```
int ret = attysScan.scan();
```

2. Check the number of Attys detected
```
attysScan.nAttysDevices
```

3. If devices have been detected they show up as an array.
`attysScan.attysComm[0,1,2,etc]` points to the AttysComm instances.

4. Set the parameters, for example:
```
attysScan.attysComm[0]->setAdc_samplingrate_index(AttysComm::ADC_RATE_250HZ);
```

5. Register a callback (optional)
```
attysCallback = new AttysCallback(this);
attysScan.attysComm[0]->registerCallback(attysCallback);
```
You need to overload the virtual function of the callback in your program.

6. Start data acquisition
```
attysScan.attysComm[0]->start();
```

7. Check if ringbuffer contains data and wait till true
```
attysScan.attysComm[n]->hasSampleAvilabale();
```

8. Get samples from buffer
```
float* values = attysScan.attysComm[n]->getSampleFromBuffer();
```

9. go back to 7)

10. Ending the program:
```
attysScan.attysComm[n]->quit();
```


## JAVA

In general the java class AttysComm is well documented.
Check out the class itself.
You find all the constants and function calls there.


### Usage


1. Create AttysComm:
```
BluetoothDevice bd = AttysComm.findAttysBtDevice();
attysComm = new AttysComm(bd);
```


2. Set options

In general there are constants defined for the differnet options,
for example: AttysComm.ADC_RATE_250HZ for the sampling rate:
```
attysComm.setAdc_samplingrate_index(AttysComm.ADC_RATE_250HZ);
```

3. (Optional) Register a message listener for error messages:
```
attysComm.registerMessageListener(messageListener);
```


4. Start the data acquisition
```
attysComm.start();
```

5. Read the data from the ringbuffer in a TimerTask:
```
    class UpdatePlotTask extends TimerTask {

        public synchronized void run() {

            if (attysComm != null) {

  	        n = attysComm.getNumSamplesAvilable();
		for(int i = 0;i<n;i++) {
                    sample = attysComm.getSampleFromBuffer();
		    PROCESS / PLOT / ETC SAMPLE
		}
	    }
        }
    }
```

6. (Optional) there is also an event listener whenever a sample has arrived:
```
    public interface DataListener {
        void gotData(long samplenumber, float[] data);
    }
```
7. to stop AttysComm just call `stop()`.
It's blocking and will only return after the Thread talking to the Attys has been terminated.



## Python (SWIG)

This libary is fast and multi threaded. It performs
the data acquisition in the background while python can then
do the postprocessing.

Pre-compiled packages for both Linux and Windows are available.

### Linux

#### Python package (pip):

Make sure you have the bluetooth development libraries:
```
sudo apt-get install libbluetooth-dev
```
and then install with:

```
pip3 install pyattyscomm
```

#### From source

You need to have swig-3.x installed. Then run in the `cpp` directory:

```
cmake .
make
make install
./setup.py install
```

and then you can load the module `pyattyscomm` system-wide!


### Windows

#### Python package (pip):

In the python console type:

```
pip install pyattyscomm
```

### From source

Install `swig` and re-run the C++ installation.
Make sure to select "Release" in Visual Studio as python
is usually not installed with its debug libraries.
After compilation you get:

- `Release\_pyattyscomm.exp`
- `Release\_pyattyscomm.pyd`
- `pyattyscomm.py`

Install them with:
```
python setup.py install
```

### How to use

The python API is identical to the C++ one.
All the definitions are in AttysComm.h and AttysScan.h.

Here is an example:

```
# load the module
import pyattyscomm

# Gets the AttysScan class which scans for Attys via bluetooth
s = pyattyscomm.AttysScan()

# Scan for Attys
s.scan()

# get the 1st Attys
c = s.getAttysComm(0)

# if an attys has been found c points to it. Otherwise it's None.

# Start data acquisition in the background
c.start()

# Now we just read data at our convenience in a loop or timer or thread

while (not c.hasSampleAvilabale()):
        # do something else or nothing
	a = a + 1
    # getting a sample
    sample = c.getSampleFromBuffer()

    # do something with the sample
    print(sample)
```

### Demo programs

There are demo programs which show you how to read/plot data with pyattyscomm:

```
readdata_demo.py
realtime_plot_demo.py
```


![alt tag](pyattyscomm.png)


Enjoy!

http://www.attys.tech
