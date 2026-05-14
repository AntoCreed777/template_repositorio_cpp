cmake_minimum_required(VERSION 3.16)

project(MyProject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(${PROJECT_SOURCE_DIR}/cmake/CompilerWarnings.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/AddProjectLibrary.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/AddProjectExecutable.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/AddProjectTest.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/BuildTypeOptions.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/ConvenienceTargets.cmake)

add_library(project_warnings INTERFACE)
target_enable_strict_warnings(project_warnings)

add_library(project_options INTERFACE)
target_enable_build_type_options(project_options)

enable_testing()

add_subdirectory(src)
add_subdirectory(apps)
add_subdirectory(tests)
