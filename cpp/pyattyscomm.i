%module(directors="1") pyattyscomm
%feature("director") AttysScanListener;
%module pyattyscomm
%{
	#define SWIG_FILE_WITH_INIT
	#include <stdio.h>
	#include "attyscomm/AttysThread.h"
	#include "attyscomm/base64.h"
	#include "AttysComm.h"
	#include "AttysScan.h"
%}

%typemap(out) sample_p {
  int i;
  $result = PyList_New(8);
  for (i = 0; i < 8; i++) {
    PyObject *o = PyFloat_FromDouble((double) $1[i]);
    PyList_SetItem($result,i,o);
  }
}

%include "attyscomm/AttysThread.h"
%include "attyscomm/base64.h"
%include "AttysComm.h"
%include "AttysScan.h"
