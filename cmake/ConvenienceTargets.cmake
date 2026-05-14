add_custom_target(run_main
    DEPENDS main_app
    COMMAND $<TARGET_FILE:main_app>
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    USES_TERMINAL
)

add_custom_target(run_sandbox
    DEPENDS sandbox_app
    COMMAND $<TARGET_FILE:sandbox_app>
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    USES_TERMINAL
)

add_custom_target(run_greeting_test
    DEPENDS greeting_test
    COMMAND $<TARGET_FILE:greeting_test>
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    USES_TERMINAL
)

add_custom_target(run_tests
    DEPENDS greeting_test
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    USES_TERMINAL
)

find_program(VALGRIND_EXECUTABLE valgrind)
if(VALGRIND_EXECUTABLE)
    add_custom_target(valgrind_main
        DEPENDS main_app
        COMMAND ${VALGRIND_EXECUTABLE} --leak-check=full --show-leak-kinds=all --track-origins=yes $<TARGET_FILE:main_app>
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
        USES_TERMINAL
    )
endif()
