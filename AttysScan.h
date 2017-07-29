class AttysScan;

#ifndef __ATTYS_SCAN_H
#define __ATTYS_SCAN_H


/**
 * AttysScan scans for Attys devices and then
 * creates an array of AttysComm intances which
 * are ready to be used
 *
 **/


#ifdef __linux__ 
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <bluetooth/rfcomm.h>
#include <sys/socket.h>
#include<sys/ioctl.h>
#include<stdio.h>
#include<fcntl.h>
#include<unistd.h>
#include<stdlib.h>
#include<termios.h>
#include <string>
#define SOCKET int
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#define Sleep(u) usleep((u*1000))
#ifdef QT_DEBUG
#define _RPT0(u,v) fprintf(stderr,v)
#define _RPT1(u,v,w) fprintf(stderr,v,w)
#else
#define _RPT0(u,v)
#define _RPT1(u,v,w)
#endif
#define OutputDebugStringW(s)
#elif _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <winsock2.h>
#include <ws2bth.h>
#include <BluetoothAPIs.h>
#else
#endif

#include <stdio.h>
#include <QThread>
#include <qsplashscreen.h>
#include "base64.h"
#include "AttysComm.h"

#pragma once

// global variable for convenience
extern AttysScan attysScan;


/**
 * Max number of Attys Devices
 **/
#define MAX_ATTYS_DEVS 4

class AttysScan {

public:
		~AttysScan();

/**
 * Scans for all attys devices and fills the global
 * variables above
 * returns 0 on success
 **/
	int scan(QSplashScreen* splash = NULL,
			int maxAttys = MAX_ATTYS_DEVS);

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

};


#endif
