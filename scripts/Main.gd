extends Control
# Native Godot 4 portrait game shell. Business state is authoritative; the 3D
# city scene is its presentation, not the source of financial outcomes.

const Catalog=preload("res://scripts/WorldCatalog.gd")
const City=preload("res://scripts/CityWorld3D.gd")
const SAVE_PATH="user://global_cafe_empire_v1.json"
const NAV=["World","Stores","Company","Atlas","Founder"]
const DARK=Color("#12252b")
const PANEL=Color("#203840")
const PAPER=Color("#e9ebdf")
const GOLD=Color("#dcae68")
var game:Dictionary={}
var ui:Control
var map:Control
var scene:Control
var status:Label
var body:VBoxContainer
var active_screen="World"
var selected_lot=""
var selected_store=""
var font_size:=17

func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 if FileAccess.file_exists(SAVE_PATH):
  if not load_game():start_game()
 else:start_game()
 rebuild_ui()

func start_game()->void:
 var chicago=Catalog.build_city("CHI",20261016)
 game={"version":1,"seed":20261016,"company":"First Light Coffee",
  "city":"CHI","week":0,"cash":8500000,"capital":8500000,
  "world":Catalog.build_all(20261016,chicago),
  "stores":[],"journal":[],"history":[],"weekly":{},
  "next_store_id":1,"founder_cash":0,"company_debt":0}
 post("Initial founder capital",[{"account":"cash","debit":8500000,"credit":0},
  {"account":"paid_in_capital","debit":0,"credit":8500000}])
 save_game()

func save_game()->void:
 var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 if file!=null:
  file.store_string(JSON.stringify(game))
  file.flush()

func load_game()->bool:
 var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
 if file==null:return false
 var parsed=JSON.parse_string(file.get_as_text())
 if not parsed is Dictionary:return false
 if not parsed.has("cash") or not parsed.has("world"):return false
 game=parsed
 return true

func money(cents:int)->String:
 var sign="-" if cents<0 else ""
 var v=absi(cents)
 return "%s$%s.%02d" % [sign,comma(int(v/100)),v%100]

func comma(v:int)->String:
 var t=str(v)
 var out=""
 for i in range(t.length()):
  if i>0 and (t.length()-i)%3==0:out+=","
  out+=t[i]
 return out

func post(note:String,rows:Array)->bool:
 var d=0
 var c=0
 for row in rows:
  d+=int(row["debit"])
  c+=int(row["credit"])
 if d!=c:
  push_error("Unbalanced journal posting: "+note)
  return false
 game["journal"].append({"week":int(game["week"]),"note":note,"rows":rows})
 return true

func transact(cost:int,expense_account:String,note:String)->bool:
 if cost<0 or int(game["cash"])<cost:return false
 if not post(note,[{"account":expense_account,"debit":cost,"credit":0},
   {"account":"cash","debit":0,"credit":cost}]):return false
 game["cash"]=int(game["cash"])-cost
 return true

func store_index(id:String)->int:
 for i in range(game["stores"].size()):
  if game["stores"][i]["id"]==id:return i
 return -1

func new_store(lot_id:String)->String:
 for id in game["world"].keys():
  var city:Dictionary=game["world"][id]
  for j in range(city["lots"].size()):
   var lot:Dictionary=city["lots"][j]
   if lot["id"]!=lot_id:continue
   if lot["status"]!="vacant":return "Property already occupied."
   var deposit=int(lot["rent_cents"])*4
   if not transact(deposit,"prepaid_rent","Lease deposit at "+lot_id):return "Insufficient cash."
   var sid="store-%s"%str(game["next_store_id"])
   game["next_store_id"]=int(game["next_store_id"])+1
   var entry={"id":sid,"lot":lot_id,"city":id,"name":lot["name"]+" Café",
    "rent":int(lot["rent_cents"]),"footfall":int(lot["footfall"]),
    "staff":0,"equipment":0,"inventory":0,"price":575,
    "rating":70,"awareness":12,"status":"preparing","sales":0,
    "orders":0,"last_profit":0,"last_capacity":0}
   game["stores"].append(entry)
   lot["status"]="leased"
   lot["store_id"]=sid
   save_game()
   return sid
 return "Property not found."

