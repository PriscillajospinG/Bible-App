cmake_minimum_required(VERSION 3.22.1)
project(llama_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(ENABLE_LLAMA "Enable llama.cpp native inference integration" ON)

add_library(
  llama_engine
  SHARED
  llama_bridge.cpp
)

find_library(log-lib log)
find_library(android-lib android)

set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native/llama_cpp")

if (ENABLE_LLAMA AND EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
  add_subdirectory("${LLAMA_CPP_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/llama_cpp_build")
  target_link_libraries(llama_engine PRIVATE llama)
  target_include_directories(llama_engine PRIVATE "${LLAMA_CPP_DIR}/include")
elseif(ENABLE_LLAMA)
  message(WARNING "llama.cpp not found, skipping native model build")
else()
  message(STATUS "ENABLE_LLAMA=OFF, building without llama.cpp")
endif()

target_link_libraries(
  llama_engine
  PRIVATE
  ${android-lib}
  ${log-lib}
)
