extends SubViewportContainer
class_name CafeCityWorld3D
signal lot_selected(lot_id:String)

const Catalog=preload("res://scripts/WorldCatalog.gd")
var selected_lot: String=""
var city_id:String="CHI"
var lots:Array=[]
var stores:Array=[]
var view:SubViewport
var world:Node3D
var camera:Camera3D
var actors:Array=[]
var flags:Dictionary={}
var colors:Dictionary={}
var boxes:Dictionary={}
var pan:=Vector2.ZERO
var zoom:float=1.0
var moving:=false
var traveled:=0.0
var time:float=0.0

func setup(parcels:Array,locations:Array,id:String="CHI")->void:
 lots=parcels
 stores=locations
 city_id=id
 if is_inside_tree():rebuild()

func _ready()->void:
 stretch=true
 mouse_filter=Control.MOUSE_FILTER_STOP
 view=SubViewport.new()
 view.own_world_3d=true
 view.size=Vector2i(430,720)
 view.msaa_3d=Viewport.MSAA_2X
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(view)
 resized.connect(_fit)
 gui_input.connect(_touch)
 _fit()
 rebuild()

func _fit()->void:
 if view:if not stretch:view.size=Vector2i(maxi(32,roundi(size.x)),maxi(32,roundi(size.y)))

func material(tag:String,col:Color,metal:float=0.0,glow:bool=false)->StandardMaterial3D:
 if colors.has(tag):return colors[tag]
 var m:=StandardMaterial3D.new()
 m.albedo_color=col
 m.metallic=metal
 m.roughness=0.69
 if glow:
  m.emission_enabled=true
  m.emission=col
 colors[tag]=m
 return m

func box(parent:Node3D,p:Vector3,s:Vector3,mat:Material)->void:
 if parent==world:
  var key:=str(mat.get_instance_id())
  if not boxes.has(key):boxes[key]={"mat":mat,"parts":[]}
  boxes[key]["parts"].append(Transform3D(Basis.IDENTITY.scaled(s),p))
  return
 var o:=MeshInstance3D.new()
 var m:=BoxMesh.new()
 m.size=s
 o.mesh=m
 o.material_override=mat
 o.position=p
 parent.add_child(o)

func flush()->void:
 for key in boxes.keys():
  var item:Dictionary=boxes[key]
  var parts:Array=item["parts"]
  var multi:=MultiMesh.new()
  multi.transform_format=MultiMesh.TRANSFORM_3D
  multi.mesh=BoxMesh.new()
  multi.instance_count=parts.size()
  for i in range(parts.size()):multi.set_instance_transform(i,parts[i])
  var actor:=MultiMeshInstance3D.new()
  actor.multimesh=multi
  actor.material_override=item["mat"]
  world.add_child(actor)
 boxes.clear()

func rebuild()->void:
 if view==null:return
 actors.clear()
 flags.clear()
 colors.clear()
 boxes.clear()
 for child in view.get_children():
  view.remove_child(child)
  child.queue_free()
 world=Node3D.new()
 view.add_child(world)
 var environment:=Environment.new()
 environment.background_mode=Environment.BG_COLOR
 environment.background_color=Color("9ab3bc")
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color=Color("d3d4cf")
 environment.ambient_light_energy=0.75
 var env:=WorldEnvironment.new()
 env.environment=environment
 world.add_child(env)
 var sun:=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-61,-34,-18)
 sun.light_energy=1.35
 sun.light_color=Color("ffe4c0")
 sun.shadow_enabled=true
 world.add_child(sun)
 camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.near=0.2
 camera.far=500
 world.add_child(camera)
 move_camera()
 generate_city()
 flush()

func move_camera()->void:
 if camera==null:return
 camera.position=Vector3(70*zoom+pan.x,88*zoom,86*zoom+pan.y)
 camera.look_at(Vector3(pan.x,0,pan.y))
 camera.size=126*zoom