func upgrade_store(id:String,kind:String)->String:
 var idx=store_index(id)
 if idx<0:return "Store not found."
 var s:Dictionary=game["stores"][idx]
 var cost=0
 match kind:
  "equipment":cost=690000
  "staff":cost=12000
  "inventory":cost=80500
  "open":
   if int(s["staff"])<2 or int(s["equipment"])<1 or int(s["inventory"])<500:
    return "Opening requires 2 staff, equipment, and at least 500 ingredient units."
   s["status"]="open"
   game["stores"][idx]=s
   save_game()
   return "Store is open."
  _:return "Unknown upgrade."
 if not transact(cost,"equipment_assets" if kind=="equipment" else ("inventory_assets" if kind=="inventory" else "recruiting_expense"),"Café "+kind):return "Insufficient corporate cash."
 match kind:
  "equipment":s["equipment"]=int(s["equipment"])+1
  "staff":s["staff"]=int(s["staff"])+1
  "inventory":s["inventory"]=int(s["inventory"])+700
 game["stores"][idx]=s
 save_game()
 return "Purchased "+kind+"."

func change_price(id:String,delta:int)->void:
 var idx=store_index(id)
 if idx<0:return
 var s:Dictionary=game["stores"][idx]
 s["price"]=clampi(int(s["price"])+delta,250,1400)
 game["stores"][idx]=s
 save_game()

func advance_week()->void:
 var week=int(game["week"])+1
 game["week"]=week
 var total_revenue=0
 var total_orders=0
 var costs=0
 var events=[]
 var current_rivals:Dictionary={}
 for city_id in game["world"]:
  current_rivals[city_id]=0
 for s in game["stores"]:
  if s["status"]=="open":current_rivals[s["city"]]=int(current_rivals[s["city"]])+1
 for i in range(game["stores"].size()):
  var s:Dictionary=game["stores"][i]
  if s["status"]!="open":continue
  var available=int(s["inventory"])
  var daily_footfall=float(s["footfall"])/7.0
  var trend=0.85+0.15*sin(float(week)*0.31+float(i))
  var awareness=0.34+float(s["awareness"])/135.0
  var elasticity=pow(575.0/float(s["price"]),1.6)
  var saturation=1.0+0.13*max(0,int(current_rivals[s["city"]])-1)
  var target=roundi(daily_footfall*0.30*7.0*trend*awareness*elasticity/saturation)
  var max_capacity=int(s["equipment"])*1200
  max_capacity=mini(max_capacity,int(s["staff"])*450)
  var served=clampi(target,0,mini(available,max_capacity))
  var lost=maxi(0,target-served)
  var revenue=served*int(s["price"])
  var ingredient_cogs=served*115
  var wage=int(s["staff"])*40000
  var rent=int(s["rent"])
  var utilities=12000+int(s["equipment"])*3500
  var overhead=wage+rent+utilities
  # Inventory inventory cost is capitalized when purchased; COGS transfers
  # stock assets into expense as units are sold.
  post("Customer sales "+s["id"],[{"account":"cash","debit":revenue,"credit":0},
   {"account":"store_revenue","debit":0,"credit":revenue}])
  post("Recognize ingredient cost "+s["id"],[{"account":"cost_of_goods_sold","debit":ingredient_cogs,"credit":0},
   {"account":"inventory_assets","debit":0,"credit":ingredient_cogs}])
  post("Weekly store operating expense "+s["id"],[{"account":"operating_expense","debit":overhead,"credit":0},
   {"account":"cash","debit":0,"credit":overhead}])
  game["cash"]=int(game["cash"])+revenue-overhead
  s["inventory"]=available-served
  s["orders"]=served
  s["sales"]=revenue
  s["last_capacity"]=max_capacity
  s["last_profit"]=revenue-ingredient_cogs-overhead
  s["rating"]=clampi(int(s["rating"])+(1 if lost==0 else -2),20,95)
  s["awareness"]=clampi(int(s["awareness"])+1,0,95)
  total_revenue+=revenue
  total_orders+=served
  costs+=ingredient_cogs+overhead
  if lost>0:events.append("%s missed %s potential customers (capacity/stock)." % [s["name"],comma(lost)])
  game["stores"][i]=s
 game["weekly"]={"week":week,"sales":total_revenue,"costs":costs,
  "income":total_revenue-costs,"orders":total_orders,"cash":game["cash"],
  "events":events}
 game["history"].append(game["weekly"].duplicate(true))
 save_game()

