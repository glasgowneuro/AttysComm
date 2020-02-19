cmake_minimum_required(VERSION 3.5)
set (CMAKE_CXX_STANDARD 11)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
	set(CMAKE_BUILD_TYPE "Release")
endif()

project(attyscomm VERSION 2.0.0 LANGUAGES CXX)
include(GNUInstallDirs)

set(LIBSRC
  AttysComm.cpp
  AttysScan.cpp
  attyscomm/base64.cpp)

set(PUBLICHEADERS
  AttysComm.h
  AttysScan.h)

set(PRIVATEHEADERS
  attyscomm/base64.h)

if(UNIX)
  
  add_library(attyscomm
    SHARED
    ${LIBSRC}
    )
  
  target_include_directories(attyscomm PRIVATE attyscomm)
  
  set_target_properties(attyscomm PROPERTIES
    SOVERSION 2
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
