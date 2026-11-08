#include "table_2d_godot.h"
#include <godot_cpp/classes/project_settings.hpp>

using namespace godot;

std::string to_std(const String& s) { return std::string(s.utf8().get_data()); }

void Table2D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_from_json", "path"), &Table2D::load_from_json);
    ClassDB::bind_method(D_METHOD("save_to_json", "path"), &Table2D::save_to_json);
    
    ClassDB::bind_method(D_METHOD("get_value", "row", "col"), &Table2D::get_value);
    ClassDB::bind_method(D_METHOD("add_column", "col_name", "type", "default"), &Table2D::add_column);
    ClassDB::bind_method(D_METHOD("add_row", "row_name", "data"), &Table2D::add_row);

    ClassDB::bind_method(D_METHOD("remove_row", "row_name"), &Table2D::remove_row);
    ClassDB::bind_method(D_METHOD("remove_column", "col_name"), &Table2D::remove_column);
}

bool Table2D::load_from_json(const String& p_path) {
    String real_path = ProjectSettings::get_singleton()->globalize_path(p_path);
    return load_table_from_json(table_, to_std(real_path));
}

bool Table2D::save_to_json(const String& p_path) {
    String real_path = ProjectSettings::get_singleton()->globalize_path(p_path);
    return save_table_to_json(table_, to_std(real_path));
}

String Table2D::get_value(const String& p_row, const String& p_col) {
    auto val = table_.get_value(to_std(p_row), to_std(p_col));
    return val.has_value() ? String(val->c_str()) : String();
}

void Table2D::add_column(const String& p_col_name, const String& p_type, const String& p_default) {
    DataType dt = DataType::String;
    if (p_type == "int") dt = DataType::Int;
    else if (p_type == "bool") dt = DataType::Bool;
    else if (p_type == "float") dt = DataType::Float;
    
    table_.add_column_in_memory(to_std(p_col_name), dt, to_std(p_default));
}

void Table2D::add_row(const String& p_row_name, const Array& p_data) {
    std::vector<std::string> cpp_data;
    for (int i = 0; i < p_data.size(); ++i) {
        cpp_data.push_back(to_std(String(p_data[i])));
    }
    table_.add_row_in_memory(to_std(p_row_name), cpp_data);
}

void Table2D::remove_row(const String& p_row_name) {
    table_.remove_row_in_memory(to_std(p_row_name));
}

void Table2D::remove_column(const String& p_col_name) {
    table_.remove_column_in_memory(to_std(p_col_name));
}