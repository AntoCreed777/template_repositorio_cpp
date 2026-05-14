# Proyecto C++ con CMake — Guía rápida

Plantilla con headers en `include/`, librerías en `src/`, ejecutables en `apps/` y tests en `tests/`.

Rápido para empezar:

```bash
# Configurar + compilar (Debug)
cmake --preset debug
cmake --build --preset debug

# Ejecutar la app principal
./build/debug/apps/main_app

# Ejecutar tests (CTest)
ctest --test-dir build/debug --output-on-failure

# Alternativa: targets de conveniencia (desde build/debug con Makefiles)
make run_main
make run_tests
```

Detalles y reglas del proyecto (helpers de CMake, tests, targets de conveniencia) están en la documentación extensa: [docs/cmake_workflow.md](docs/cmake_workflow.md).

```bash
# Ejecutar el binario directamente (útil para debug rápido)
./build/debug/apps/main_app

# Ejecutar un test en particular directamente
./build/debug/tests/greeting_test

# Ejecutar todos los tests con CTest (muestra salida en fallos)
ctest --test-dir build/debug --output-on-failure

# Ejecutar valgrind si el target de convenience falla o no está disponible
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./build/debug/apps/main_app

# Forzar compilación antes de ejecutar si algo no está actualizado
cmake --build --preset debug --target greeting_test
```

Consejo: si usas otros generadores (por ejemplo `Ninja`) reemplaza `make ...` por el workflow de CMake (`cmake --build`).


## Documentación

- [cmake_workflow.md](docs/cmake_workflow.md) - Cómo funciona CMake
- [conventions.md](docs/conventions.md) - Convenciones de nombres
