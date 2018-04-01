#include "AttysScan.h"

#include <assert.h>

// convenience class which can be used globally
AttysScan attysScan;

/**
 * Scans for Attys Devices
 * Fills up the variables
 * Returns zero on success
 **/
int AttysScan::scan(int maxAttysDevs) {
	dev = new SOCKET[maxAttysDevs];
	attysName = new char*[maxAttysDevs];
	attysComm = new AttysComm*[maxAttysDevs];
	assert(attysComm != nullptr);
	for (int devNo = 0; devNo < maxAttysDevs; devNo++) {
		dev[devNo] = 0;
		attysComm[devNo] = nullptr;
		attysName[devNo] = new char[256];
		attysName[devNo][0] = 0;
	}

	nAttysDevices = 0;

#ifdef __linux__

	inquiry_info *ii = NULL;
	int max_rsp, num_rsp;
	int dev_id, sock, len, flags;
	int i;
	char addr[19] = { 0 };
	char name[248] = { 0 };
	struct sockaddr_rc saddr;
	memset(&saddr,0,sizeof(struct sockaddr_rc));

	if (debug) {
		fprintf(stderr,"Scanning for Attys devices.\n");
	}
	if (statusCallback) {
		statusCallback->message(SCAN_SEARCHING,"Searching for\nAttys devices");
	}
	
	dev_id = hci_get_route(NULL);
	if (dev_id < 0) {
		if (debug) {
			fprintf(stderr,"No bluetooth devices paired or bluetooth off. Err code = %d\n",dev_id);
		}
		if (statusCallback) {
			statusCallback->message(SCAN_NODEV,"No bluetooth\ndevices available");
		}
		return dev_id;
	}
	sock = hci_open_dev( dev_id );
	if (sock < 0) {
		if (debug) {
			fprintf(stderr,"Socket open returned error code %d.\n",sock);
		}
		if (statusCallback) {
			statusCallback->message(SCAN_SOCKETERR,"Error opening socket");
		}
		return sock;
	}
	
	len  = 8;
	max_rsp = 255;
	flags = IREQ_CACHE_FLUSH;
	ii = new inquiry_info[max_rsp];
	for(int i = 0;i<max_rsp;i++) {
		memset(ii+i,0,sizeof(inquiry_info));
	}
    
	num_rsp = hci_inquiry(dev_id, len, max_rsp, NULL, &ii, flags);
	if( num_rsp < 0 ) {
		perror("hci_inquiry");
		return num_rsp;
	}
		
	// let's probe how many we have
	nAttysDevices = 0;
	for (i = 0; (i < num_rsp) && (i < maxAttysDevs); i++) {
		for(int j = 0;j<3;j++) {
			ba2str(&(ii+i)->bdaddr, addr);
			memset(name, 0, sizeof(name));
			if (hci_read_remote_name(sock, &(ii+i)->bdaddr, sizeof(name), 
						 name, 0) < 0)
				strcpy(name, "[unknown]");
			fprintf(stderr,"%s  %s", addr, name);
			if (strstr(name,"GN-ATTYS")!=0) {
				fprintf(stderr,"! Found one. Connecting. ");
				// allocate a socket
				int s = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);
				memset(&saddr,0,sizeof(struct sockaddr_rc));
				// set the connection parameters (who to connect to)
				saddr.rc_family = AF_BLUETOOTH;
				saddr.rc_channel = (uint8_t) 1;
				str2ba( addr, &saddr.rc_bdaddr );
				
				// connect to server
				int status = ::connect(s,
						       (struct sockaddr *)&saddr,
						       sizeof(saddr));
				
				if (status == 0) {
					attysComm[nAttysDevices] = new AttysComm(s);
					sprintf(attysName[nAttysDevices], "%d:%s", nAttysDevices, name);
					fprintf(stderr,"Success.\n");
					nAttysDevices++;
					break;
				} else {
					fprintf(stderr,"Connect failed. Error code = %d. ",status);
					if (status == -1) {
						fprintf(stderr,"Permission denied. Please pair the Attys with your bluetooth adapter.\n");
						statusCallback->message(SCAN_CONNECTERR,"Permission denied. Attys not paired with this computer.");
					} else {
						statusCallback->message(SCAN_CONNECTERR,"Connect failed");
					}
					::close(s);
					fprintf(stderr,"\n");
				}
			} else {
				fprintf(stderr,"\n");
			}
		}
	}

	delete[] ii;
	
	
