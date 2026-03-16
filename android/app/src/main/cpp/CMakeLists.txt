cmake_minimum_required(VERSION 3.22.1)
project(llama_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
  llama_engine
  SHARED
  llama_bridge.cpp
)

find_library(log-lib log)
find_library(android-lib android)

set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native/llama_cpp")

if (NOT EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "llama.cpp submodule missing at native/llama_cpp")
endif()

add_subdirectory("${LLAMA_CPP_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/llama_cpp_build")
target_link_libraries(llama_engine PRIVATE llama)
target_include_directories(llama_engine PRIVATE "${LLAMA_CPP_DIR}/include")

target_link_libraries(
  llama_engine
  PRIVATE
  llama
  ${android-lib}
  ${log-lib}
)
