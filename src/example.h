#pragma once
#include <godot_cpp/classes/ref_counted.hpp>  

namespace godot {
	class Example : public RefCounted {
		GDCLASS(Example, RefCounted)

	protected:
		static void _bind_methods();

	public:
		void ping();
	};
}