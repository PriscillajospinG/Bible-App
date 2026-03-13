cmake_minimum_required(VERSION 3.22.1)
project(llama_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
  llama_engine
  SHARED
  llama_engine.cpp
)

find_library(log-lib log)

# Optional llama.cpp integration:
# Place llama.cpp sources at android/app/src/main/cpp/llama.cpp
# (containing llama.h + CMakeLists.txt), then this auto-links against it.
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/CMakeLists.txt")
  add_subdirectory(llama.cpp)
  target_link_libraries(llama_engine PRIVATE llama)
  target_compile_definitions(llama_engine PRIVATE USE_LLAMA_CPP=1)
endif()

target_link_libraries(
  llama_engine
  ${log-lib}
)
