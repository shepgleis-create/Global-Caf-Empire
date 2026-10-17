extends SubViewportContainer
class_name CafeOfficeWorld3D
# Original 3D corporate-office model. Floor geometry is genuinely instanced
# from the selected department; mini-staff are ambient representatives of team
# capacity, not fictitious employees in the accounting state.
var department:String="Executive"
var seats:int=6
var offices:Dictionary={
 "Executive":{"floor":"#d8c7a9","desk":"#66584e","screen":"#83a8a7"},
 "Products":{"floor":"#c6c2ae","desk":"#a4aa9e","screen":"#739caa"},
 "Technology":{"floor":"#a9b9c1","desk":"#56656d","screen":"#83c5c7"},
 "Finance":{"floor":"#c7b9a8","desk":"#826d5c","screen":"#acd1bc"}}
var sub:SubViewport
var floor_root:Node3D
var camera:Camera3D
var employees:Array=[]
var t:float=0.0

func _ready()->void:
 stretch=true
 sub=SubViewport.new()
 sub.own_world_3d=true
 sub.size=Vector2i(430,310)
 sub.transparent_bg=true
 sub.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(sub)
 rebuild()

func set_department(name:String,capacity:int)->void:
 department=name
 seats=maxi(2,mini(capacity,20))
 if is_inside_tree() and sub!=null:rebuild()

func mat(hex:String,metallic:float=0.0)->StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=Color(hex)
 m.metallic=metallic
 m.roughness=0.6
 return m

func part(parent:Node3D,p:Vector3,ext:Vector3,material:Material)->MeshInstance3D:
 var node=MeshInstance3D.new()
 var mesh=BoxMesh.new()
 mesh.size=ext
 node.mesh=mesh
 node.material_override=material
 node.position=p
 parent.add_child(node)
 return node

func rebuild()->void:
 if sub==null:return
 employees.clear()
 for c in sub.get_children():
  sub.remove_child(c)
  c.queue_free()
 floor_root=Node3D.new()
 sub.add_child(floor_root)
 var env=WorldEnvironment.new()
 var e=Environment.new()
 e.background_mode=Environment.BG_COLOR
 e.background_color=Color("#203840")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color=Color("#ede9df")
 e.ambient_light_energy=0.78
 env.environment=e
 floor_root.add_child(env)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-55,-22,-20)
 sun.light_energy=1.2
 floor_root.add_child(sun)
 camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=11.8
 camera.position=Vector3(14,17,16)
 floor_root.add_child(camera)
 camera.look_at_from_position(Vector3(14,17,16),Vector3(0,0.5,0))
 camera.current=true
 var profile:Dictionary=offices.get(department,offices["Executive"])
 var floor_material=mat(profile["floor"])
 var wall_material=mat("#efe6d5")
 var desk_material=mat(profile["desk"])
 var screen_material=mat(profile["screen"],0.45)
 var glass=mat("#abcdd1",0.25)
 var plant=mat("#4c8565")
 var wood=mat("#826e58")
 part(floor_root,Vector3(0,-0.16,0),Vector3(13,0.35,10),floor_material)
 part(floor_root,Vector3(0,2.4,-5),Vector3(13,4.8,0.22),wall_material)
 part(floor_root,Vector3(-6.5,2.4,0),Vector3(0.22,4.8,10),wall_material)
 for i in range(3):
  part(floor_root,Vector3(-4.1+i*4.05,3.1,-4.82),Vector3(2.8,1.45,0.10),glass)
 for i in range(2):
  part(floor_root,Vector3(-6.38,3.1,-2.8+i*4.5),Vector3(0.10,1.5,2.6),glass)
 var stations=maxi(2,mini(9,seats))
 if department=="Executive":stations=mini(stations,3)
 elif department=="Products":stations=mini(stations,5)
 elif department=="Technology":stations=mini(stations,6)
 for i in range(stations):
  var x:float=-4.3+float(i%2)*3.3
  var z:float=-2.5+float(int(i/2))*2.6
  part(floor_root,Vector3(x,0.9,z),Vector3(2.25,0.14,0.78),desk_material)
  part(floor_root,Vector3(x,0.47,z),Vector3(0.13,0.85,0.45),wood)
  part(floor_root,Vector3(x,1.32,z-0.20),Vector3(0.75,0.68,0.10),screen_material)
  part(floor_root,Vector3(x,1.00,z+0.9),Vector3(0.74,0.12,0.60),desk_material)
  var worker=Node3D.new()
  floor_root.add_child(worker)
  worker.position=Vector3(x,0,z+0.97)
  part(worker,Vector3(0,0.83,0),Vector3(0.5,0.9,0.44),mat(["#445d69","#8a7165","#779087"][i%3]))
  part(worker,Vector3(0,1.39,0),Vector3(0.38,0.38,0.38),mat("#c29b80"))
  employees.append(worker)
 for j in range(2):
  var px=5.3 if j==0 else -5.5
  part(floor_root,Vector3(px,0.5,3.6),Vector3(0.56,1.0,0.55),wood)
  part(floor_root,Vector3(px,1.35,3.6),Vector3(1.1,1.4,1.0),plant)
 if department=="Executive":
  part(floor_root,Vector3(2.9,0.83,-1.3),Vector3(3.2,0.22,4.9),wood)
  for chair in range(6):
   var px:float=1.1 if chair%2==0 else 4.7
   var pz:float=-3.0+float(int(chair/2))*1.7
   part(floor_root,Vector3(px,0.68,pz),Vector3(0.70,0.16,0.68),desk_material)
   part(floor_root,Vector3(px,1.02,pz+0.35),Vector3(0.70,0.73,0.13),desk_material)
  part(floor_root,Vector3(3.8,2.8,-4.78),Vector3(2.4,1.2,0.11),screen_material)
 elif department=="Finance":
  for terminal in range(3):
   part(floor_root,Vector3(2.1+float(terminal)*1.25,2.8,-4.82),Vector3(1.0,0.85,0.1),screen_material)
 elif department=="Products":
  part(floor_root,Vector3(3.7,0.92,1.9),Vector3(4.3,0.17,2.1),desk_material)
  for cup in range(5):
   part(floor_root,Vector3(2.0+float(cup)*0.77,1.10,1.75),Vector3(0.22,0.31,0.22),mat("#f2e9d5"))
  part(floor_root,Vector3(3.8,2.2,-4.77),Vector3(2.5,1.5,0.14),screen_material)
 elif department=="Technology":
  for k in range(3):
   var tz:float=-3.1+float(k)*2.1
   part(floor_root,Vector3(5.2,1.75,tz),Vector3(1.25,3.5,1.25),wood)
   for light in range(3):
    part(floor_root,Vector3(5.86,0.90+float(light)*0.8,tz),Vector3(0.08,0.10,0.8),screen_material)

func _process(delta:float)->void:
 t+=delta
 for i in range(employees.size()):
  var worker:Node3D=employees[i]
  worker.rotation.y=sin(t*0.8+float(i))*0.09
