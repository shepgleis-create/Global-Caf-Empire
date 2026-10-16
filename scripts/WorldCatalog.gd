extends RefCounted
class_name CafeWorldCatalog

# Original city simulation profiles are data-driven. Every city has its own
# persistent 16-parcel commercial market and 3D environment profile.
const CSV_PATH = "res://data/world_cities.txt"
const DISTRICTS = ["Central Promenade","Station Quarter","Market Street","Foundry Square",
"Garden Walk","Exchange Plaza","Canal Court","University Gate","Terrace Row",
"Grand Boulevard","Waterfront","Gallery Lane","Old Town","South Arcade",
"Merchant Square","West Quay"]

static func profiles() -> Array:
    var cities: Array = []
    var f := FileAccess.open(CSV_PATH,FileAccess.READ)
    if f == null:
        push_error("World city manifest is missing.")
        return cities
    f.get_line()
    while not f.eof_reached():
        var line := f.get_line().strip_edges()
        if line.is_empty(): continue
        var a := line.split("|")
        if a.size() != 6: continue
        cities.append({"id":a[0],"name":a[1],"country":a[2],"style":a[3],"cost":float(a[4]),"temperature":int(a[5])})
    return cities

static func profile(city_id:String) -> Dictionary:
    for p in profiles():
        if p["id"] == city_id:
            return p
    return {}

static func build_city(city_id:String, seed_value:int, existing_lots:Array=[]) -> Dictionary:
    var p:=profile(city_id)
    if p.is_empty(): return {}
    var lots:=existing_lots
    if lots.is_empty():
        var rng:=RandomNumberGenerator.new()
        rng.seed=abs(seed_value*12397+city_id.hash())
        for i in range(16):
            var traffic:=rng.randi_range(8200,20000)
            var rent:=roundi(rng.randi_range(48000,118000)*float(p["cost"]))
            lots.append({"id":"%s-%02d" % [city_id,i+1],"name":DISTRICTS[i],
                "x":i%4,"y":int(i/4),"rent_cents":rent,"footfall":traffic,
                "sqft":rng.randi_range(670,2200),
                "status":"vacant" if rng.randf()<0.62 else "occupied","store_id":""})
    return {"id":city_id,"name":p["name"],"region":p["country"],
        "style":p["style"],"climate_temp":p["temperature"],"cost_index":p["cost"],
        "reference_latte_cents":roundi(575.0*pow(float(p["cost"]),0.35)),
        "economy_index":100,"lots":lots}

static func build_all(seed_value:int, chicago:Dictionary) -> Dictionary:
    var result:Dictionary={}
    for p in profiles():
        var id:String=p["id"]
        result[id]=build_city(id,seed_value,chicago["lots"] if id=="CHI" else [])
    return result