func generate_city()->void:
 var meta:=Catalog.profile(city_id)
 var rng:=RandomNumberGenerator.new()
 rng.seed=abs(city_id.hash())+11029
 var style:String=meta.get("style","modern")
 var asphalt=material("asphalt",Color("424a50"))
 var sidewalks=material("walk",Color("bcbdb6"))
 var lane=material("stripe",Color("e3cba5"))
 var grass=material("park",Color("567e63"))
 var water=material("water",Color("3d8792"),0.3)
 var ground_color=Color("768778")
 if style=="desert":ground_color=Color("b6a78b")
 elif style in ["historic","canals"]:ground_color=Color("9a998e")
 elif style=="mountain":ground_color=Color("667d74")
 var earth=material("earth",ground_color)
 var stone=material("pedestrian_plaza",Color("d1c7ad"))
 var crossing=material("pedestrian_crossing",Color("e5e3d9"))
 var cycle=material("cycle_lane",Color("698c83"))
 var foliage=material("street_trees",Color("608e6b"))
 var riveredge=material("riveredge",Color("c5b9a5"))
 box(world,Vector3(0,-0.5,0),Vector3(160,0.9,160),earth)
 box(world,Vector3(0,0,0),Vector3(147,0.18,147),asphalt)
 # Original multi-modal avenues and crossings distinguish the world map from a tile grid.
 for avenue in [-1,1]:
  box(world,Vector3(avenue*5.7,0.11,0),Vector3(0.22,0.02,140),cycle)
 for i in range(13):
  var k:float=(float(i)-6.0)*11.4+5.7
  box(world,Vector3(k,0.10,0),Vector3(0.14,0.02,143),lane)
  box(world,Vector3(0,0.10,k),Vector3(143,0.02,0.14),lane)
 for i in range(1,12,2):
  for j in range(1,12,3):
   var cx:float=(float(i)-6)*11.4+5.7
   var cz:float=(float(j)-6)*11.4+5.7
   for c in range(4):
    box(world,Vector3(cx-1.1+float(c)*0.70,0.125,cz),Vector3(0.36,0.018,2.5),crossing)
 for i in range(12):
  for j in range(12):
   var x:float=(float(i)-5.5)*11.4
   var z:float=(float(j)-5.5)*11.4
   var owned_slot:bool=i>=4 and i<8 and j>=4 and j<8
   var sea:bool=(style in ["harbor","coastal","lakeshore","canals","waterfront"]) and (i==0 or (style=="canals" and i==10))
   if sea:
    box(world,Vector3(x,0.06,z),Vector3(9.1,0.12,9.1),water)
    if j%3==0:
     box(world,Vector3(x+3.4,0.23,z),Vector3(1.1,0.32,8.4),riveredge)
     if j%6==0:
      box(world,Vector3(x+1.0,0.28,z),Vector3(5.2,0.20,1.35),riveredge)
    continue
   box(world,Vector3(x,0.19,z),Vector3(9.1,0.30,9.1),sidewalks)
   var is_plaza:bool=not owned_slot and ((i*13+j*19+abs(city_id.hash())%17)%27==0)
   if is_plaza:
    box(world,Vector3(x,0.33,z),Vector3(8.3,0.16,8.3),stone)
    box(world,Vector3(x,0.47,z),Vector3(6.0,0.10,5.6),grass)
    if j%2==0:
     box(world,Vector3(x,0.55,z),Vector3(1.3,0.16,1.3),riveredge)
     box(world,Vector3(x,1.23,z),Vector3(0.46,1.38,0.46),foliage)
    for t in range(4):
     add_tree(Vector3(x+(-2.7 if t%2==0 else 2.7),0.50,z+(-2.7 if t<2 else 2.7)))
    box(world,Vector3(x,0.53,z),Vector3(2.0,0.30,1.3),material("park_bench",Color("886f5b")))
    continue
   var lot:Dictionary={}
   if owned_slot and lots.size()==16:lot=lots[(j-4)*4+(i-4)]
   var height:float=rng.randf_range(8,21)
   if style in ["dense","modern","desert"] and rng.randf()<0.35:height*=rng.randf_range(1.5,2.5)
   if style=="historic":height=minf(height,15)
   elif style=="industrial":height=rng.randf_range(6,13)
   elif style=="tropical":height=rng.randf_range(8,19)
   elif style=="mountain":height=rng.randf_range(5,16)
   if style in ["dense","modern"] and (i-5)*(i-5)+(j-5)*(j-5)<15 and not owned_slot:
    height*=1.30
   if style=="desert" and rng.randf()<0.12:height*=1.65
   make_building(Vector3(x,0.38,z),height,rng,lot)
   if ((i*5+j*11)%7==0):
    add_tree(Vector3(x+3.8,0.35,z+3.8))
 for i in range(11):
  add_vehicle(i,rng)
 for i in range(16):
  add_pedestrian(i,rng)