#elif _WIN32

	WSADATA wsd;
	int r = WSAStartup(MAKEWORD(2, 2), &wsd);
	if (r != 0) {
		_RPT1(0, " WASStartup failed: %d\n",r);
		return r;
	}

	WSAQUERYSET wsaq;
	ZeroMemory(&wsaq, sizeof(wsaq));
	wsaq.dwSize = sizeof(wsaq);
	wsaq.dwNameSpace = NS_BTH;
	wsaq.lpcsaBuffer = NULL;
	HANDLE hLookup = nullptr;
	int iRet = WSALookupServiceBegin(&wsaq, LUP_CONTAINERS, &hLookup);
	if (0 != iRet) {
		if (WSAGetLastError() != WSASERVICE_NOT_FOUND) {
			_RPT0(0,"WSALookupServiceBegin failed\n");
			if (statusCallback) {
				statusCallback->message(SCAN_SOCKETERR,"Internal windows\nbluetooth driver problem:\nWSALookupServiceBegin failed\n");
			}
			return iRet;
		}
		else {
			_RPT0(0,"No bluetooth devices found\n");
			if (statusCallback) {
				statusCallback->message(SCAN_NODEV,"No bluetooth devices found.\nHave you paired the Attys?\nIs bluetooth switched on?");
			}
			return -1;
		}
	}

	CHAR buf[4096];
	LPWSAQUERYSET pwsaResults = (LPWSAQUERYSET)buf;
	ZeroMemory(pwsaResults, sizeof(WSAQUERYSET));
	pwsaResults->dwSize = sizeof(WSAQUERYSET);
	pwsaResults->dwNameSpace = NS_BTH;
	pwsaResults->lpBlob = NULL;

	DWORD dwSize = sizeof(buf);
	while ((WSALookupServiceNext(hLookup, LUP_RETURN_NAME | LUP_RETURN_ADDR, &dwSize, pwsaResults) == 0) &&
	       (nAttysDevices < maxAttysDevs ) ){
		LPWSTR name = pwsaResults->lpszServiceInstanceName;
		if (wcsstr(name,L"GN-ATTYS1") != 0) {
			_RPT0(0,"Found an Attys!\n");

			char tmp[256];
			sprintf(tmp, "Connecting to\nAttys #%d:\n%S", nAttysDevices,name);
			if (statusCallback) {
				statusCallback->message(SCAN_CONNECTING,tmp);
			}

			for (int i = 0; i < 5; i++) {

				// allocate a socket
				SOCKET s = ::socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);

				if (INVALID_SOCKET == s) {
					_RPT0(0,"=CRITICAL= | socket() call failed.\n");
					return -1;
				}

				PSOCKADDR_BTH btAddr = (SOCKADDR_BTH *)(pwsaResults->lpcsaBuffer->RemoteAddr.lpSockaddr);
				btAddr->addressFamily = AF_BTH;
				btAddr->serviceClassId = RFCOMM_PROTOCOL_UUID;
				btAddr->port = BT_PORT_ANY;

				int btAddrLen = pwsaResults->lpcsaBuffer->RemoteAddr.iSockaddrLength;

				// connect to server
				int status = ::connect(s, (struct sockaddr *)btAddr, btAddrLen);

				if (status == 0) {
					attysComm[nAttysDevices] = new AttysComm(s);
					assert(attysComm[nAttysDevices] != nullptr);
					sprintf(attysName[nAttysDevices], "#%d: %S", nAttysDevices, name);
					nAttysDevices++;
					break;
				}
				else {
					_RPT0(0,"Connect failed\n");
					statusCallback->message(SCAN_CONNECTERR,"Connect failed");
					shutdown(s, SD_BOTH);
					closesocket(s);
				}
			}
		} else {
			_RPT0(0,"\n");
		}
	}

	WSALookupServiceEnd(hLookup);


#else

#endif

	return 0;
}


AttysScan::~AttysScan() {
	for (int devNo = 0; devNo < nAttysDevices; devNo++) {
		attysComm[devNo]->quit();
	}
}