function(add_project_test target_name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES LIBRARIES)
    cmake_parse_arguments(APP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT APP_SOURCES)
        message(FATAL_ERROR "add_project_test(${target_name}) requires SOURCES")
    endif()

    add_executable(${target_name} ${APP_SOURCES})

    target_link_libraries(${target_name} PRIVATE
        core
        project_warnings
        Catch2::Catch2WithMain
        ${APP_LIBRARIES}
    )

    target_include_directories(${target_name} PRIVATE
        ${PROJECT_SOURCE_DIR}/include
    )

    add_test(NAME ${target_name} COMMAND ${target_name})
endfunction()