func make_building(at:Vector3,height:float,rng:RandomNumberGenerator,lot:Dictionary)->void:
 var style:String=Catalog.profile(city_id).get("style","modern")
 var palette=[Color("c9c7b9"),Color("acb9b9"),Color("bdafa2"),Color("afb2b5"),Color("b7bbb0"),Color("a9aeaf")]
 if style=="historic":palette=[Color("dbccae"),Color("d1bfaa"),Color("c4ab96"),Color("c8c1b2"),Color("b3b7ac"),Color("ddd2be")]
 if style in ["dense","modern"]:palette=[Color("adb8c3"),Color("a6bbb9"),Color("d0cec5"),Color("9facb1"),Color("c6b6a9"),Color("c4c9c6")]
 if style=="desert":palette=[Color("cebeaa"),Color("c4b9a9"),Color("cfc2b4"),Color("a9b5b6"),Color("d2c4b1"),Color("beb4a3")]
 var index:int=rng.randi_range(0,palette.size()-1)
 var facade=material("facade"+str(index),palette[index])
 var glass=material("windows",Color("59899a"),0.24)
 var dark=material("frames",Color("4d5c62"))
 var roof=material("roof",Color("777d7c"))
 var h:float=maxf(7,height)
 var w:float=rng.randf_range(6.5,8.5)
 var d:float=rng.randf_range(6.7,8.5)
 box(world,at+Vector3(0,h/2,0),Vector3(w,h,d),facade)
 box(world,at+Vector3(0,h+0.22,0),Vector3(w+0.32,0.3,d+0.34),roof)
 if style=="historic":
  box(world,at+Vector3(0,h+0.68,0),Vector3(w*0.82,0.72,d*0.84),material("mansard",Color("686e73")))
  box(world,at+Vector3(0,0.30,0),Vector3(w+0.46,0.29,d+0.38),material("base",Color("7e827f")))
 elif style in ["dense","modern"] and h>22:
  box(world,at+Vector3(0,h+1.20,0),Vector3(w*0.51,1.9,d*0.54),facade)
  box(world,at+Vector3(0,h+2.23,0),Vector3(w*0.57,0.18,d*0.60),roof)
 elif style in ["coastal","tropical","waterfront"]:
  box(world,at+Vector3(0,h+0.49,0),Vector3(w*0.70,0.32,d*0.65),material("roofdeck",Color("a4b6a6")))
 for trim_level in range(1,mini(5,maxi(2,int(h/6.0)))):
  var trim_height:float=float(trim_level)*h/float(mini(5,maxi(2,int(h/6.0))))
  box(world,at+Vector3(0,trim_height,d/2+0.10),Vector3(w*0.94,0.09,0.16),roof)
 if rng.randf()<0.35:
  box(world,at+Vector3(w*0.33,h+0.59,d*0.18),Vector3(0.9,0.7,1.15),material("vent",Color("798283")))
 if rng.randf()<0.4:box(world,at+Vector3(0,h+0.53,0),Vector3(1.4,0.45,2.0),dark)
 var floors:int=mini(6,maxi(2,roundi(h/3.0)))
 for k in range(floors):
  var y:float=(float(k)+0.55)*h/float(floors)
  for n in range(3):
   box(world,at+Vector3((float(n)-1)*w*0.26,y,d/2+0.06),Vector3(w*0.18,1.45,0.1),glass)
   box(world,at+Vector3(w/2+0.06,y,(float(n)-1)*d*0.26),Vector3(0.1,1.45,d*0.18),glass)
 if not lot.is_empty():
  box(world,at+Vector3(0,1.2,d/2+0.16),Vector3(w*0.68,2.25,0.12),dark)
  box(world,at+Vector3(0,1.15,d/2+0.27),Vector3(w*0.57,1.58,0.1),glass)
  box(world,at+Vector3(0,2.55,d/2+0.38),Vector3(w*0.72,0.23,0.75),material("canopy",Color("526870")))
  var status:String=lot["status"]
  var color=Color("a8dac3") if status=="vacant" else (Color("e3b771") if status=="leased" else Color("80929b"))
  var indicator:=material("pin"+status,color,0.12,true)
  box(world,at+Vector3(0,h+0.92,0),Vector3(1.5,1.5,1.5),indicator)
  flags[lot["id"]]=Vector3(at.x,0,at.z)

