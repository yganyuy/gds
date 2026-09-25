#include "example.h"
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void Example::_bind_methods() {
	ClassDB::bind_method(D_METHOD("ping"), & Example::ping);
}

void Example::ping() {
	UtilityFunctions::print("hi gde");
}