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

    // ===== 一条物品数据 =====
    struct WuPinShuJu {
        String  luJing;      // 路径
        float   zhanRong;    // 单件占容
        int32_t shuLiang;    // 数量
    };

    // ===== 背包容器 =====
    class MaterialContainer : public Node {
        GDCLASS(MaterialContainer, Node)   // 类名保持英文，你的 背包组件.gd 依赖它

    private:
        // --- 核心数据 ---
        std::vector<WuPinShuJu>                 shuJuBiao;     // 所有物品
        std::unordered_map<std::string, size_t> luJingSuoYin;  // 路径 → 下标
        mutable std::mutex shuJuSuo;     // 线程锁

        // --- 容量 ---
        float zuiDaRongLiang = 1000.0f;
        float dangQianRongLiang = 0.0f;

        // --- 同步缓存 ---
        // wuPinYouBianHua = true  → 数据变了，下次 get 要重建缓存
        // wuPinYouBianHua = false → 数据没变，直接返回缓存
        bool  wuPinYouBianHua = true;
        Array wuPinHuanCun;

    protected:
        static void _bind_methods();

        Array _构建物品数组();   // 调用前必须持锁
        void  _标记已变化();     // 调用前必须持锁

    public:
        MaterialContainer() = default;
        ~MaterialContainer() = default;

        // ===== 核心运算 =====
        bool    add_material(const String& luJing, float zhanRong, int32_t shuLiang);
        int32_t remove_material(const String& luJing, int32_t shuLiang);
        String  find_material(const Variant& shuXing) const;

        // ===== 你自己想加的辅助接口（可删可留） =====
        int32_t get_material_quantity(const String& luJing) const;
        void    clear_all();

        // ===== 容量 =====
        void  set_max_capacity(float zhi);
        float get_max_capacity() const;
        void  set_current_capacity(float zhi);   // ← 新增：同步系统要写入
        float get_current_capacity() const;

        // ===== 网络同步（属性名 items_sync 给 GDScript 用） =====
        Array get_items_sync();
        void  set_items_sync(const Array& shuJu);
    };

} // namespace godot
#endif