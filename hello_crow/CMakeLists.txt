cmake_minimum_required(VERSION 3.10)
project(hello_crow)

# Use modern C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Prefer pthreads for threading
set(THREADS_PREFER_PTHREAD_FLAG ON)

# Enable static linking for Boost
set(Boost_USE_STATIC_LIBS ON)

# Find Boost libraries
find_package(Boost 1.66 REQUIRED COMPONENTS system filesystem)

# Find Threads library
find_package(Threads REQUIRED)

# Find MongoDB C++ driver
find_package(mongocxx REQUIRED)
find_package(bsoncxx REQUIRED)

# Include directories
include_directories(${Boost_INCLUDE_DIRS})

# Create executable
add_executable(hello_crow main.cpp)

# Link against Boost, MongoDB, and threading libraries
target_link_libraries(hello_crow
    PRIVATE
        Boost::system
        Boost::filesystem
        Threads::Threads
        mongo::mongocxx_shared
        mongo::bsoncxx_shared
)
