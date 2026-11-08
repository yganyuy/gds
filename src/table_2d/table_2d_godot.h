#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/array.hpp>
#include "table_manager.h" 
#include "table_json.h"    

namespace godot {
class Table2D : public RefCounted {
    GDCLASS(Table2D, RefCounted)
private:
    TableManager2D table_; 

protected:
    static void _bind_methods();

public:
    bool load_from_json(const String& p_path);
    bool save_to_json(const String& p_path);

    String get_value(const String& p_row, const String& p_col);
    
    void add_column(const String& p_col_name, const String& p_type, const String& p_default);
    void add_row(const String& p_row_name, const Array& p_data);

    void remove_row(const String& p_row_name);
    void remove_column(const String& p_col_name);
};
}