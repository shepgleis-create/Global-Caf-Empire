extends SceneTree
const World=preload("res://scripts/WorldCatalog.gd")
const City=preload("res://scripts/CityWorld3D.gd")

func _initialize()->void:
 call_deferred("run")

func run()->void:
 var selected=City.new()
 selected.size=Vector2(430,932)
 selected.setup(World.build_city("CHI",1234)["lots"],[],"CHI")
 get_root().add_child(selected)
 for n in range(3):await process_frame
 assert(selected.flags.size()==16)
 var known_id:String=selected.flags.keys()[0]
 var center:Vector3=selected.flags[known_id]
 var projected:Vector2=selected.camera.unproject_position(center)
 var phone_tap:Vector2=projected*selected.size/Vector2(selected.view.size)
 selected.select_at(phone_tap)
 assert(selected.selected_lot==known_id)
 print("TOUCH_MAP_PASS: 16 selectable lots, phone-height-to-render-viewport coordinates mapped exactly")
 selected.queue_free()
 quit()
