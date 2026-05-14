#include <catch2/catch_test_macros.hpp>

#include "core/greeting.hpp"

TEST_CASE("build_greeting retorna mensaje esperado", "[core][greeting]") {
    REQUIRE(core::build_greeting("Mundo") == "Hola, Mundo!");
}
