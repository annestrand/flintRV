cmake_minimum_required(VERSION 3.12)

project(risa_handler_lib)

add_library(risa_handler SHARED ${CMAKE_CURRENT_SOURCE_DIR}/risa_handler.cc)
target_include_directories(risa_handler PUBLIC ${CMAKE_SOURCE_DIR}/sim)
set_target_properties(risa_handler PROPERTIES C_STANDARD 99)
if (WIN32 OR MINGW)
    set_target_properties(risa_handler
        PROPERTIES
            PREFIX ""
            SUFFIX ".dll"
    )
endif()