func colorset(c:Control,shade:Color)->void:
 var style=StyleBoxFlat.new()
 style.bg_color=shade
 style.corner_radius_top_left=13
 style.corner_radius_top_right=13
 style.corner_radius_bottom_left=13
 style.corner_radius_bottom_right=13
 c.add_theme_stylebox_override("panel",style)

func font(label:Label,sz:int=17,col:Color=PAPER)->void:
 label.add_theme_color_override("font_color",col)
 label.add_theme_font_size_override("font_size",sz)

func txt(text:String,sz:int=17,color:Color=PAPER)->Label:
 var x=Label.new()
 x.text=text
 x.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 font(x,sz,color)
 return x

func btn(caption:String,callback:Callable)->Button:
 var b=Button.new()
 b.text=caption
 b.custom_minimum_size=Vector2(0,49)
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.pressed.connect(callback)
 return b

func clear_all(n:Node)->void:
 for c in n.get_children():n.remove_child(c);c.queue_free()

func rebuild_ui()->void:
 if ui!=null:
  remove_child(ui)
  ui.queue_free()
 ui=Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(ui)
 var bg=ColorRect.new()
 bg.color=DARK
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(bg)
 scene=City.new()
 scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scene.setup(game["world"][game["city"]]["lots"],game["stores"],game["city"])
 scene.lot_selected.connect(_lot_clicked)
 ui.add_child(scene)
 scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scene.visible=active_screen=="World"
 var overlay=VBoxContainer.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_theme_constant_override("separation",7)
 ui.add_child(overlay)
 var top=PanelContainer.new()
 colorset(top,DARK)
 top.custom_minimum_size=Vector2(0,82)
 overlay.add_child(top)
 var header=VBoxContainer.new()
 header.add_theme_constant_override("separation",0)
 top.add_child(header)
 var bname=txt(str(game["company"]),20)
 bname.autowrap_mode=TextServer.AUTOWRAP_OFF
 bname.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 bname.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 header.add_child(bname)
 status=txt("%s · Week %d" % [money(int(game["cash"])),int(game["week"])],16,GOLD)
 status.autowrap_mode=TextServer.AUTOWRAP_OFF
 status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 header.add_child(status)
 var tabs=HBoxContainer.new()
 tabs.add_theme_constant_override("separation",2)
 overlay.add_child(tabs)
 for n in NAV:
  var button=btn(n,func():active_screen=n;rebuild_ui())
  button.add_theme_font_size_override("font_size",13)
  tabs.add_child(button)
 if active_screen=="World":
  var remaining=Control.new()
  remaining.size_flags_vertical=Control.SIZE_EXPAND_FILL
  overlay.add_child(remaining)
 var panel=PanelContainer.new()
 colorset(panel,DARK)
 panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
 panel.visible=active_screen!="World"
 overlay.add_child(panel)
 var scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 body=VBoxContainer.new()
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",12)
 scroll.add_child(body)
 match active_screen:
  "World":pass
  "Stores":show_stores()
  "Company":show_company()
  "Atlas":show_atlas()
  "Founder":show_founder()
 var bottom=PanelContainer.new()
 colorset(bottom,DARK)
 overlay.add_child(bottom)
 var tools=HBoxContainer.new()
 bottom.add_child(tools)
 tools.add_child(btn("Advance 1 week",func():advance_week();active_screen="Company";rebuild_ui()))
 tools.add_child(btn("Save",func():save_game();status.text="Saved"))
 if active_screen=="World":
  var guide=PanelContainer.new()
  colorset(guide,DARK)
  guide.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
  guide.position=Vector2(0,138)
  ui.add_child(guide)
  guide.add_child(txt("Tap a marked building to lease · Drag map · Scroll to zoom",14,GOLD))

func _lot_clicked(lot_id:String)->void:
 selected_lot=lot_id
 var district:Dictionary={}
 for x in game["world"][game["city"]]["lots"]:
  if x["id"]==lot_id:district=x;break
 if district.is_empty():return
 var dialog=ConfirmationDialog.new()
 dialog.title="Commercial lease · "+str(district["name"])
 dialog.dialog_text="Weekly rent: %s\nFootfall/week: %s\nDeposit (4 weeks): %s\n\nSign lease and create a café?" % [money(int(district["rent_cents"])),comma(int(district["footfall"])),money(int(district["rent_cents"])*4)]
 add_child(dialog)
 dialog.confirmed.connect(func():
  var result=new_store(lot_id)
  if result.begins_with("store-"):selected_store=result;active_screen="Stores";rebuild_ui()
  else:show_message(result))
 dialog.popup_centered(Vector2i(360,330))

