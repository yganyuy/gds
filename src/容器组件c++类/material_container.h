#ifndef MATERIAL_CONTAINER_H
#define MATERIAL_CONTAINER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <vector>
#include <unordered_map>
#include <string>
#include <mutex>

namespace godot {

    // 素材数据结构：对应一条素材记录
    // path     : 素材资源路径（如 res://icon.svg）
    // capacity : 单个素材占用的容量
    // quantity : 该素材的数量
    struct MaterialData {
        String path;
        float capacity;
        int32_t quantity;
    };

    class MaterialContainer : public Node {
        GDCLASS(MaterialContainer, Node)

    private:
        // 核心数据存储：所有素材记录
        std::vector<MaterialData> data_array;

        // 索引缓存：路径 -> 数组下标，把查找复杂度降到 O(1)
        std::unordered_map<std::string, size_t> path_index_map;

        // 线程安全锁，保护 data_array / path_index_map / current_capacity
        std::mutex data_mutex;

        // 容量数据
        float max_capacity = 1000.0f;    // 最大容量
        float current_capacity = 0.0f;   // 当前已用容量

    protected:
        static void _bind_methods();

    public:
        MaterialContainer();
        ~MaterialContainer();

        // ========== 核心接口（暴露给 GDScript） ==========
        // add_item    : 获取某物（增加素材）
        // discard_item: 丢弃某物（减少素材）
        // find_item   : 查找某物（按索引或路径）
        void add_item(const String& p_path, float p_capacity, int32_t p_quantity);
        void discard_item(const String& p_path, int32_t p_quantity);
        String find_item(const Variant& p_attribute) const;

        // ========== 属性 Get/Set ==========
        void set_max_capacity(float p_capacity);
        float get_max_capacity() const;
        float get_current_capacity() const;
    };

} // namespace godot

#endif