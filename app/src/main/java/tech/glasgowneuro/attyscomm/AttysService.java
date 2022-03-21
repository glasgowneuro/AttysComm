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
import java.util.Timer;
import java.util.TimerTask;

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

    private AttysComm attysComm = null;
    final public AttysComm getAttysComm() {
        return attysComm;
    }

    final synchronized public void createAttysComm() {
        if (null != attysComm) return;
        attysComm = new AttysComm();
    }

    final public void stopAttysComm() {
        if (null != attysComm) {
            attysComm.stop();
        }
    }

    final public void startAttysComm() {
        if (null != attysComm) {
            attysComm.start();
        }
    }

    @Override
    public final void onDestroy() {
        stopAttysComm();
        super.onDestroy();
    }

}