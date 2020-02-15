cmake_minimum_required(VERSION 3.5)
set (CMAKE_CXX_STANDARD 11)

add_executable (attystest attystest.cpp)
target_link_libraries(attystest attyscomm_static pthread "-framework CoreBluetooth" "-framework IOBluetooth" "-framework Foundation")
target_include_directories(attystest PRIVATE ..)
