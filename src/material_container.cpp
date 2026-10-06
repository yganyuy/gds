#include "material_container.h"
using namespace godot;

void MaterialContainer::_bind_methods() {
    // ---- 信号 ----
    ADD_SIGNAL(MethodInfo("material_added",
        PropertyInfo(Variant::STRING, "path"), PropertyInfo(Variant::INT, "quantity")));
    ADD_SIGNAL(MethodInfo("material_removed",
        PropertyInfo(Variant::STRING, "path"), PropertyInfo(Variant::INT, "quantity")));
    ADD_SIGNAL(MethodInfo("capacity_updated",
        PropertyInfo(Variant::FLOAT, "current"), PropertyInfo(Variant::FLOAT, "max")));
    ADD_SIGNAL(MethodInfo("backpack_full",
        PropertyInfo(Variant::FLOAT, "current"), PropertyInfo(Variant::FLOAT, "max")));

    // ---- 方法 ----
    ClassDB::bind_method(D_METHOD("add_material", "path", "capacity", "quantity"),
        &MaterialContainer::add_material);
    ClassDB::bind_method(D_METHOD("remove_material", "path", "quantity"),
        &MaterialContainer::remove_material);
    ClassDB::bind_method(D_METHOD("find_material", "attribute"),
        &MaterialContainer::find_material);
    ClassDB::bind_method(D_METHOD("get_material_quantity", "path"),
        &MaterialContainer::get_material_quantity);
    ClassDB::bind_method(D_METHOD("clear_all"),
        &MaterialContainer::clear_all);

    // ---- 容量属性 ----
    ClassDB::bind_method(D_METHOD("set_max_capacity", "capacity"),
        &MaterialContainer::set_max_capacity);
    ClassDB::bind_method(D_METHOD("get_max_capacity"),
        &MaterialContainer::get_max_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_capacity"),
        "set_max_capacity", "get_max_capacity");

    ClassDB::bind_method(D_METHOD("set_current_capacity", "capacity"),
        &MaterialContainer::set_current_capacity);
    ClassDB::bind_method(D_METHOD("get_current_capacity"),
        &MaterialContainer::get_current_capacity);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "current_capacity"),
        "set_current_capacity", "get_current_capacity");

    // ---- 同步属性 items_sync ----
    ClassDB::bind_method(D_METHOD("get_items_sync"),
        &MaterialContainer::get_items_sync);
    ClassDB::bind_method(D_METHOD("set_items_sync", "items"),
        &MaterialContainer::set_items_sync);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "items_sync",
        PROPERTY_HINT_ARRAY_TYPE, "Dictionary"),
        "set_items_sync", "get_items_sync");
}

// ========== 内部工具 ==========
Array MaterialContainer::_构建物品数组() {
    Array jieGuo;
    for (size_t i = 0; i < shuJuBiao.size(); i++) {
        Dictionary yiTiao;
        yiTiao["path"] = shuJuBiao[i].luJing;
        yiTiao["capacity"] = shuJuBiao[i].zhanRong;
        yiTiao["quantity"] = shuJuBiao[i].shuLiang;
        jieGuo.append(yiTiao);
    }
    return jieGuo;
}
void MaterialContainer::_标记已变化() { wuPinYouBianHua = true; }

// ========== 增加 ==========
bool MaterialContainer::add_material(const String& luJing, float zhanRong, int32_t shuLiang) {
    if (shuLiang <= 0 || zhanRong <= 0.0f) return false;   // ← 顺便修了 < 0.0f

    std::lock_guard<std::mutex> lock(shuJuSuo);

    std::string jian = luJing.utf8().get_data();
    auto it = luJingSuoYin.find(jian);

    // ★ 关键：先决定"这次该用什么 zhanRong"
    //   已有物品 → 以已存的为准，不信传入值
    //   新物品   → 用传入的
    float shiJiZhanRong = (it != luJingSuoYin.end())
        ? shuJuBiao[it->second].zhanRong
        : zhanRong;
    float zheCiZhanRong = shiJiZhanRong * shuLiang;

    // ★ 只有这一次容量检查
    if (dangQianRongLiang + zheCiZhanRong > zuiDaRongLiang) {
        call_deferred("emit_signal", "backpack_full", dangQianRongLiang, zuiDaRongLiang);
        return false;
    }

    // 插入或累加
    if (it == luJingSuoYin.end()) {
        WuPinShuJu xin;
        xin.luJing = luJing;
        xin.zhanRong = shiJiZhanRong;   // 新物品用算好的
        xin.shuLiang = shuLiang;
        shuJuBiao.push_back(xin);
        luJingSuoYin[jian] = shuJuBiao.size() - 1;
    }
    else {
        shuJuBiao[it->second].shuLiang += shuLiang;
    }

    // ★ 统一在这里累加容量，不再分分支
    dangQianRongLiang += zheCiZhanRong;
    _标记已变化();

    call_deferred("emit_signal", "material_added", luJing, shuLiang);
    call_deferred("emit_signal", "capacity_updated", dangQianRongLiang, zuiDaRongLiang);
    return true;
}

