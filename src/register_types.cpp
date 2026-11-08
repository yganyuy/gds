#include "register_types.h"
#include "Locator/my_Locator.h"    
#include "example/example.h"
#include "material/material_container.h"
#include "item_container/item_table_godot.h"    
#include "table_2d/table_2d_godot.h"
#include "physics_space_2d/physics_space_2d.h" 
#include "physics_space_3d/physics_space_3d.h" 
#include  "simple_tracker_2d/simple_tracker_2d.h"
//#######引入上面的头文就是你自定义#######
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_my_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    GDREGISTER_CLASS(CXT);
    GDREGISTER_CLASS(Example);
    GDREGISTER_CLASS(MaterialContainer);
    GDREGISTER_CLASS(ItemTableManagerGodot);
    GDREGISTER_CLASS(Table2D);
    GDREGISTER_CLASS(PhysicsSpace3D); 
    GDREGISTER_CLASS(PhysicsSpace2D); 
    GDREGISTER_CLASS(SimpleTracker2D); 

     // 注册你的类
}

void uninitialize_my_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {
    GDExtensionBool GDE_EXPORT example_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization) {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
        init_obj.register_initializer(initialize_my_module);
        init_obj.register_terminator(uninitialize_my_module);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
        return init_obj.init();
    }
}