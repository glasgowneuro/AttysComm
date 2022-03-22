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

    private final String TAG = AttysService.class.getSimpleName();

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
        Log.d(TAG,"Starting AttysService");
        return START_STICKY;
    }

    private final AttysComm attysComm = new AttysComm();

    final public AttysComm getAttysComm() {
        return attysComm;
    }

    final public void stopAttysComm() {
        attysComm.stop();
    }

    final public void startAttysComm() {
        attysComm.start();
    }

    @Override
    public final void onDestroy() {
        stopAttysComm();
        super.onDestroy();
    }

}