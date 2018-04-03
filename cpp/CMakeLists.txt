cmake_minimum_required(VERSION 3.5)
set (CMAKE_CXX_STANDARD 11)

project(attyscomm VERSION 1.0.0 LANGUAGES CXX)
include(GNUInstallDirs)

set(LIBSRC
  AttysComm.cpp
  AttysScan.cpp
  attyscomm/base64.cpp)

set(PUBLICHEADERS
  AttysComm.h
  AttysScan.h)

set(PRIVATEHEADERS
  attyscomm/base64.h
  attyscomm/AttysThread.h)

if(UNIX)
  
  add_library(attyscomm
    SHARED
    ${LIBSRC}
    )
  
  target_include_directories(attyscomm PRIVATE attyscomm)
  
  set_target_properties(attyscomm PROPERTIES
    SOVERSION 1
    VERSION ${PROJECT_VERSION}
    PUBLIC_HEADER "${PUBLICHEADERS}"
    PRIVATE_HEADER "${PRIVATEHEADERS}")
  
  install(TARGETS attyscomm
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    PRIVATE_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/attyscomm)
  
endif(UNIX)

  
add_library(attyscomm_static
  STATIC
  ${LIBSRC}
  )

if(WIN32)
  target_link_libraries(attyscomm_static ws2_32)
endif(WIN32)

target_include_directories(attyscomm_static PRIVATE attyscomm)

set_target_properties(attyscomm_static PROPERTIES
  VERSION ${PROJECT_VERSION}
  PUBLIC_HEADER "${PUBLICHEADERS}"
  PRIVATE_HEADER "${PRIVATEHEADERS}")

install(TARGETS attyscomm_static
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  PRIVATE_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/attyscomm)


FIND_PACKAGE(SWIG)
FIND_PACKAGE(PythonLibs)

if (${SWIG_FOUND} AND NOT WIN32)
	INCLUDE(${SWIG_USE_FILE})
	INCLUDE_DIRECTORIES(${PYTHON_INCLUDE_PATH})
	INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
	SET(CMAKE_SWIG_FLAGS "")
	SET_SOURCE_FILES_PROPERTIES(pyattyscomm.i PROPERTIES CPLUSPLUS ON)
	SET_SOURCE_FILES_PROPERTIES(pyattyscomm.i PROPERTIES SWIG_FLAGS "-includeall")
	SWIG_ADD_MODULE(pyattyscomm python pyattyscomm.i ${LIBSRC})
	list(APPEND EXTRA_PY_LIBS "bluetooth")
	SWIG_LINK_LIBRARIES(pyattyscomm ${PYTHON_LIBRARIES} ${EXTRA_PY_LIBS} attyscomm)
endif (${SWIG_FOUND} AND NOT WIN32)