// ========== 移除 ==========
int32_t MaterialContainer::remove_material(const String& luJing, int32_t shuLiang) {
    if (shuLiang <= 0) return 0;

    std::lock_guard<std::mutex> lock(shuJuSuo);

    std::string jian = luJing.utf8().get_data();
    auto it = luJingSuoYin.find(jian);
    if (it == luJingSuoYin.end()) return 0;

    size_t xiaBiao = it->second;
    WuPinShuJu& yiTiao = shuJuBiao[xiaBiao];

    int32_t shiJi = (shuLiang > yiTiao.shuLiang) ? yiTiao.shuLiang : shuLiang;
    yiTiao.shuLiang -= shiJi;
    dangQianRongLiang -= yiTiao.zhanRong * shiJi;

    if (yiTiao.shuLiang == 0) {
        size_t zuiHou = shuJuBiao.size() - 1;
        if (xiaBiao != zuiHou) {
            shuJuBiao[xiaBiao] = shuJuBiao[zuiHou];
            luJingSuoYin[shuJuBiao[xiaBiao].luJing.utf8().get_data()] = xiaBiao;
        }
        shuJuBiao.pop_back();
        luJingSuoYin.erase(jian);
    }

    _标记已变化();   // ★ 关键

    call_deferred("emit_signal", "material_removed", luJing, shiJi);
    call_deferred("emit_signal", "capacity_updated", dangQianRongLiang, zuiDaRongLiang);
    return shiJi;
}

// ========== 查找 ==========
String MaterialContainer::find_material(const Variant& shuXing) const {
    std::lock_guard<std::mutex> lock(shuJuSuo);

    if (shuXing.get_type() == Variant::INT) {
        int32_t xiaBiao = shuXing;
        if (xiaBiao >= 0 && xiaBiao < (int32_t)shuJuBiao.size())
            return shuJuBiao[xiaBiao].luJing;
    }
    else if (shuXing.get_type() == Variant::STRING) {
        String luJing = shuXing;
        std::string jian = luJing.utf8().get_data();
        auto it = luJingSuoYin.find(jian);
        if (it != luJingSuoYin.end())
            return shuJuBiao[it->second].luJing;
    }
    return String("");
}

int32_t MaterialContainer::get_material_quantity(const String& luJing) const {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    std::string jian = luJing.utf8().get_data();
    auto it = luJingSuoYin.find(jian);
    return (it == luJingSuoYin.end()) ? 0 : shuJuBiao[it->second].shuLiang;
}

void MaterialContainer::clear_all() {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    shuJuBiao.clear();
    luJingSuoYin.clear();
    dangQianRongLiang = 0.0f;
    _标记已变化();
}

// ========== 容量 ==========
void  MaterialContainer::set_max_capacity(float zhi) {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    zuiDaRongLiang = zhi;
}
float MaterialContainer::get_max_capacity() const {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    return zuiDaRongLiang;
}
void  MaterialContainer::set_current_capacity(float zhi) {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    dangQianRongLiang = zhi;
}
float MaterialContainer::get_current_capacity() const {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    return dangQianRongLiang;
}

// ========== 网络同步 ==========
// 关键：数据没变就直接返回缓存，省掉"每 0.5 秒重建几千元素"的开销
Array MaterialContainer::get_items_sync() {
    std::lock_guard<std::mutex> lock(shuJuSuo);
    if (wuPinYouBianHua) {
        wuPinHuanCun = _构建物品数组();
        wuPinYouBianHua = false;   // 重建后清脏标记
    }
    return wuPinHuanCun;
}

void MaterialContainer::set_items_sync(const Array& shuJu) {
    std::lock_guard<std::mutex> lock(shuJuSuo);

    shuJuBiao.clear();
    luJingSuoYin.clear();
    dangQianRongLiang = 0.0f;

    for (int i = 0; i < shuJu.size(); i++) {
        if (shuJu[i].get_type() != Variant::DICTIONARY) continue;
        Dictionary yiTiao = shuJu[i];
        if (!yiTiao.has("path")) continue;

        WuPinShuJu xin;
        xin.luJing = yiTiao["path"];
        xin.zhanRong = (float)yiTiao.get("capacity", 1.0f);
        xin.shuLiang = (int)yiTiao.get("quantity", 0);
        if (xin.shuLiang <= 0) continue;

        luJingSuoYin[xin.luJing.utf8().get_data()] = shuJuBiao.size();
        shuJuBiao.push_back(xin);
        dangQianRongLiang += xin.zhanRong * xin.shuLiang;
    }

    wuPinHuanCun = shuJu;
    wuPinYouBianHua = false;
}