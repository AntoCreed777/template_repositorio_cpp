# Proyecto C++ con CMake

Template minimalista para proyectos C++ con CMake.

Soporta:
- Múltiples ejecutables en un mismo proyecto
- Compartir librerías internas entre ejecutables
- Debug (GDB/Valgrind) y Release (-O3) con presets

## Estructura

```text
.
├── CMakeLists.txt
├── CMakePresets.json
├── cmake/
├── include/
├── src/
├── apps/
└── docs/
```

## Uso rápido

**Debug:**
```bash
cmake --preset debug
cmake --build --preset debug
./build/debug/apps/main_app
```

**Release:**
```bash
cmake --preset release
cmake --build --preset release
./build/release/apps/main_app
```

## Agregar ejecutable

1. Crear archivo en `apps/`, ej: `apps/tool.cpp`
2. Agregar en `apps/CMakeLists.txt`:
```cmake
add_project_executable(tool SOURCES tool.cpp)
```

## Agregar librería

1. Crear header y source de la librería, por ejemplo:
   - `include/math/sum.hpp`
   - `src/math/sum.cpp`
2. Registrar la librería en `src/CMakeLists.txt`:
```cmake
add_project_library(math
	SOURCES math/sum.cpp
)
```
3. Enlazar la librería desde un ejecutable en `apps/CMakeLists.txt`:
```cmake
add_project_executable(main_app
	SOURCES main.cpp
	LIBRARIES math
)
```

Nota: `add_project_library(...)` expone automáticamente `include/` para que puedas incluir headers como `#include <math/sum.hpp>`.

## Agregar test (ejemplo)

1. Crear archivo de test en `tests/`, por ejemplo: `tests/greeting_test.cpp`
2. Registrar el test en `tests/CMakeLists.txt`:
```cmake
add_project_test(greeting_test
	SOURCES greeting_test.cpp
)
```
3. Compilar en Debug y ejecutar tests:
```bash
cmake --preset debug
cmake --build --preset debug
ctest --test-dir build/debug --output-on-failure
# Alternativa: ejecutar el binario de test directamente
./build/debug/tests/greeting_test
```

El framework usado es Catch2 (vía `FetchContent`) y cada test se registra en CTest mediante `add_project_test(...)`.

Ejemplo real incluido: `tests/greeting_test.cpp`.

## Documentación

- [cmake_workflow.md](docs/cmake_workflow.md) - Cómo funciona CMake
- [conventions.md](docs/conventions.md) - Convenciones de nombres