func show_message(s:String)->void:
 var a=AcceptDialog.new()
 a.title="Global Café Empire"
 a.dialog_text=s
 add_child(a)
 a.popup_centered()

func show_stores()->void:
 body.add_child(txt("Your cafés",27,GOLD))
 if game["stores"].is_empty():
  body.add_child(txt("You have no stores yet. Open World, select a vacant building, and sign a lease."))
 for s in game["stores"]:
  body.add_child(txt("%s · %s" % [s["name"],s["city"]],20,GOLD))
  body.add_child(txt("%s · Weekly rent %s · Latest profit %s" % [s["status"],money(int(s["rent"])),money(int(s["last_profit"]))]))
  body.add_child(txt("Staff %d · Machines %d · Ingredient units %s" % [int(s["staff"]),int(s["equipment"]),comma(int(s["inventory"]))],14))
  var id:String=s["id"]
  var row=HBoxContainer.new()
  body.add_child(row)
  row.add_child(btn("Hire",func():show_message(upgrade_store(id,"staff"));rebuild_ui()))
  row.add_child(btn("Machine",func():show_message(upgrade_store(id,"equipment"));rebuild_ui()))
  row.add_child(btn("Supplies",func():show_message(upgrade_store(id,"inventory"));rebuild_ui()))
  body.add_child(btn("Open café / check requirements",func():show_message(upgrade_store(id,"open"));rebuild_ui()))
  var p=HBoxContainer.new()
  body.add_child(p)
  p.add_child(btn("− $0.25",func():change_price(id,-25);rebuild_ui()))
  p.add_child(txt("Drink price "+money(int(s["price"]))))
  p.add_child(btn("+ $0.25",func():change_price(id,25);rebuild_ui()))
  body.add_child(HSeparator.new())

func show_company()->void:
 body.add_child(txt("Corporate overview",27,GOLD))
 body.add_child(txt("%s cash | %s cafés" % [money(int(game["cash"])),comma(game["stores"].size())]))
 body.add_child(txt("Company finances and weekly results derive from the game ledger, not UI display calculations.",14))
 if game["weekly"].is_empty():
  body.add_child(txt("No trading week yet. Lease and open a store, then advance time."))
 else:
  var w=game["weekly"]
  body.add_child(txt("WEEK %d OPERATIONS" % int(w["week"]),19,GOLD))
  body.add_child(txt("Gross sales       %s" % money(int(w["sales"]))))
  body.add_child(txt("Cost and expenses %s" % money(int(w["costs"]))))
  body.add_child(txt("Net income        %s" % money(int(w["income"]))))
  body.add_child(txt("Cups served       %s" % comma(int(w["orders"]))))
  for issue in w["events"]:body.add_child(txt("• "+str(issue),14))
 body.add_child(HSeparator.new())
 body.add_child(txt("Accounting journal",20,GOLD))
 var rows=game["journal"]
 for idx in range(maxi(0,rows.size()-12),rows.size()):
  var j=rows[idx]
  body.add_child(txt("W%d · %s" % [int(j["week"]),str(j["note"])],13))

func show_atlas()->void:
 body.add_child(txt("Global markets",27,GOLD))
 body.add_child(txt("64 simulated city economies. Each city has 16 original commercial parcels; individual 3D environments are being developed.",14))
 var picker=OptionButton.new()
 picker.custom_minimum_size.y=50
 var profiles=Catalog.profiles()
 var index=0
 for p in profiles:
  picker.add_item("%s · %s" % [p["name"],p["country"]])
  if p["id"]==game["city"]:picker.select(index)
  index+=1
 body.add_child(picker)
 body.add_child(btn("Travel / select city",func():
  game["city"]=profiles[picker.selected]["id"]
  active_screen="World"
  save_game()
  rebuild_ui()))

func show_founder()->void:
 body.add_child(txt("Founder & ownership",27,GOLD))
 body.add_child(txt("Founder owns 100% of the company at launch. Corporate cash is distinct from personal cash."))
 body.add_child(txt("Paid-in capital: "+money(int(game["capital"]))))
 body.add_child(txt("Corporate funds: "+money(int(game["cash"]))))
 body.add_child(txt("Personal cash: "+money(int(game["founder_cash"]))))
 body.add_child(txt("Legacy, personal assets and governance features will be built on the same ownership and cash ledgers.",14))
