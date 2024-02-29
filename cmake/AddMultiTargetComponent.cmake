include(ExternalProject)

function(add_multi_target_component srcRelPrefix project toolchainTuple generator)
    set(projectToolchainTuple ${project}-${toolchainTuple})
    set(toolchainFile ${CMAKE_SOURCE_DIR}/cmake/${toolchainTuple}.cmake)
    set(outputDir ${CMAKE_BINARY_DIR}/${toolchainTuple}/${project})

    if(${generator} STREQUAL "Ninja")
        set(buildBin ninja)
    else()
        set(buildBin make)
    endif()

    ExternalProject_Add(${projectToolchainTuple}
        PREFIX ${outputDir}
        SOURCE_DIR ${CMAKE_SOURCE_DIR}/${srcRelPrefix}/${project}
        BINARY_DIR ${outputDir}
        CMAKE_GENERATOR ${generator}
        CMAKE_ARGS -DCMAKE_TOOLCHAIN_FILE=${toolchainFile} -DPARENT_DIR=${CMAKE_SOURCE_DIR} -B ${outputDir}
        BUILD_COMMAND ${buildBin}
        INSTALL_COMMAND ""
    )
endfunction()
