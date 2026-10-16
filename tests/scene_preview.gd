extends SceneTree
const World=preload("res://scripts/WorldCatalog.gd")
const City=preload("res://scripts/CityWorld3D.gd")

func _initialize()->void:
 var root=Control.new()
 root.size=Vector2(430,932)
 get_root().add_child(root)
 var viewport=City.new()
 viewport.size=Vector2(430,932)
 viewport.setup(World.build_city("PAR",1999)["lots"],[],"PAR")
 root.add_child(viewport)
 viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 call_deferred("finish")

func finish()->void:
 for i in range(8):
  await process_frame
 print("SCENE_PREVIEW_RENDERED")
 quit()
