#include "AttysComm.h"

#include <assert.h>

#include <chrono>
#include <thread>

#import <Foundation/Foundation.h>

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>


@interface AsyncCommDelegate : NSObject <IOBluetoothRFCOMMChannelDelegate> {
    @public
    AttysComm* delegateCPP;
}
@end

@implementation AsyncCommDelegate {
}

-(void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel status:(IOReturn)error
{
    
    if ( error != kIOReturnSuccess ) {
        fprintf(stderr,"Error - could not open the RFCOMM channel. Error code = %08x.\n",error);
        delegateCPP->setConnected(0);
        return;
    }
    else{
        fprintf(stderr,"Connected. Yeah!\n");
        delegateCPP->setConnected(1);
    }
    
}

-(void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    NSString  *message = [[NSString alloc] initWithBytes:dataPointer length:dataLength encoding:NSUTF8StringEncoding];
    if (delegateCPP->isInitialising()) {
        if (delegateCPP->recBuffer) {
            delete delegateCPP->recBuffer;
        }
        delegateCPP->recBuffer = new char[message.length+2];
        strcpy(delegateCPP->recBuffer,[message UTF8String]);
    } else {
        delegateCPP->processRawAttysData([message UTF8String]);
    }
}


@end


void AttysComm::getReceivedData(char* buf, int maxlen) {
    while ((!isConnected) && (doRun)) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    if (recBuffer) {
        strncpy(buf,recBuffer,maxlen);
        delete recBuffer;
        recBuffer = NULL;
        fprintf(stderr,"Received:%s\n",buf);
    } else {
        strncpy(buf,"",maxlen);
    }
}


int AttysComm::sendBT(const char* dataToSend)
{
    fprintf(stderr,"Sending Message\n");
//    if (!rfcommchannel) return kIOReturnError;
//    while ((!isConnected) && (doRun)) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
//    }
    fprintf(stderr,"writesync\n");
    return [(__bridge IOBluetoothRFCOMMChannel*)rfcommchannel writeSync:(void*)dataToSend length:strlen(dataToSend)];
}


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
    if (!rfcommchannel) return;
    IOBluetoothRFCOMMChannel *chan = (__bridge IOBluetoothRFCOMMChannel*) rfcommchannel;
    [chan closeChannel];
    fprintf(stderr,"closing");
}


void AttysComm::sendSyncCommand(const char *msg, int waitForOK) {
	char cr[] = "\n";
	int ret = 0;
	// 10 attempts
    while (doRun) {
		fprintf(stderr,"Sending: %s", msg);
		ret = sendBT(msg);
		if (kIOReturnSuccess != ret) {
			if (attysCommMessage) {
				attysCommMessage->hasMessage(errno, "message transmit error");
			}
		}
		sendBT(cr);
		if (!waitForOK) {
			return;
		}
		for (int i = 0; i < 100; i++) {
			char linebuffer[8192];
			std::this_thread::sleep_for(std::chrono::milliseconds(1));
			getReceivedData(linebuffer, 8191);
            ret = strlen(linebuffer);
			if ((ret > 2) && (ret < 5)) {
				fprintf(stderr,">>%s<<\n",linebuffer);
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
	sendBT(rststr);

	// everything platform independent
	sendInitCommandsToAttys();

	strcpy(inbuffer, "");
	initialising = 0;
	fprintf(stderr,"Init finished. Waiting for data.\n");
}

void AttysComm::start() {
    if (mainThread) {
        return;
    }
    mainThread = new std::thread(AttysCommBase::execMainThread, this);
    
    doRun = 1;
    
    sendInit();

    if (attysCommMessage) {
        attysCommMessage->hasMessage(MESSAGE_RECEIVING_DATA, "Connected");
    }
}

void AttysComm::run() {
	watchdogCounter = TIMEOUT_IN_SECS * getSamplingRateInHz();
	// watchdog = new std::thread(AttysComm::watchdogThread, this);
    
    IOBluetoothDevice *device = (IOBluetoothDevice *)btAddr;
    IOBluetoothRFCOMMChannel *chan = (__bridge IOBluetoothRFCOMMChannel*) rfcommchannel;
    IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
    IOBluetoothSDPServiceRecord     *sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
    UInt8 rfcommChannelID;
    [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID];

    AsyncCommDelegate* asyncCommDelegate = [[AsyncCommDelegate alloc] init];
    asyncCommDelegate->delegateCPP = this;
    
    if ( [device openRFCOMMChannelAsync:&chan withChannelID:rfcommChannelID delegate:asyncCommDelegate] != kIOReturnSuccess ) {
        fprintf(stderr,"Fatal - could not open the rfcomm.\n");
        return;
    }
    
    rfcommchannel = (__bridge void*) chan;
    
    doRun = 1;

	while (doRun) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	}

    if (watchdog) {
        watchdog->join();
        delete watchdog;
        watchdog = NULL;
    }
};


unsigned char* AttysComm::getBluetoothBinaryAdress() {
    IOBluetoothDevice *device = (IOBluetoothDevice *)btAddr;
    return (unsigned char*)[device getAddress];
}


void AttysComm::getBluetoothAdressString(char* s) {
    IOBluetoothDevice *device = (IOBluetoothDevice *)btAddr;
    strcpy(s,[device.addressString UTF8String]);
}

