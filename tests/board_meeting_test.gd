extends SceneTree
const Game=preload("res://scripts/Main.gd")

func _initialize()->void:
 var x=Game.new()
 x.start_game()
 assert(x.hold_board_meeting("Growth campaign").begins_with("Open at least one"))
 var lot_id=""
 for parcel in x.game["world"]["CHI"]["lots"]:
  if parcel["status"]=="vacant":lot_id=parcel["id"];break
 var id=x.new_store(lot_id)
 assert(str(id).begins_with("store-"))
 assert(x.upgrade_store(id,"equipment").begins_with("Purchased"))
 assert(x.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(x.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(x.upgrade_store(id,"inventory").begins_with("Purchased"))
 assert(x.upgrade_store(id,"open")=="Store is open.")
 var prior_cash:int=x.game["cash"]
 var awareness_before:int=x.game["stores"][0]["awareness"]
 var result:String=x.hold_board_meeting("Growth campaign")
 assert(result.begins_with("Board motion approved"))
 assert(int(x.game["cash"])==prior_cash-180000)
 assert(int(x.game["stores"][0]["awareness"])==awareness_before+6)
 assert(x.hold_board_meeting("Employee development").begins_with("Board decisions are available"))
 assert(x.finance_snapshot()["balanced"])
 for i in range(13):
  x.advance_week()
 var rating_before:int=x.game["stores"][0]["rating"]
 var cash_before:int=x.game["cash"]
 assert(x.hold_board_meeting("Employee development").begins_with("Board motion approved"))
 assert(int(x.game["cash"])==cash_before-95000)
 assert(int(x.game["stores"][0]["rating"])==mini(95,rating_before+5))
 assert(x.game["board_history"].size()==2)
 assert(x.finance_snapshot()["balanced"])
 var restored=Game.new()
 assert(restored.load_game())
 assert(restored.game["board_history"].size()==2)
 assert(restored.finance_snapshot()["balanced"])
 print("BOARD_PASS: one vote per quarter, spend-once accounting, changed demand inputs, persistent decisions")
 x.free()
 restored.free()
 quit()
