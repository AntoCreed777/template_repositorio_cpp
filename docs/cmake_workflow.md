# Cómo funciona CMake en esta estructura

## Índice

- [Visión general](#visi%C3%B3n-general)
- [Presets (CMakePresets.json)](#presets-cmakepresetsjson)
- [Flow típico de compilación](#flow-t%C3%ADpico-de-compilaci%C3%B3n)
- [Headers (`include/`)](#headers-include)
- [Tests](#tests)
- [Convenience targets](#convenience-targets)
- [Escalado: agregar librerías o ejecutables](#escalado-agregar-librer%C3%ADas-o-ejecutables)
- [Ventajas](#ventajas)

## Visión general

Esta estructura usa un patrón modular de CMake donde:
- **cmake/** contiene funciones reutilizables
- **include/** contiene headers públicos de las librerías (organizados por módulo)
- **src/** contiene librerías compartidas (sin `main`)
- **apps/** contiene ejecutables del proyecto
- **tests/** contiene tests integrados con CTest y Catch2

## Estructura de CMakeLists.txt

### Raíz (CMakeLists.txt)

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyProject LANGUAGES CXX)
```

Define versión mínima de CMake y el nombre del proyecto (cámbialo por tu nombre de proyecto).

```cmake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

- C++17 obligatorio, sin extensiones del compilador
- `compile_commands.json` se genera para herramientas como clangd

```cmake
include(${PROJECT_SOURCE_DIR}/cmake/CompilerWarnings.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/AddProjectExecutable.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/BuildTypeOptions.cmake)
```

Carga módulos CMake personalizados.

```cmake
add_library(project_warnings INTERFACE)
target_enable_strict_warnings(project_warnings)

add_library(project_options INTERFACE)
target_enable_build_type_options(project_options)
```

Define dos librerías de interfaz (no compiladas):
- `project_warnings`: flags `-Wall -Wextra -Wpedantic` (etc)
- `project_options`: optimizaciones según Debug/Release

```cmake
add_subdirectory(src)
add_subdirectory(apps)
```

Procesa las carpetas src y apps en ese orden.

## Headers (`include/`)

Este proyecto expone los headers públicos en la carpeta `include/`. Las reglas principales son:

- Coloca los headers públicos bajo `include/` manteniendo un prefijo por módulo, por ejemplo `include/core/greeting.hpp`.
- Los sources de `src/` deben incluir headers públicos como `#include <core/greeting.hpp>`.
- La función helper `add_project_library(...)` añade `target_include_directories(... PUBLIC ${PROJECT_SOURCE_DIR}/include)`, por lo que los ejecutables y tests que enlacen la librería pueden incluir los headers sin rutas relativas.
- Para headers privados del módulo, ponlos en `src/<module>/detail/` o en el mismo `src/` y no los exportes en `include/`.

Ejemplo de uso en código:

```cpp
#include <core/greeting.hpp>
```

Esto evita usar rutas relativas complejas en los includes y mantiene una API pública clara.

### src/CMakeLists.txt

Define librerías compartidas usando la función helper `add_project_library`:

```cmake
add_project_library(core
    SOURCES core/greeting.cpp
)
```

Esta función:
- Crea la librería
- Expone automáticamente `include/` (PUBLIC)
- Aplica warnings y opciones de compilación
- Propaga todo a ejecutables que la enlacen

**Nota**: Cada `.cpp` debe añadirse en `SOURCES`. Puedes crear múltiples librerías en este archivo (ej: `core`, `math`, `utils`).

Ejemplo con múltiples librerías:

```cmake
add_project_library(core
    SOURCES core/greeting.cpp
)

add_project_library(math
    SOURCES math/operations.cpp
)
```

### apps/CMakeLists.txt

Define ejecutables usando la función helper `add_project_executable`:

```cmake
add_project_executable(main_app
    SOURCES main.cpp
)
```

Esta función (definida en `cmake/AddProjectExecutable.cmake`):
1. Crea un ejecutable
2. Lo enlaza automáticamente contra la librería `core`
3. Añade warnings y opciones de compilación
4. Expone `include/` para headers compartidos

Si necesitas un ejecutable con librerías adicionales:

```cmake
add_project_executable(network_tool
    SOURCES net.cpp
    LIBRARIES pthread ssl
)
```

## Módulos CMake personalizados

### cmake/CompilerWarnings.cmake

Define la función `target_enable_strict_warnings`:

```cmake
function(target_enable_strict_warnings target_name)
    if(MSVC)
        target_compile_options(${target_name} INTERFACE /W4 /permissive-)
    else()
        target_compile_options(${target_name} INTERFACE
            -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wconversion
            -Wsign-conversion
            -Wfloat-equal
        )
    endif()
endfunction()
```

Abstrae los flags de warnings entre compiladores (MSVC vs GCC/Clang).

### cmake/BuildTypeOptions.cmake

Define la función `target_enable_build_type_options`:

```cmake
function(target_enable_build_type_options target_name)
    if(MSVC)
        target_compile_options(${target_name} INTERFACE
            $<$<CONFIG:Debug>:/Zi>
            $<$<CONFIG:Release>:/O2>
        )
    else()
        target_compile_options(${target_name} INTERFACE
            $<$<CONFIG:Debug>:-O0;-g3;-fno-omit-frame-pointer>
            $<$<CONFIG:Release>:-O3;-march=native;-mtune=native>
        )
    endif()
endfunction()
```

Usa **generator expressions** (`$<$<CONFIG:Debug>:...>`):
- Si configuración es Debug: `-O0 -g3 -fno-omit-frame-pointer`
- Si configuración es Release: `-O3 -march=native -mtune=native`

### cmake/AddProjectLibrary.cmake

Define la función `add_project_library`:

```cmake
function(add_project_library lib_name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES LIBRARIES)
    cmake_parse_arguments(LIB "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT LIB_SOURCES)
        message(FATAL_ERROR "add_project_library(${lib_name}) requires SOURCES")
    endif()

    add_library(${lib_name} ${LIB_SOURCES})

    target_include_directories(${lib_name}
        PUBLIC
            ${PROJECT_SOURCE_DIR}/include
    )

    target_link_libraries(${lib_name}
        PUBLIC
            project_warnings
            project_options
            ${LIB_LIBRARIES}
    )
endfunction()
```

Automatiza la creación de librerías:
- Crea librería con los `.cpp` listados
- Expone `include/` públicamente
- Aplica warnings y opciones de compilación
- Permite enlazar librerías externas con LIBRARIES

### cmake/AddProjectExecutable.cmake

Define la función `add_project_executable`:

```cmake
function(add_project_executable target_name)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SOURCES LIBRARIES)
    cmake_parse_arguments(APP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT APP_SOURCES)
        message(FATAL_ERROR "add_project_executable(${target_name}) requires SOURCES")
    endif()

    add_executable(${target_name} ${APP_SOURCES})

    target_link_libraries(${target_name} PRIVATE
        core
        project_warnings
        ${APP_LIBRARIES}
    )

    target_include_directories(${target_name} PRIVATE
        ${PROJECT_SOURCE_DIR}/include
    )
endfunction()
```

Simplifica la creación de ejecutables:
- Parsea argumentos SOURCES y LIBRARIES
- Enlaza automáticamente contra las librerías compartidas (`core` por defecto)
- Aplica warnings y opciones de compilación
- Expone headers en `include/`

## Presets (CMakePresets.json)

Define 2 perfiles de configuración + compilación:

### Debug preset

```json
{
  "name": "debug",
  "displayName": "Debug",
  "description": "Debug for GDB and Valgrind",
  "generator": "Unix Makefiles",
  "binaryDir": "${sourceDir}/build/debug",
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Debug"
  }
}
```

- Compilación: `cmake --preset debug && cmake --build --preset debug`
- Binarios en `build/debug/`
- Flags: `-O0 -g3 -fno-omit-frame-pointer`

### Release preset

```json
{
  "name": "release",
  "displayName": "Release",
  "description": "Release build with O3 and native tuning",
  "generator": "Unix Makefiles",
  "binaryDir": "${sourceDir}/build/release",
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Release"
  }
}
```

- Compilación: `cmake --preset release && cmake --build --preset release`
- Binarios en `build/release/`
- Flags: `-O3 -march=native -mtune=native`

## Flow típico de compilación

```bash
# Primera vez
cmake --preset debug
cmake --build --preset debug

# Cambios en .cpp/.hpp
cmake --build --preset debug

# Cambios en CMakeLists.txt
cmake --preset debug
cmake --build --preset debug

# Compilar Release
cmake --preset release
cmake --build --preset release

# Ejecutar
./build/debug/apps/main_app
./build/release/apps/main_app
```

## Tests

En este proyecto los tests se integran con CMake/CTest y usamos Catch2 como framework de aserciones. Componentes principales:

- `enable_testing()` — habilita el soporte de testing en el proyecto; añade la infraestructura que CTest usa para descubrir tests.
- `add_test(<name> COMMAND <cmd>)` — registra un test en CTest; CTest ejecutará `<cmd>` cuando corras `ctest`.
- `add_project_test(...)` — helper del repositorio (en `cmake/AddProjectTest.cmake`) que crea el ejecutable de test, lo enlaza contra `core` y Catch2, e invoca `add_test()` para registrarlo automáticamente.
- Catch2 — framework de tests (se obtiene con `FetchContent` desde `tests/CMakeLists.txt`) que proporciona `TEST_CASE` y `REQUIRE`.

Flujo práctico:

1. CMake genera y compila los ejecutables de test.
2. Cada ejecutable queda registrado en CTest vía `add_test`.
3. Ejecutas los tests con CTest o directamente ejecutando el binario.

Comandos útiles:

```bash
# Configurar y compilar (Debug preset)
cmake --preset debug
cmake --build --preset debug

# Ejecutar todos los tests con CTest (muestra salida al fallar)
ctest --test-dir build/debug --output-on-failure

# Ejecutar un test directamente
./build/debug/tests/greeting_test
```

Ejecutar/filtrar tests con CTest

```bash
# Ejecutar todos los tests (salida en fallos)
ctest --test-dir build/debug --output-on-failure

# Ejecutar tests cuyo nombre coincida con 'greeting'
ctest --test-dir build/debug -R greeting --output-on-failure

# Ejecutar tests en paralelo (ej: 4 jobs)
ctest --test-dir build/debug -j4 --output-on-failure

# Output verboso (útil para depurar)
ctest --test-dir build/debug -V
```

## Convenience targets

Los targets de conveniencia están definidos en `cmake/ConvenienceTargets.cmake` y expuestos como objetivos build para facilitar ejecutar binarios y tests sin escribir rutas.

Ejemplos disponibles:

- `run_main` — ejecuta `main_app`.
- `run_sandbox` — ejecuta `sandbox_app`.
- `run_greeting_test` — ejecuta el binario `greeting_test`.
- `run_tests` — ejecuta `ctest` en la carpeta de build (equivalente a `ctest --test-dir <dir>`).
- `valgrind_main` — ejecuta `main_app` bajo Valgrind (si `valgrind` está instalado).

Invocación:

```bash
# Con Makefiles (desde build/debug)
make run_tests

# Con CMake (desde raíz)
cmake --build --preset debug --target run_tests
```

Qué se evita con estos targets

- Escribir rutas largas a binarios (`build/debug/...`).
- Confundir carpetas de build (`debug` vs `release`).
- Olvidar flags repetitivos de Valgrind.

Comandos de respaldo si un target falla

```bash
# Ejecutar binario directamente
./build/debug/apps/main_app

# Ejecutar test directamente
./build/debug/tests/greeting_test

# Ejecutar tests con CTest
ctest --test-dir build/debug --output-on-failure

# Ejecutar valgrind manualmente
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./build/debug/apps/main_app
```

Consejo: si usas otro generador (por ejemplo `Ninja`) usa `cmake --build` en lugar de `make` para invocar los targets.


## Escalado: agregar librerías o ejecutables

### Agregar librería en src/

Edita `src/CMakeLists.txt` y usa `add_project_library`:

```cmake
add_project_library(math
    SOURCES math/operations.cpp
)
```

Luego enlazala en un ejecutable:

```cmake
# En apps/CMakeLists.txt
add_project_executable(calculator
    SOURCES calc.cpp
    LIBRARIES math
)
```

### Agregar ejecutable en apps/

1. Crear `apps/tool.cpp` con `main()`
2. Editar `apps/CMakeLists.txt`:

```cmake
add_project_executable(tool
    SOURCES tool.cpp
)
```

3. Compilar:

```bash
cmake --build --preset debug --target tool
./build/debug/apps/tool
```

## Ventajas de esta estructura

| Aspecto | Ventaja |
|--------|---------|
| **Modular** | Funciones CMake reutilizables en `cmake/` |
| **Escalable** | Agregar librerías/ejecutables sin duplicar config |
| **Limpio** | Separación clara src (librerías) vs apps (ejecutables) |
| **Debug-friendly** | Presets para GDB/Valgrind sin cambiar CMake |
| **Portable** | Funciona en GNU/Linux, macOS, Windows (con ajustes menores) |
| **Rápido** | Compilación incremental, paralela con `-j` |
