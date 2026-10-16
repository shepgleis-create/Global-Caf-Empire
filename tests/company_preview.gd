extends SceneTree
# CI runs real Main.tscn, opens the real Company UI and captures Godot frames.
func _initialize()->void:
 call_deferred("preview")
func preview()->void:
 var game=load("res://scenes/Main.tscn").instantiate()
 get_root().add_child(game)
 for n in range(2):await process_frame
 game.active_screen="Company"
 game.game["department"]="Executive"
 game.rebuild_ui()
 for n in range(8):await process_frame
 print("REAL_HQ_VIEW_CAPTURED")
 quit()
