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
            Log.d(TAG, "Found Attys. AttysComm set up.");
        }
    }

    public void stop() {
        if (attysComm != null) {
            attysComm.stop();
        }
    }

    @Override
    public final void onDestroy() {
        stop();
        attysComm = null;
        super.onDestroy();
    }

}