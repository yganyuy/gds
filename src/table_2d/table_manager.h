#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include <optional>
#include <algorithm>
#include <cstdlib> // 引入 strtol

enum class DataType { String, Int, Bool, Float };

struct ColumnDef {
    std::string name;
    DataType type = DataType::String;
    std::string default_value;
};

class TableManager2D {
public:
    std::string table_name;
    std::vector<ColumnDef> headers;
    std::unordered_map<std::string, std::vector<std::string>> rows;
    std::vector<std::string> row_names; // Preserve JSON order

    // Index for fast lookup (O(1))
    std::unordered_map<std::string, size_t> col_name_to_index_;

    void build_index() {
        col_name_to_index_.clear();
        for (size_t i = 0; i < headers.size(); ++i) {
            col_name_to_index_[headers[i].name] = i;
        }
    }

    void add_column_in_memory(const std::string& name, DataType type, const std::string& default_val) {
        if (col_name_to_index_.find(name) != col_name_to_index_.end()) return;
        
        headers.push_back({name, type, default_val});
        build_index();

        for (auto& pair : rows) {
            pair.second.push_back(default_val);
        }
    }

    void add_row_in_memory(const std::string& row_name, const std::vector<std::string>& data = {}) {
        std::string actual_name = row_name;
        
        if (actual_name.empty()) {
            int max_id = 0;
            for (const auto& rn : row_names) {
                char* endptr;
                long id = std::strtol(rn.c_str(), &endptr, 10);
                if (*endptr == '\0' && id > max_id) max_id = static_cast<int>(id);
            }
            actual_name = std::to_string(max_id + 1);
        }

        std::vector<std::string> new_row;
        for (size_t i = 0; i < headers.size(); ++i) {
            if (i < data.size()) {
                new_row.push_back(data[i]);
            } else {
                new_row.push_back(headers[i].default_value);
            }
        }

        rows[actual_name] = new_row;
        row_names.push_back(actual_name);
    }

    std::optional<std::string> get_value(const std::string& row_name, const std::string& col_name) const {
        auto row_it = rows.find(row_name);
        if (row_it == rows.end()) return std::nullopt;

        auto col_it = col_name_to_index_.find(col_name);
        if (col_it == col_name_to_index_.end()) return std::nullopt;

        size_t col_idx = col_it->second;
        if (col_idx >= row_it->second.size()) return std::nullopt;

        return row_it->second[col_idx];
    }

    // 移除一行
    void remove_row_in_memory(const std::string& row_name) {
        auto it = rows.find(row_name);
        if (it == rows.end()) return;

        rows.erase(it);

        auto vec_it = std::find(row_names.begin(), row_names.end(), row_name);
        if (vec_it != row_names.end()) {
            row_names.erase(vec_it);
        }
    }

    // 移除一列
    void remove_column_in_memory(const std::string& col_name) {
        auto col_it = col_name_to_index_.find(col_name);
        if (col_it == col_name_to_index_.end()) return;

        size_t col_idx = col_it->second;

        headers.erase(headers.begin() + col_idx);

        for (auto& pair : rows) {
            if (col_idx < pair.second.size()) {
                pair.second.erase(pair.second.begin() + col_idx);
            }
        }

        build_index();
    }
};