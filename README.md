# AttysCOMM

The JAVA API for the Attys: http://www.attys.tech

![alt tag](ecu_attys_daq_board.png)



In general the java class AttysComm is well documented.
Check out the class itself.
You find all the constants and function calls there.


## Usage


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


Enjoy!

http://www.attys.tech
