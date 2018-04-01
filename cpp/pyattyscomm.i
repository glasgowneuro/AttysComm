%module pyattyscomm
%{
	#define SWIG_FILE_WITH_INIT
	#include<stdio.h>
	#include "attyscomm/AttysThread.h"
	#include "attyscomm/base64.h"
	#include "AttysComm.h"
	#include "AttysScan.h"	
%}
%include "AttysComm.h"
%include "AttysScan.h"

