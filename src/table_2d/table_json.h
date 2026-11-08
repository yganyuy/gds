#pragma once
#include "table_manager.h"
#include <string>

bool load_table_from_json(TableManager2D& table, const std::string& filepath, std::string* error_message = nullptr);
bool save_table_to_json(const TableManager2D& table, const std::string& filepath);
bool add_column_to_json(const std::string& filepath, const std::string& col_name, const std::string& type_str, const std::string& default_val);
bool add_row_to_json(const std::string& filepath, const std::string& row_name, const std::vector<std::string>& data);