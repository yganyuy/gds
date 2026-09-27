#include "material_container.h"

using namespace godot;

void MaterialContainer::_bind_methods() {
    // ============================================================
    // 绑定信号（信号名全部英文，避免中文乱码）
    // ============================================================
    // 信号：获取素材成功（参数：路径, 数量）
    ADD_SIGNAL(MethodInfo("item_added",
        PropertyInfo(Variant::STRING, "path"),
        PropertyInfo(Variant::INT, "quantity")));

    // 信号：丢弃素材成功（参数：路径, 数量）
    ADD_SIGNAL(MethodInfo("item_discarded",
        PropertyInfo(Variant::STRING, "path"),
        PropertyInfo(Variant::INT, "quantity")));

    // 信号：容量已更新（参数：当前容量, 最大容量）
    ADD_SIGNAL(MethodInfo("capacity_changed",
        PropertyInfo(Variant::FLOAT, "current"),
        PropertyInfo(Variant::FLOAT, "max")));

    // ============================================================
    // 绑定方法（方法名全部英文，避免 D_METHOD 中文乱码）
    // ============================================================
    // 获取某物：add_item(path, capacity, quantity)
    ClassDB::bind_method(D_METHOD("add_item", "path", "capacity", "quantity"),
        &MaterialContainer::add_item);

    // 丢弃某物：discard_item(path, quantity)
    ClassDB::bind_method(D_METHOD("discard_item", "path", "quantity"),
        &MaterialContainer::discard_item);

    // 查找某物：find_item(attribute) —— attribute 可传索引(int)或路径(String)
    ClassDB::bind_method(D_METHOD("find_item", "attribute"),
        &MaterialContainer::find_item);

    // ============================================================
    // 绑定属性（属性名全部英文）
    // ============================================================
    // 最大容量
    ClassDB::bind_method(D_METHOD("set_max_capacity", "capacity"),
        &MaterialContainer::set_max_capacity);
    ClassDB::bind_method(D_METHOD("get_max_capacity"),
        &MaterialContainer::get_max_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_capacity"),
        "set_max_capacity", "get_max_capacity");

    // 当前容量（只读）
    ClassDB::bind_method(D_METHOD("get_current_capacity"),
        &MaterialContainer::get_current_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_capacity"),
        "", "get_current_capacity");
}

MaterialContainer::MaterialContainer() {}
MaterialContainer::~MaterialContainer() {}

// ========== 属性实现 ==========

// 设置最大容量
void MaterialContainer::set_max_capacity(float p_capacity) {
    std::lock_guard<std::mutex> lock(data_mutex);
    max_capacity = p_capacity;
}

// 获取最大容量
float MaterialContainer::get_max_capacity() const { return max_capacity; }

// 获取当前已用容量
float MaterialContainer::get_current_capacity() const { return current_capacity; }

// ========== 核心逻辑：获取某物（增加素材） ==========
// 参数：
//   p_path     : 素材路径
//   p_capacity : 单个素材占用的容量
//   p_quantity : 获取的数量
void MaterialContainer::add_item(const String& p_path, float p_capacity, int32_t p_quantity) {
    // 1. 加锁（保证多线程安全）
    std::lock_guard<std::mutex> lock(data_mutex);

    // 把 Godot String 转成 std::string（UTF-8 字节），用于 unordered_map 查找
    std::string std_path = p_path.utf8().get_data();
    auto it = path_index_map.find(std_path);

    if (it == path_index_map.end()) {
        // 情况 A：素材不存在，新增一条记录
        MaterialData new_data{ p_path, p_capacity, p_quantity };
        data_array.push_back(new_data);
        path_index_map[std_path] = data_array.size() - 1;
    }
    else {
        // 情况 B：素材已存在，累加数量
        data_array[it->second].quantity += p_quantity;
    }

    // 更新当前容量
    current_capacity += p_capacity * p_quantity;

    // 2. 解锁（离开作用域自动解锁，这是 C++ 的 RAII 优势）

    // 3. 发射信号（call_deferred 会把调用排到主线程下一帧，线程安全）
    call_deferred("emit_signal", "item_added", p_path, p_quantity);
    call_deferred("emit_signal", "capacity_changed", current_capacity, max_capacity);
}

// ========== 核心逻辑：丢弃某物（减少素材） ==========
// 参数：
//   p_path     : 素材路径
//   p_quantity : 丢弃的数量
void MaterialContainer::discard_item(const String& p_path, int32_t p_quantity) {
    std::lock_guard<std::mutex> lock(data_mutex);

    std::string std_path = p_path.utf8().get_data();
    auto it = path_index_map.find(std_path);

    if (it != path_index_map.end()) {
        size_t index = it->second;
        MaterialData& data = data_array[index];

        // 实际丢弃数量不能超过现有数量
        int32_t actual_discard = std::min(p_quantity, data.quantity);
        // 计算应扣除的容量
        float deducted_capacity = data.capacity * actual_discard;

        data.quantity -= actual_discard;
        current_capacity -= deducted_capacity;

        // 如果数量归零，从数组和 map 中删除该记录
        if (data.quantity <= 0) {
            // 技巧：数组删除是 O(n)，如果对顺序没要求，
            // 把最后一个元素移过来填补空位，再 pop_back，复杂度 O(1)
            size_t last_index = data_array.size() - 1;
            if (index != last_index) {
                data_array[index] = data_array[last_index];
                // 同步更新被移动元素的 map 索引
                path_index_map[data_array[index].path.utf8().get_data()] = index;
            }
            data_array.pop_back();
            path_index_map.erase(std_path);
        }
    }

    call_deferred("emit_signal", "item_discarded", p_path, p_quantity);
    call_deferred("emit_signal", "capacity_changed", current_capacity, max_capacity);
}

// ========== 核心逻辑：查找某物 ==========
// 参数：
//   p_attribute : 可以是 int（数组索引）或 String（素材路径）
// 返回：
//   找到则返回素材路径，找不到返回空字符串
String MaterialContainer::find_item(const Variant& p_attribute) const {
    if (p_attribute.get_type() == Variant::INT) {
        // 情况 A：按索引查找
        int32_t index = p_attribute;
        if (index >= 0 && index < data_array.size()) {
            return data_array[index].path;
        }
    }
    else if (p_attribute.get_type() == Variant::STRING) {
        // 情况 B：按路径查找
        String path = p_attribute;
        std::string std_path = path.utf8().get_data();
        auto it = path_index_map.find(std_path);
        if (it != path_index_map.end()) {
            return data_array[it->second].path;
        }
    }
    return String();
}