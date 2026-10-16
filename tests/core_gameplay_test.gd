extends SceneTree
const Game=preload("res://scripts/Main.gd")

func _initialize()->void:
 var game=Game.new()
 game.start_game()
 assert(game.game["world"].size()==64)
 var cash_before:int=game.game["cash"]
 var chicago:Dictionary=game.game["world"]["CHI"]
 var lot_id=""
 for item in chicago["lots"]:
  if item["status"]=="vacant":
   lot_id=item["id"]
   break
 assert(not lot_id.is_empty())
 var id:String=game.new_store(lot_id)
 assert(id.begins_with("store-"))
 assert(int(game.game["cash"])<cash_before)
 assert(game.upgrade_store(id,"equipment").begins_with("Purchased"))
 assert(game.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(game.upgrade_store(id,"staff").begins_with("Purchased"))
 assert(game.upgrade_store(id,"inventory").begins_with("Purchased"))
 assert(game.upgrade_store(id,"open")=="Store is open.")
 var start_price=int(game.game["stores"][0]["price"])
 game.change_price(id,25)
 assert(int(game.game["stores"][0]["price"])==start_price+25)
 var balance_before:int=game.game["cash"]
 game.advance_week()
 var w=game.game["weekly"]
 assert(int(w["week"])==1)
 assert(int(w["orders"])>0)
 assert(int(w["sales"])>0)
 assert(int(w["costs"])>0)
 assert(int(w["cash"])==int(game.game["cash"]))
 var rows:int=0
 var accounts:Dictionary={}
 for posting in game.game["journal"]:
  var debit=0
  var credit=0
  for row in posting["rows"]:
   debit+=int(row["debit"])
   credit+=int(row["credit"])
   var name:String=row["account"]
   accounts[name]=int(accounts.get(name,0))+int(row["debit"])-int(row["credit"])
  assert(debit==credit)
  rows+=1
 assert(int(accounts["cash"])==int(game.game["cash"]))
 assert(int(accounts["cash"])+int(accounts.get("prepaid_rent",0))+int(accounts.get("equipment_assets",0))+int(accounts.get("inventory_assets",0))==8500000+int(w["income"])-24000)
 assert(int(game.game["cash"])==balance_before+int(w["sales"])-(int(w["costs"])-int(w["orders"])*115))
 var count_before:int=game.game["stores"].size()
 var replay=Game.new()
 assert(replay.load_game())
 assert(replay.game["stores"].size()==count_before)
 assert(int(replay.game["cash"])==int(game.game["cash"]))
 print("GAMEPLAY_PASS 64 cities, lease, purchases, staff, pricing, sales, balanced journal, save/resume; postings=",rows)
 game.free()
 replay.free()
 quit()
