class AttysScan;

#ifndef __ATTYS_SCAN_H
#define __ATTYS_SCAN_H


/**
 * AttysScan scans for Attys devices and then
 * creates an array of AttysComm intances which
 * are ready to be used
 *
 **/

#include "AttysComm.h"

#pragma once

// global variable for convenience
extern AttysScan attysScan;


/**
 * Max number of Attys Devices
 **/
#define MAX_ATTYS_DEVS 4


// callback which reports the status of the scanner
struct AttysScanListener {
	virtual ~AttysScanListener() {};
	virtual void message(const int, const char *) = 0;
};


class AttysScan {

public:
	~AttysScan();

/**
 * Scans for all attys devices and fills the global
 * variables above
 * returns 0 on success
 **/
	int scan(int maxAttys = MAX_ATTYS_DEVS);

	static const int SCAN_CONNECTED = 0;
	static const int SCAN_SEARCHING = 1;
	static const int SCAN_NODEV = 2;
	static const int SCAN_SOCKETERR = 3;
	static const int SCAN_CONNECTING = 4;
	static const int SCAN_CONNECTERR = 5;

	// Register a callback
	void registerCallback(AttysScanListener* f) {
		statusCallback = f;
	}

	// Unregister the callback
	void unregisterCallback() {
		statusCallback = NULL;
	}

	AttysScanListener* statusCallback = NULL;



/**
 * Actual number of Attys Devices
 **/
	int nAttysDevices = 0;

/**
 * file descriptor for bt devices
 **/
	SOCKET *dev = NULL;

/**
 * name of the Attys
 **/
	char** attysName = NULL;

/**
 * Pointer to AttysComm
 **/
	AttysComm** attysComm = NULL;

	AttysComm* getAttysComm(int i) {
		return attysComm[i];
	}

};


#endif
