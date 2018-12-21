# use OpenMP

if (WIN32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /openmp")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /openmp")
elseif (APPLE)
    # For the libomp installed by brew
    include_directories("/usr/local/opt/libomp/include")
    link_directories("/usr/local/opt/libomp/lib")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Xpreprocessor -fopenmp")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xpreprocessor -fopenmp")

    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -lomp")
    set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} -lomp")
elseif (UNIX)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fopenmp")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fopenmp")
else ()
endif ()