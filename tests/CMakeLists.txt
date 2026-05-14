# =========================
# Catch2
# =========================
include(FetchContent)

FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.5.3
)

FetchContent_MakeAvailable(Catch2)

# =========================
# Tests
# =========================
add_project_test(greeting_test
    SOURCES greeting_test.cpp
)
