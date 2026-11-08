#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <cstdint>

#include "item_table/item_table.h"

namespace godot {

	class ItemTableManagerGodot : public RefCounted {
		GDCLASS(ItemTableManagerGodot, RefCounted)

	private:
		ItemTableManager table_;
		String last_error_;

	protected:
		static void _bind_methods();

	public:
		bool load_from_json(const String& p_file_path);
		bool has_item(const String& p_name);
		int64_t get_price(const String& p_name);
		String get_item_path(const String& p_name);
		int64_t get_size();
		PackedStringArray get_all_names();
		void clear();
		String get_last_error();

		bool append_row_to_json(const String& p_file_path, const String& p_name, const String& p_path, int64_t p_price, const Dictionary& p_extra_columns);
		bool add_column_to_json(const String& p_file_path, const String& p_column_name, const String& p_default_value_json);
	};

} // namespace godot