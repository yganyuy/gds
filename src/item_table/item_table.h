// item_table.h
#pragma once

#include <cstddef>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>
#include <map> // 新增

// 一行物品数据
struct Item {
    std::string name;   
    std::string path;   
    int price = 0;      
};

// 纯粹的二维表格管理器
class ItemTableManager {
public:
    void add_item(const Item& item);
    size_t get_size() const;
    std::optional<Item> get_item_by_index(size_t index) const;
    std::optional<Item> get_item_by_name(const std::string& name) const;
    std::vector<std::string> get_all_names() const;
    void remove_item(const std::string& name);
    bool contains(const std::string& name) const;
    void clear();

private:
    std::vector<Item> rows_;                                
    std::unordered_map<std::string, size_t> name_to_index_; 
};

// 数据加载层
bool parse_items_json(const std::string& json_text,
                      std::vector<Item>& out_items,
                      std::string* error_message = nullptr);

bool load_from_json(ItemTableManager& table,
                    const std::string& filepath,
                    std::string* error_message = nullptr);

// ============================================================================
// 数据修改层（新增）
// ============================================================================

// 向 JSON 文件追加一行。extra_columns 允许插入结构体尚未定义的额外列。
bool append_row_to_json(const std::string& filepath, 
                        const std::string& name, 
                        const std::string& path, 
                        int price,
                        const std::map<std::string, std::string>& extra_columns = {});

// 向 JSON 文件中所有行批量追加一列
bool add_column_to_json(const std::string& filepath, 
                        const std::string& column_name, 
                        const std::string& default_value_json);