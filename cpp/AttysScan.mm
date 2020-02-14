#include "AttysScan.h"

#import <Foundation/Foundation.h>

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

#include <thread>

// convenience class which can be used globally
AttysScan attysScan;

/**
 * Scans for Attys Devices
 * Fills up the variables
 * Returns zero on success
 **/
int AttysScan::scan(int maxAttysDevs) {
	attysName = new char*[maxAttysDevs];
	attysComm = new AttysComm*[maxAttysDevs];
	assert(attysComm != nullptr);
	for (int devNo = 0; devNo < maxAttysDevs; devNo++) {
		attysComm[devNo] = nullptr;
		attysName[devNo] = new char[256];
		attysName[devNo][0] = 0;
	}

	nAttysDevices = 0;

	fprintf(stderr,"Attempting to connect\n");

	NSArray *deviceArray = [IOBluetoothDevice pairedDevices];
	if ( ( deviceArray == nil ) || ( [deviceArray count] == 0 ) ) {
		throw "Error - no device has been paired.";
	}
	
	fprintf(stderr,"We have %lu paired device(s).\n",(unsigned long)deviceArray.count);

	// let's probe how many we have
	nAttysDevices = 0;
	for (int i = 0; (i < deviceArray.count) && (i < maxAttysDevs); i++) {
        IOBluetoothDevice *device = [deviceArray objectAtIndex:i];
        fprintf(stderr,"device name = %s\n",[device.name UTF8String]);
        char name[256];
        strcpy(name,[device.name UTF8String]);
        if (strstr(name, "GN-ATTYS") != 0) {
            fprintf(stderr, "! Found one. Connecting. ");
				// allocate a socket
            attysComm[nAttysDevices] = new AttysComm((__bridge void*)device);
            if (attysComm[nAttysDevices] == NULL) {
					break;
            }
            try {
                attysComm[nAttysDevices]->connect();
                strncpy(attysName[nAttysDevices], name, sizeof(name));
                nAttysDevices++;
                fprintf(stderr, " Connected.\n");
                break;
            }
            catch (const char *msg) {
                if (statusCallback) {
						statusCallback->message(SCAN_CONNECTERR, msg);
                }
                attysComm[nAttysDevices]->closeSocket();
                delete attysComm[nAttysDevices];
                attysComm[nAttysDevices] = NULL;
                fprintf(stderr, " Connection error.\n");
            }
			}
			else {
				fprintf(stderr, "\n");
			}
	}

	// get them both to sync
	for (int devNo = 0; devNo < nAttysDevices; devNo++) {
		attysComm[devNo]->resetRingbuffer();
	}

	return 0;
}


AttysScan::~AttysScan() {
	if (!attysComm) return;
	for (int devNo = 0; devNo < nAttysDevices; devNo++) {
		if (attysComm[devNo]) {
			delete attysComm[devNo];
			attysComm[devNo] = NULL;
		}
	}
	delete[] attysComm;
}
