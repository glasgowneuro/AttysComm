package tech.glasgowneuro.attyscomm;

import android.app.Service;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.net.Uri;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import java.io.File;
import java.io.PrintWriter;
import java.util.Locale;

public class AttysService extends Service {

    private final String TAG = "AttysService";

    public void registerDataListener(AttysComm.DataListener dataListener) {
        this.dataListener = dataListener;
    }

    private AttysComm.DataListener dataListener = null;

    private final AttysComm.DataListener localDataListener = new AttysComm.DataListener() {
        @Override
        public void gotData(long samplenumber, float[] data) {
            if (null != dataListener) {
                dataListener.gotData(samplenumber,data);
            }
            dataRecorder.saveData(samplenumber,data);
        }
    };

    private AttysComm.MessageListener messageListener = null;

    public void registerMessageListener(AttysComm.MessageListener messageListener) {
        this.messageListener = messageListener;
    }

    private final AttysComm.MessageListener localMessageListener = new AttysComm.MessageListener() {
        @Override
        public void haveMessage(int msg) {
            if (null != messageListener) {
                messageListener.haveMessage(msg);
            }
        }
    };

    public class AttysBinder extends Binder {
        public final AttysService getService() {
            return AttysService.this;
        }
    }

    private final IBinder attysBinder = new AttysBinder();

    @Override
    public final IBinder onBind(Intent intent) {
        return attysBinder;
    }

    @Override
    public final int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    private BluetoothDevice btAttysDevice = null;
    public BluetoothDevice getBtAttysDevice() {
        return btAttysDevice;
    }

    private AttysComm attysComm = null;
    public AttysComm getAttysComm() {
        return attysComm;
    }

    synchronized public void createAttysComm() {
        if (null != attysComm) return;
        btAttysDevice = AttysComm.findAttysBtDevice();
        if (null == btAttysDevice) {
            attysComm = null;
            Log.d(TAG, "BT Attys Device is null!");
        } else {
            attysComm = new AttysComm(btAttysDevice);
            attysComm.registerDataListener(localDataListener);
            attysComm.registerMessageListener(localMessageListener);
            Log.d(TAG, "Found Attys. AttysComm set up.");
        }
    }

    @Override
    public final void onDestroy() {
        if (null != attysComm) {
            attysComm.stop();
        }
        attysComm = null;
        super.onDestroy();
    }

    public class DataRecorder {
        /////////////////////////////////////////////////////////////
        // saving data into a file

        public final static byte DATA_SEPARATOR_TAB = 0;
        public final static byte DATA_SEPARATOR_COMMA = 1;
        public final static byte DATA_SEPARATOR_SPACE = 2;

        private PrintWriter textdataFileStream = null;
        private File textdataFile = null;
        private byte data_separator = DataRecorder.DATA_SEPARATOR_TAB;
        private File file = null;
        private boolean gpioLogging = false;

        // starts the recording
        public void startRec(File _file) throws java.io.FileNotFoundException {
            file = _file;
            try {
                textdataFileStream = new PrintWriter(file);
                textdataFile = file;
            } catch (java.io.FileNotFoundException e) {
                textdataFileStream = null;
                textdataFile = null;
                Log.d(TAG,"Could not start recording:",e);
                throw e;
            }
        }

        // stops it
        public void stopRec() {
            if (textdataFileStream != null) {
                textdataFileStream.close();
                textdataFileStream = null;
                textdataFile = null;
                if (file != null) {
                    Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                    Uri contentUri = Uri.fromFile(file);
                    mediaScanIntent.setData(contentUri);
                    sendBroadcast(mediaScanIntent);
                }
            }
        }

        public File getFile() {
            return textdataFile;
        }

        public void setDataSeparator(byte s) {
            data_separator = s;
        }

        public void setGPIOlogging(boolean g) { gpioLogging = g; }

        public boolean isRecording() {
            return (textdataFileStream != null) && (textdataFile != null);
        }

        public void saveData(long sampleNo, float[] data) {
            if (textdataFile == null) return;
            if (textdataFileStream == null) return;

            char s = ' ';
            switch (data_separator) {
                case DATA_SEPARATOR_SPACE:
                    s = ' ';
                    break;
                case DATA_SEPARATOR_COMMA:
                    s = ',';
                    break;
                case DATA_SEPARATOR_TAB:
                    s = 9;
                    break;
            }
            String tmp = String.format(Locale.US, "%e%c", (double) sampleNo / (double) getAttysComm().getSamplingRateInHz(), s);
            for (float aData_unfilt : data) {
                tmp = tmp + String.format(Locale.US, "%e%c", aData_unfilt, s);
            }

            if (gpioLogging) {
                tmp = tmp + String.format(Locale.US, "%c%e", s, data[AttysComm.INDEX_GPIO0]);
                tmp = tmp + String.format(Locale.US, "%c%e", s, data[AttysComm.INDEX_GPIO1]);
            }

            if (textdataFileStream != null) {
                textdataFileStream.format(Locale.US, "%s\n", tmp);
            }
        }
    }

    private final DataRecorder dataRecorder = new DataRecorder();

    public DataRecorder getDataRecorder() {
        return dataRecorder;
    }

}