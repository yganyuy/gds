#include "item_table.h"

#include <utility>

void ItemTableManager::add_item(const Item& item) {
    const auto found = name_to_index_.find(item.name);
    if (found != name_to_index_.end()) {
        // 名称已存在：覆盖该行内容，行号不变，避免重复加载数据时出现重复行。
        rows_[found->second] = item;
        return;
    }

    name_to_index_.emplace(item.name, rows_.size());
    rows_.push_back(item);
}

size_t ItemTableManager::get_size() const {
    return rows_.size();
}

std::optional<Item> ItemTableManager::get_item_by_index(size_t index) const {
    if (index >= rows_.size()) {
        return std::nullopt;
    }
    return rows_[index];
}

std::optional<Item> ItemTableManager::get_item_by_name(const std::string& name) const {
    const auto found = name_to_index_.find(name);
    if (found == name_to_index_.end()) {
        return std::nullopt;
    }
    return rows_[found->second];
}

std::vector<std::string> ItemTableManager::get_all_names() const {
    std::vector<std::string> names;
    names.reserve(rows_.size());
    for (const Item& item : rows_) {
        names.push_back(item.name);
    }
    return names;
}

bool ItemTableManager::contains(const std::string& name) const {
    return name_to_index_.find(name) != name_to_index_.end();
}

void ItemTableManager::remove_item(const std::string& name) {
    const auto found = name_to_index_.find(name);
    if (found == name_to_index_.end()) {
        return; // 不存在就什么都不做，保持接口幂等
    }

    const size_t index = found->second;
    rows_.erase(rows_.begin() + static_cast<std::ptrdiff_t>(index));

    // 索引失效的根因：vector 删除会把被删行之后的元素整体前移一位，
    // 而 map 里存的是「行号」这个数值，不是指针，所以它不会自动跟着变。
    // 这里选择 O(N) 重建索引，换取「行顺序保持不变」——因为这是给人看的二维表，
    // 行号本身有语义（“第二行”“索引 1”），打乱顺序会让行号失去意义。
    //
    // 备选方案（性能优先、且不关心行顺序时）—— swap-and-pop，删除 O(1)：
    //     if (index != rows_.size() - 1) {
    //         std::swap(rows_[index], rows_.back());
    //         name_to_index_[rows_[index].name] = index;  // 只修正被换过来的那一行
    //     }
    //     rows_.pop_back();
    // 代价是最后一行的内容会被挪到被删位置，表格行序发生变化。
    name_to_index_.clear();
    name_to_index_.reserve(rows_.size());
    for (size_t i = 0; i < rows_.size(); ++i) {
        name_to_index_.emplace(rows_[i].name, i);
    }
}

void ItemTableManager::clear() {
    rows_.clear();
    name_to_index_.clear();
}
