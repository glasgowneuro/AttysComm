#include "AttysComm.h"

#include <assert.h>

#include <chrono>
#include <thread>

#import <Foundation/Foundation.h>

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

void AttysComm::connect() {
    IOBluetoothDevice *device = (IOBluetoothDevice *)btAddr;
    IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
    IOBluetoothSDPServiceRecord     *sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
    if ( sppServiceRecord == nil ) {
        throw "Not an spp/rfcomm device.\n";
    }
    UInt8 rfcommChannelID;
    if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess ) {
        throw "Not an SPP/RFCOMM device.\n";
    }
}


void AttysComm::closeSocket() {
#ifdef __linux__ 
	shutdown(btsocket, SHUT_RDWR);
	close(btsocket);
#elif _WIN32
	shutdown(btsocket, SD_BOTH);
	closesocket(btsocket);
#else
#endif
}


void AttysComm::sendSyncCommand(const char *message, int waitForOK) {
	char cr[] = "\n";
	int ret = 0;
	// 10 attempts
	for (int k = 0; k < 10; k++) {
		fprintf(stderr,"Sending: %s", message);
		ret = send(btsocket, message, (int)strlen(message), 0);
		if (ret < 0) {
			if (attysCommMessage) {
				attysCommMessage->hasMessage(errno, "message transmit error");
			}
		}
		send(btsocket, cr, (int)strlen(cr), 0);
		if (!waitForOK) {
			return;
		}
		for (int i = 0; i < 100; i++) {
			char linebuffer[8192];
			std::this_thread::sleep_for(std::chrono::milliseconds(1));
			ret = recv(btsocket, linebuffer, 8191, 0);
			if (ret < 0) {
				if (attysCommMessage) {
					attysCommMessage->hasMessage(errno, "could receive OK");
				}
			}
			if ((ret > 2) && (ret < 5)) {
				linebuffer[ret] = 0;
				//fprintf(stderr,">>%s<<\n",linebuffer);
				linebuffer[ret] = 0;
				if (strstr(linebuffer, "OK")) {
					fprintf(stderr, " -- OK received\n");
					return;
				}
			}
		}
		fprintf(stderr, " -- no OK received!\n");
	}
}


void AttysComm::sendInit() {
	fprintf(stderr,"Sending Init\n");
	// flag to prevent the data receiver to mess it up!
	initialising = 1;
	strcpy(inbuffer, "");
	char rststr[] = "\n\n\n\n\r";
	send(btsocket, rststr, (int)strlen(rststr), 0);

	// everything platform independent
	sendInitCommandsToAttys();

	strcpy(inbuffer, "");
	initialising = 0;
	fprintf(stderr,"Init finished. Waiting for data.\n");
}


void AttysComm::run() {
	char recvbuffer[8192];

	sendInit();

	doRun = 1;

	if (attysCommMessage) {
		attysCommMessage->hasMessage(MESSAGE_RECEIVING_DATA, "Connected");
	}

	watchdogCounter = TIMEOUT_IN_SECS * getSamplingRateInHz();
	watchdog = new std::thread(AttysComm::watchdogThread, this);

	// Keep listening to the InputStream until an exception occurs
	while (doRun) {

		while (initialising && doRun) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
		}
		int ret = recv(btsocket, recvbuffer, sizeof(recvbuffer), 0);
		if (ret < 0) {
			if (attysCommMessage) {
				attysCommMessage->hasMessage(errno, "data reception error");
			}
		}
		if (ret > 0) {
			processRawAttysData(recvbuffer, ret);
		}
	}

	watchdog->join();
	delete watchdog;
	watchdog = NULL;
};
