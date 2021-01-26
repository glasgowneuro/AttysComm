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

    private BluetoothDevice btAttysDevice = null;

    private AttysComm attysComm = null;

    AttysComm.DataListener dataListener = null;

    private final AttysComm.DataListener localDataListener = new AttysComm.DataListener() {
        @Override
        public void gotData(long samplenumber, float[] data) {
            if (null != dataListener) {
                dataListener.gotData(samplenumber,data);
                dataRecorder.saveData(samplenumber,data);
            }
        }
    };

    public AttysService() {
    }

    public AttysComm getAttysComm() {
        return attysComm;
    }

    public BluetoothDevice getBtAttysDevice() {
        return btAttysDevice;
    }

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
        //we have some options for service
        //start sticky means service will be explicity started and stopped

        Log.d(TAG, "onStartCommand");

        btAttysDevice = AttysComm.findAttysBtDevice();
        if (null == btAttysDevice) {
            attysComm = null;
        } else {
            attysComm = new AttysComm(btAttysDevice);
            attysComm.registerDataListener(localDataListener);
        }

        return START_STICKY;
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

        // are we recording?
        public boolean isRecording() {
            return (textdataFileStream != null);
        }

        public File getFile() {
            return textdataFile;
        }

        public void setDataSeparator(byte s) {
            data_separator = s;
        }

        public void setGPIOlogging(boolean g) { gpioLogging = g; }

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
            String tmp = String.format(Locale.US, "%f%c", (double) sampleNo / (double) getAttysComm().getSamplingRateInHz(), s);
            for (float aData_unfilt : data) {
                tmp = tmp + String.format(Locale.US, "%f%c", aData_unfilt, s);
            }

            if (gpioLogging) {
                tmp = tmp + String.format(Locale.US, "%c%f", s, data[AttysComm.INDEX_GPIO0]);
                tmp = tmp + String.format(Locale.US, "%c%f", s, data[AttysComm.INDEX_GPIO1]);
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