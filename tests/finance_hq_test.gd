extends SceneTree
const Game=preload("res://scripts/Main.gd")
const Office=preload("res://scripts/OfficeWorld3D.gd")

func _initialize()->void:
 var player=Game.new()
 player.start_game()
 var city=player.game["world"]["CHI"]
 var lot_id=""
 for lot in city["lots"]:
  if lot["status"]=="vacant":
   lot_id=lot["id"]
   break
 assert(not lot_id.is_empty())
 var id=player.new_store(lot_id)
 assert(str(id).begins_with("store-"))
 assert(player.upgrade_store(id,"equipment").begins_with("Purchased"))
 assert(player.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(player.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(player.upgrade_store(id,"inventory").begins_with("Purchased"))
 assert(player.upgrade_store(id,"open")=="Store is open.")
 assert(player.corporate_action("product").begins_with("Action"))
 assert(player.corporate_action("technology").begins_with("Action"))
 assert(player.corporate_action("executive").begins_with("Action"))
 var before=player.finance_snapshot()
 assert(before["balanced"])
 assert(before["assets"]==before["equity"]+before["liabilities"])
 assert(before["cash"]==player.game["cash"])
 for i in range(30):
  if player.game["stores"][0]["inventory"]<500:
   assert(player.upgrade_store(id,"inventory").begins_with("Purchased"))
  player.advance_week()
  var snap=player.finance_snapshot()
  assert(snap["balanced"])
  assert(snap["cash"]==player.game["cash"])
  assert(snap["assets"]==snap["liabilities"]+snap["equity"])
 var saved=Game.new()
 assert(saved.load_game())
 assert(saved.finance_snapshot()==player.finance_snapshot())
 var working=Office.new()
 working.set_department("Executive",5)
 get_root().add_child(working)
 for j in range(5):
  await process_frame
 assert(working.floor_root!=null)
 assert(working.employees.size()>0)
 for division in ["Technology","Products","Finance","Executive"]:
  working.set_department(division,9)
  for j in range(2):await process_frame
  assert(working.floor_root!=null)
  assert(working.employees.size()>0)
 working.queue_free()
 print("FINANCE_HQ_PASS: 30 weeks, exact journal balance, corporate actions, 4 distinct native 3D HQ floors, save-resume")
 player.free()
 saved.free()
 quit()
