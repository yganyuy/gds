#include "material_container.h"

using namespace godot;

void MaterialContainer::_bind_methods() {
    // 绑定信号 (英文名)
    ADD_SIGNAL(MethodInfo("material_added", PropertyInfo(Variant::STRING, "path"), PropertyInfo(Variant::INT, "quantity")));     // 对应：获取素材成功
    ADD_SIGNAL(MethodInfo("material_removed", PropertyInfo(Variant::STRING, "path"), PropertyInfo(Variant::INT, "quantity")));   // 对应：丢弃素材成功
    ADD_SIGNAL(MethodInfo("capacity_updated", PropertyInfo(Variant::FLOAT, "current"), PropertyInfo(Variant::FLOAT, "max")));    // 对应：容量已更新

    // 绑定方法
    ClassDB::bind_method(D_METHOD("add_material", "path", "capacity", "quantity"), &MaterialContainer::add_material);
    ClassDB::bind_method(D_METHOD("remove_material", "path", "quantity"), &MaterialContainer::remove_material);
    ClassDB::bind_method(D_METHOD("find_material", "attribute"), &MaterialContainer::find_material);

    // 绑定属性
    ClassDB::bind_method(D_METHOD("set_max_capacity", "capacity"), &MaterialContainer::set_max_capacity);
    ClassDB::bind_method(D_METHOD("get_max_capacity"), &MaterialContainer::get_max_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_capacity"), "set_max_capacity", "get_max_capacity");

    ClassDB::bind_method(D_METHOD("get_current_capacity"), &MaterialContainer::get_current_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_capacity"), "", "get_current_capacity");
}

MaterialContainer::MaterialContainer() {}
MaterialContainer::~MaterialContainer() {}

void MaterialContainer::set_max_capacity(float p_capacity) {
    std::lock_guard<std::mutex> lock(data_mutex);
    max_capacity = p_capacity;
}

float MaterialContainer::get_max_capacity() const { return max_capacity; }
float MaterialContainer::get_current_capacity() const { return current_capacity; }

// ========== 核心逻辑：获取某物 (add_material) ==========
void MaterialContainer::add_material(const String &p_path, float p_capacity, int32_t p_quantity) {
    // 1. 加锁 (RAII机制，离开作用域自动解锁)
    std::lock_guard<std::mutex> lock(data_mutex);
    
    std::string std_path = p_path.utf8().get_data();
    auto it = path_to_index.find(std_path);
    
    if (it == path_to_index.end()) {
        // 容器中原本没有该素材，新增
        MaterialData new_data{p_path, p_capacity, p_quantity};
        data_array.push_back(new_data);
        path_to_index[std_path] = data_array.size() - 1;
    } else {
        // 已有该素材，累加数量
        data_array[it->second].quantity += p_quantity;
    }
    
    current_capacity += p_capacity * p_quantity;
    
    // 2. 解锁（离开作用域自动完成）
    
    // 3. 发射信号 (由Godot底层自动排队到主线程执行，供主线程组件监听)
    call_deferred("emit_signal", "material_added", p_path, p_quantity);
    call_deferred("emit_signal", "capacity_updated", current_capacity, max_capacity);
}

// ========== 核心逻辑：丢弃某物 (remove_material) ==========
void MaterialContainer::remove_material(const String &p_path, int32_t p_quantity) {
    std::lock_guard<std::mutex> lock(data_mutex);
    
    std::string std_path = p_path.utf8().get_data();
    auto it = path_to_index.find(std_path);
    
    if (it != path_to_index.end()) {
        size_t index = it->second;
        MaterialData &data = data_array[index];
        
        int32_t actual_discard = std::min(p_quantity, data.quantity);
        float deducted_capacity = data.capacity * actual_discard;
        
        data.quantity -= actual_discard;
        current_capacity -= deducted_capacity;
        
        // 如果数量归零，彻底删除数据
        if (data.quantity <= 0) {
            // 性能优化：由于数组中间删除是 O(n)，这里采用“交换并弹出”策略
            size_t last_index = data_array.size() - 1;
            if (index != last_index) {
                // 把最后一个元素移到当前位置
                data_array[index] = data_array[last_index];
                // 更新被移动元素的索引记录
                path_to_index[data_array[index].path.utf8().get_data()] = index;
            }
            data_array.pop_back();
            path_to_index.erase(std_path);
        }
    }
    
    call_deferred("emit_signal", "material_removed", p_path, p_quantity);
    call_deferred("emit_signal", "capacity_updated", current_capacity, max_capacity);
}

// ========== 核心逻辑：查找某物 (find_material) ==========
String MaterialContainer::find_material(const Variant &p_attribute) const {
    // 传入索引（整数）
    if (p_attribute.get_type() == Variant::INT) {
        int32_t index = p_attribute;
        if (index >= 0 && index < data_array.size()) {
            return data_array[index].path;
        }
    } 
    // 传入路径（文本）
    else if (p_attribute.get_type() == Variant::STRING) {
        String path = p_attribute;
        std::string std_path = path.utf8().get_data();
        auto it = path_to_index.find(std_path);
        if (it != path_to_index.end()) {
            return data_array[it->second].path;
        }
    }
    return String(""); // 未找到返回空字符串
}