func add_tree(at:Vector3)->void:
 var trunk=material("tree_trunk",Color("675b4e"))
 var foliage=material("tree_canopy",Color("497b5c"))
 box(world,at+Vector3(0,0.9,0),Vector3(0.25,1.9,0.25),trunk)
 box(world,at+Vector3(0,2.25,0),Vector3(1.50,1.8,1.45),foliage)
 box(world,at+Vector3(0,3.0,0),Vector3(0.90,0.55,0.86),foliage)

func add_vehicle(i:int,rng:RandomNumberGenerator)->void:
 var car:=Node3D.new()
 world.add_child(car)
 var coat=material("car"+str(i%4),[Color("d8d7d4"),Color("ba6f61"),Color("315466"),Color("bf9a56")][i%4])
 box(car,Vector3(0,0.48,0),Vector3(1.3,0.55,2.3),coat)
 box(car,Vector3(0,0.87,0.02),Vector3(1.1,0.42,1.3),material("windshield",Color("4b7180"),0.3))
 actors.append({"node":car,"kind":0,"track":i%4,"start":rng.randf_range(-63,63),"speed":rng.randf_range(2.5,5.5)})

func add_pedestrian(i:int,rng:RandomNumberGenerator)->void:
 var actor:=Node3D.new()
 world.add_child(actor)
 box(actor,Vector3(0,0.69,0),Vector3(0.28,0.7,0.22),material("shirt"+str(i%3),[Color("355063"),Color("a98473"),Color("cbbbaa")][i%3]))
 box(actor,Vector3(0,1.18,0),Vector3(0.23,0.24,0.24),material("skin",Color("c49e83")))
 actors.append({"node":actor,"kind":1,"track":i%4,"start":rng.randf_range(-60,60),"speed":rng.randf_range(0.4,1.5)})

func _process(dt:float)->void:
 time+=dt
 for a in actors:
  var node:Node3D=a["node"]
  var offset:float=wrapf(float(a["start"])+time*float(a["speed"]),-64,64)
  var track:int=a["track"]
  if int(a["kind"])==0:
   if track<2:node.position=Vector3(offset,0,12.0 if track==0 else -11.3)
   else:node.position=Vector3(11.3 if track==2 else -12.0,0,offset)
   node.rotation.y=PI/2 if track<2 else 0
  else:
   if track<2:node.position=Vector3(offset,0,17 if track==0 else -17)
   else:node.position=Vector3(17 if track==2 else -17,0,offset)

func _touch(event:InputEvent)->void:
 if event is InputEventMagnifyGesture:
  zoom=clampf(zoom/maxf(event.factor,0.6),0.36,2.6)
  move_camera()
 elif event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
   zoom=clampf(zoom*0.86,0.36,2.6)
   move_camera()
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
   zoom=clampf(zoom*1.14,0.36,2.6)
   move_camera()
  elif event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed:
    moving=true
    traveled=0
   elif moving:
    if traveled<13:select_at(event.position)
    moving=false
 elif event is InputEventMouseMotion and moving:
  traveled+=event.relative.length()
  pan-=event.relative*0.12*zoom
  pan=pan.clamp(Vector2(-50,-50),Vector2(50,50))
  move_camera()
 elif event is InputEventScreenDrag:
  traveled+=event.relative.length()
  pan-=event.relative*0.12*zoom
  move_camera()
 elif event is InputEventScreenTouch:
  if event.pressed:traveled=0
  elif traveled<13:select_at(event.position)

func select_at(position:Vector2)->void:
 if camera==null:return
 # SubViewport uses a lower fixed resolution than its portrait container.
 # Convert screen pixels to internal pixels before ray projection (critical on iPhone).
 var viewport_position=position*Vector2(view.size)/size
 var point=Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(viewport_position),camera.project_ray_normal(viewport_position))
 if point==null:return
 var at:Vector3=point
 for id in flags:
  var location:Vector3=flags[id]
  if Vector2(at.x,at.z).distance_to(Vector2(location.x,location.z))<5.4:
   selected_lot=id
   lot_selected.emit(id)
   return
