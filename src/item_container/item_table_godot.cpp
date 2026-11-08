#include "item_table_godot.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/variant/array.hpp>

#include <optional>
#include <string>
#include <vector>
#include <map>

using namespace godot;

namespace {
	std::string to_std_string(const String& p_text) {
		return std::string(p_text.utf8().get_data());
	}
}

void ItemTableManagerGodot::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_from_json", "file_path"), &ItemTableManagerGodot::load_from_json);
	ClassDB::bind_method(D_METHOD("has_item", "name"), &ItemTableManagerGodot::has_item);
	ClassDB::bind_method(D_METHOD("get_price", "name"), &ItemTableManagerGodot::get_price);
	ClassDB::bind_method(D_METHOD("get_item_path", "name"), &ItemTableManagerGodot::get_item_path);
	ClassDB::bind_method(D_METHOD("get_size"), &ItemTableManagerGodot::get_size);
	ClassDB::bind_method(D_METHOD("get_all_names"), &ItemTableManagerGodot::get_all_names);
	ClassDB::bind_method(D_METHOD("clear"), &ItemTableManagerGodot::clear);
	ClassDB::bind_method(D_METHOD("get_last_error"), &ItemTableManagerGodot::get_last_error);

	ClassDB::bind_method(D_METHOD("append_row_to_json", "file_path", "name", "path", "price", "extra_columns"), 
		&ItemTableManagerGodot::append_row_to_json, DEFVAL(Dictionary()));
	ClassDB::bind_method(D_METHOD("add_column_to_json", "file_path", "column_name", "default_value_json"), 
		&ItemTableManagerGodot::add_column_to_json);
}

bool ItemTableManagerGodot::load_from_json(const String& p_file_path) {
	last_error_ = String();
	Ref<FileAccess> file = FileAccess::open(p_file_path, FileAccess::READ);
	if (file.is_null()) {
		last_error_ = String("Failed to open file for reading: ") + p_file_path;
		return false;
	}
	const String text = file->get_as_text();
	file->close();

	std::string parse_error;
	std::vector<Item> parsed;
	if (!parse_items_json(to_std_string(text), parsed, &parse_error)) {
		last_error_ = String("JSON parse error: ") + String(parse_error.c_str());
		return false;
	}
	table_.clear();
	for (const Item& item : parsed) table_.add_item(item);
	return true;
}

bool ItemTableManagerGodot::has_item(const String& p_name) { return table_.contains(to_std_string(p_name)); }

int64_t ItemTableManagerGodot::get_price(const String& p_name) {
	const std::optional<Item> row = table_.get_item_by_name(to_std_string(p_name));
	return row.has_value() ? static_cast<int64_t>(row->price) : -1;
}

String ItemTableManagerGodot::get_item_path(const String& p_name) {
	const std::optional<Item> row = table_.get_item_by_name(to_std_string(p_name));
	return row.has_value() ? String(row->path.c_str()) : String();
}

int64_t ItemTableManagerGodot::get_size() { return static_cast<int64_t>(table_.get_size()); }

PackedStringArray ItemTableManagerGodot::get_all_names() {
	PackedStringArray names;
	for (size_t i = 0; i < table_.get_size(); ++i) {
		const std::optional<Item> row = table_.get_item_by_index(i);
		if (row.has_value()) names.append(String(row->name.c_str()));
	}
	return names;
}

void ItemTableManagerGodot::clear() { table_.clear(); last_error_ = String(); }
String ItemTableManagerGodot::get_last_error() { return last_error_; }

bool ItemTableManagerGodot::append_row_to_json(const String& p_file_path, const String& p_name, const String& p_path, int64_t p_price, const Dictionary& p_extra_columns) {
	last_error_ = String();
	String real_path = ProjectSettings::get_singleton()->globalize_path(p_file_path);
	
	std::map<std::string, std::string> cpp_extra;
	Array keys = p_extra_columns.keys();
	for (int i = 0; i < keys.size(); ++i) {
		String k = keys[i]; String v = p_extra_columns[k];
		cpp_extra[to_std_string(k)] = to_std_string(v);
	}

	bool success = ::append_row_to_json(to_std_string(real_path), to_std_string(p_name), to_std_string(p_path), static_cast<int>(p_price), cpp_extra);
	if (!success) {
		last_error_ = String("Failed to append row. Real path: ") + real_path;
	}
	return success;
}

bool ItemTableManagerGodot::add_column_to_json(const String& p_file_path, const String& p_column_name, const String& p_default_value_json) {
	last_error_ = String();
	String real_path = ProjectSettings::get_singleton()->globalize_path(p_file_path);

	bool success = ::add_column_to_json(to_std_string(real_path), to_std_string(p_column_name), to_std_string(p_default_value_json));
	if (!success) {
		last_error_ = String("Failed to add column. Real path: ") + real_path;
	}
	return success;
}