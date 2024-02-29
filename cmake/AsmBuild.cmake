function(asm_build inputFile)
    get_filename_component(tgt ${inputFile} NAME_WE)
    # Build binary - extract raw hex bin - convert hex bin to C header
    add_executable(${tgt} ${inputFile})
    add_custom_command(
        TARGET ${tgt} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary ${tgt} ${tgt}.hex && xxd -i ${tgt}.hex ${tgt}.inc
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endfunction()

function(asm_build_verilog inputFile)
    get_filename_component(tgt ${inputFile} NAME_WE)
    # Build binary - extract raw memfile (verilog)
    add_executable(${tgt} ${inputFile})
    add_custom_command(
        TARGET ${tgt} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O verilog --verilog-data-width=4 ${tgt} ${tgt}.mem &&
            ${Python_EXECUTABLE} ${PARENT_DIR}/scripts/byteswap_memfile.py ${tgt}.mem
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endfunction()

function(asm_build_riscv_tests inputFile)
    get_filename_component(tgt ${inputFile} NAME_WE)
    # Build binary - extract raw hex bin - convert hex bin to C header
    add_executable(${tgt} ${inputFile})
    target_compile_definitions(${tgt} PRIVATE TEST_FUNC_NAME=${tgt})
    target_compile_definitions(${tgt} PRIVATE TEST_FUNC_TXT="${tgt}")
    target_compile_definitions(${tgt} PRIVATE TEST_FUNC_RET=${tgt}_ret)
    add_custom_command(
        TARGET ${tgt} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary ${tgt} ${tgt}.hex && xxd -i ${tgt}.hex ${tgt}.inc
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endfunction()
