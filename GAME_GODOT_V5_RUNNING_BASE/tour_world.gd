extends Node3D
# Photographic environment adapter. Quest state and puzzle rules stay in main.gd.
var game: Node3D
var yaw := -PI/2.0
var pitch := -.06
var look_drag := false
var face_materials: Array[ShaderMaterial] = []
var focus: String = ""
var targets: Dictionary = {}
var caption: Label
var scene_data: Dictionary
var scenes: Array
var current_scene := "agora"
var scene_props: Dictionary = {}
var navigation_nodes: Array[Node3D] = []
var gallery_board: Node3D
var scene_caption: String = ""
var camera_origin := Vector3(0,1.65,0)
var start_player := Vector3(1.8,1,-.8)
var cube_root: Node3D

func build(g: Node3D) -> void:
    game = g
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/tour/manifest.json"))
    scenes = manifest.scenes
    scene_data = scenes[0]
    game.COIN_SPOTS = [Vector3(2.4,.8,-1.5),Vector3(-2.6,.8,-1.8),Vector3(0,.8,-2.6)]
    game.ALTAR_SPOT = Vector3(0,0,-3.5)
    game.VAULT_SPOT = Vector3(3.2,0,2.2)
    game.QUEEN_SPOT = Vector3(2.5,0,2.7)
    game.vault_entry_offset = Vector3(0,1,0)
    game.map_pickup_offset = Vector3(-1.2,1,0)
    var env := WorldEnvironment.new()
    add_child(env)
    game.world_environment = Environment.new()
    env.environment = game.world_environment
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    game.world_environment.sky = sky
    game.world_environment.background_mode = Environment.BG_SKY
    game.world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    game.world_environment.ambient_light_color = Color("b5c7d0")
    game.world_environment.ambient_light_energy = .75
    game.sunlight = DirectionalLight3D.new()
    game.add_child(game.sunlight)
    game.sunlight.rotation_degrees = Vector3(-43,-25,0)
    game.sunlight.light_energy = .8
    game.sunlight.shadow_enabled = true
    _cube()
    # Invisible physical floor; the visible paving belongs to the photograph.
    var floor_body := StaticBody3D.new()
    add_child(floor_body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(12,.2,12)
    collision.shape = shape
    floor_body.add_child(collision)
    floor_body.position.y = -.1
    for i in range(3):
        var coin := Node3D.new()
        game.add_child(coin)
        coin.position = game.COIN_SPOTS[i]
        coin.scale = Vector3.ONE*.28
        game._cylinder(coin,Vector3.ZERO,.74,.2,Color("e9bb50"))
        var beetle: Node3D = game._sphere(coin,Vector3(0,.28,0),.4,Color("277c97"))
        beetle.scale = Vector3(1,.6,1.35)
        game._ring(coin,Vector3(0,.1,0),.77,Color("ffd77a"),true)
        game.coin_nodes.append(coin)
        targets["coin%d" % i] = coin
        _shadow(coin,Vector3(0,-2.65,0),2.3)
    var altar := Node3D.new()
    game.add_child(altar)
    altar.position = game.ALTAR_SPOT
    game._cylinder(altar,Vector3(0,.3,0),.55,.6,Color("aa8652"))
    game._cylinder(altar,Vector3(0,.65,0),.65,.13,Color("d9ba71"))
    game._ankh(altar,Vector3(0,1.0,0),.2)
    targets.altar = altar
    scene_props.altar = altar
    _shadow(altar,Vector3(0,.012,0),.8)
    var magic: Node3D = game._magic_decal(self,game.ALTAR_SPOT+Vector3(0,.02,0),2.4)
    game.past_objects.append(magic)
    scene_props.magic = magic
    game.vault_door = game._box(self,game.VAULT_SPOT+Vector3(0,.35,0),Vector3(.65,.7,.45),Color("8b673b"))
    game._box(game.vault_door,Vector3(0,.37,0),Vector3(.7,.08,.5),Color("b99c56"))
    game._ring(game.vault_door,Vector3(0,0,-.18),.2,Color("efc86a"),true)
    targets.vault = game.vault_door
    var map_marker: Node3D = game._cylinder(self,game.VAULT_SPOT+Vector3(-1.2,.45,0),.25,.9,Color("aa8652"))
    game._box(map_marker,Vector3(0,.51,0),Vector3(.42,.05,.33),Color("dfc88c"))
    targets.map = map_marker
    game.queen = Node3D.new()
    game.add_child(game.queen)
    game.queen.position = game.QUEEN_SPOT
    game._royal_figure(game.queen,false)
    game.queen.scale = Vector3.ONE*.5
    targets.queen = game.queen
    _shadow(game.queen,Vector3(0,.02,0),.8)
    game.queen_cage = Node3D.new()
    game.add_child(game.queen_cage)
    game.queen_cage.position = game.QUEEN_SPOT
    for x in [-.5,.5]:
        for z in [-.5,.5]:
            game._cylinder(game.queen_cage,Vector3(x,1,z),.025,2.0,Color("659bc6"))
    game._ring(game.queen_cage,Vector3(0,2,0),.72,Color("81badf"),true)
    game.present_objects.append(game.queen_cage)
    game.bridge = Node3D.new()
    game.add_child(game.bridge)
    game.bridge.position = Vector3(0,0,2.0)
    for i in range(5):
        game._box(game.bridge,Vector3(i*.27,.035,0),Vector3(.24,.05,.5),Color("d6b268"))
    game.past_objects.append(game.bridge)
    game._create_reversal_art()
    if not game.rune_nodes.is_empty():
        game.rune_nodes[0].get_parent().scale = Vector3.ONE*.1
    for x in [-.9,.9]:
        var obelisk: Node3D = game._obelisk(self,game.ALTAR_SPOT+Vector3(x,0,0),5.0)
        obelisk.scale = Vector3.ONE*.18
        game.past_objects.append(obelisk)
    # Existing reversal art uses campus-sized obelisks; retain only nearby particles.
    game.magic_particles.position = game.ALTAR_SPOT+Vector3(0,.6,0)
    game.magic_particles.emission_sphere_radius = .7
    game.magic_particles.amount = 35
    _make_gallery()
    _create_navigation()
    sync_scene_visibility()

func _cube() -> void:
    cube_root = Node3D.new()
    add_child(cube_root)
    cube_root.position = camera_origin
    var shader := Shader.new()
    shader.code = "shader_type spatial; render_mode unshaded,cull_disabled,fog_disabled; uniform sampler2D photo : source_color,filter_linear_mipmap,repeat_disable; uniform float ancient_mix = 0.0; void fragment(){vec3 c=texture(photo,UV).rgb;ALBEDO=c*mix(vec3(.94,.99,1.06),vec3(1.13,1.045,.84),ancient_mix);}"
    var l := 40.0
    var points := {
        "front":[Vector3(-l,l,-l),Vector3(l,l,-l),Vector3(l,-l,-l),Vector3(-l,-l,-l)],
        "right":[Vector3(l,l,-l),Vector3(l,l,l),Vector3(l,-l,l),Vector3(l,-l,-l)],
        "back":[Vector3(l,l,l),Vector3(-l,l,l),Vector3(-l,-l,l),Vector3(l,-l,l)],
        "left":[Vector3(-l,l,l),Vector3(-l,l,-l),Vector3(-l,-l,-l),Vector3(-l,-l,l)],
        "top":[Vector3(-l,l,l),Vector3(l,l,l),Vector3(l,l,-l),Vector3(-l,l,-l)],
        "bottom":[Vector3(-l,-l,-l),Vector3(l,-l,-l),Vector3(l,-l,l),Vector3(-l,-l,l)]}
    for face in points:
        var arrays := []
        arrays.resize(Mesh.ARRAY_MAX)
        arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(points[face])
        arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
        arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
        var mesh := ArrayMesh.new()
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
        var mi := MeshInstance3D.new()
        mi.name = "TourPhoto_"+face
        mi.set_meta("face",face)
        mi.mesh = mesh
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var mat := ShaderMaterial.new()
        mat.shader = shader
        mat.set_shader_parameter("photo",load(scene_data.texture_folder+"/"+face+".png"))
        mi.material_override = mat
        face_materials.append(mat)
        cube_root.add_child(mi)

func _shadow(parent: Node3D, at: Vector3, size: float) -> void:
    var mi := MeshInstance3D.new()
    parent.add_child(mi)
    mi.position = at
    var plane := PlaneMesh.new()
    plane.size = Vector2(size,size*.7)
    mi.mesh = plane
    var shader := Shader.new()
    shader.code = "shader_type spatial;render_mode unshaded,cull_disabled,depth_draw_never;void fragment(){float a=1.0-smoothstep(.05,.5,length(UV-.5));ALBEDO=vec3(.04,.035,.03);ALPHA=a*.28;}"
    var mat := ShaderMaterial.new()
    mat.shader = shader
    mi.material_override = mat

func create_hud() -> void:
    game.hud_root = CanvasLayer.new()
    game.add_child(game.hud_root)
    var outer := Control.new()
    game.hud_root.add_child(outer)
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var reticle := _label(outer,Vector2(634,344),26)
    reticle.text = "·"
    game.status_label = _label(outer,Vector2(20,16),19)
    game.objective_label = _label(outer,Vector2(20,43),17)
    caption = _label(outer,Vector2(20,70),15)
    caption.text = "AGORA CIRCLE  |  Actual Lakehead tour photograph  |  Fixed 360° camera"
    game.hint_label = _label(outer,Vector2(20,650),19)
    game.message_label = _label(outer,Vector2(170,110),18)
    var controls := _label(outer,Vector2(20,684),15)
    controls.text = "Right-drag / arrows: look   WASD: move avatar   E: interact   R: reverse   M: map   Blue hotspots / E: travel   F1: HUD"
    game.map_panel = PanelContainer.new()
    outer.add_child(game.map_panel)
    game.map_panel.position = Vector2(380,230)
    var text := Label.new()
    text.text = "THE ANCIENT MAP\n\nNefertiti waits behind the blue temporal prison.\nTravel to LAKE TAMBLYN through the blue hotspots.\nEnter Ancient Echo with R, approach her, and press E.\n\nM / ESC: close"
    text.add_theme_font_size_override("font_size",20)
    game.map_panel.add_child(text)
    game.map_panel.hide()
    game.win_panel = PanelContainer.new()
    outer.add_child(game.win_panel)
    game.win_panel.position = Vector2(300,150)
    var victory := TextureRect.new()
    victory.texture = load("res://assets/victory.png")
    victory.custom_minimum_size = Vector2(680,360)
    victory.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    game.win_panel.add_child(victory)
    game.win_panel.hide()
    game.help_panel = PanelContainer.new()
    outer.add_child(game.help_panel)
    game.help_panel.hide()

func _label(parent: Node, at: Vector2, size: int) -> Label:
    var label := Label.new()
    parent.add_child(label)
    label.position = at
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_shadow_color",Color("101820"))
    label.add_theme_constant_override("shadow_offset_x",1)
    label.add_theme_constant_override("shadow_offset_y",2)
    return label

func setup_player() -> void:
    game.player.position = start_player
    game.player_model.scale = Vector3.ONE*.5
    # The old floating GUARDIAN label is inappropriate at photographic human scale.
    for child in game.player_model.get_children():
        if child is Label3D:
            child.hide()
    for child in game.player.get_children():
        if child is CollisionShape3D:
            child.shape.radius = .28
            child.shape.height = 1.75
            child.position.y = -.125
    _shadow(game.player,Vector3(0,-.98,0),.65)

func update(delta: float) -> void:
    if Input.is_key_pressed(KEY_LEFT): yaw += delta*1.2
    if Input.is_key_pressed(KEY_RIGHT): yaw -= delta*1.2
    if Input.is_key_pressed(KEY_UP): pitch = minf(pitch+delta*.8,1.2)
    if Input.is_key_pressed(KEY_DOWN): pitch = maxf(pitch-delta*.8,-1.2)
    game.cam.position = camera_origin
    game.cam.rotation = Vector3(pitch,yaw,0)
    game.cam.fov = 78
    sync_scene_visibility()
    caption.text = scene_data.name+"  |  Actual Lakehead tour photograph  |  Fixed 360° camera"
    focus = ""
    var best := .97
    var forward: Vector3 = -game.cam.global_basis.z
    for key in targets:
        var node: Node3D = targets[key]
        if not _active(key): continue
        var point := node.global_position+Vector3(0,.35 if key.begins_with("travel:") else (.65 if key in ["altar","vault","queen"] else 0),0)
        var score := forward.dot((point-camera_origin).normalized())
        if score > best:
            best = score
            focus = key
    if focus != "":
        game.hint_label.text = "E  /  "+_target_title(focus)
    else:
        game.hint_label.text = "Look at a glowing relic or shrine, approach it, then press E."
    if game.altar_started:
        game.hint_label.text = "ALTAR: 3 → 2 → 1   |   %d / 3" % game.altar_step
    game.objective_label.text = _objective()

func _active(key: String) -> bool:
    if key.begins_with("travel:"): return true
    if key.begins_with("coin"):
        var i := int(key.substr(4))
        return current_scene == ["agora","corridor","atac"][i] and not game.coins[i] and game.ancient
    if key == "altar": return current_scene == "agora" and not game.has_key
    if key == "vault": return current_scene == "atac" and not game.vault_open
    if key == "map": return current_scene == "atac" and game.vault_open and not game.map_found
    return current_scene == "lake" and not game.finished

func _target_title(key: String) -> String:
    if key.begins_with("travel:"): return "Travel to "+_scene_name(key.substr(7))
    if key.begins_with("coin"): return "Collect sacred scarab"
    return {"altar":"Agora shrine","vault":"Unlock map chest","map":"Read ancient map","queen":"Rescue Nefertiti"}.get(key,key)

func _objective() -> String:
    if game.finished: return "Nefertiti rescued. ENTER to play again."
    if not (game.coins[0] and game.coins[1] and game.coins[2]):
        var names := ["Agora Circle","Campus Corridor (library approach)","ATAC"]
        for i in range(3):
            if not game.coins[i]:
                return "SCARAB %d / %s  —  R reveals it; blue hotspots connect locations." % [i+1,names[i]]
    if not game.has_key: return "Return to the Agora shrine. Place scarabs in reverse order: 3, 2, 1."
    if not game.vault_open: return "ATAC: use the golden key on the wooden map chest."
    if not game.map_found: return "ATAC: read the parchment beside the unlocked chest."
    return "LAKE TAMBLYN: reverse Nefertiti's blue prison, approach, and press E."

func can_target(key: String) -> bool:
    return focus == key

func move_player(delta: float) -> void:
    if game.finished or game.is_map_open or game.altar_started: return
    var axis := Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_S))-float(Input.is_key_pressed(KEY_W))).normalized()
    var direction := Basis(Vector3.UP,yaw)*Vector3(axis.x,0,axis.y)
    game.player.velocity = direction*1.6
    game.player.move_and_slide()
    var flat := Vector2(game.player.position.x,game.player.position.z)
    if flat.length()>3.8:
        flat=flat.normalized()*3.8
        game.player.position.x=flat.x
        game.player.position.z=flat.y
    if direction.length()>.1:
        game.player_model.rotation.y = lerp_angle(game.player_model.rotation.y,atan2(direction.x,direction.z),delta*8)

func handle_input(event: InputEvent) -> bool:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if game.is_map_open or game.finished or game.altar_started: return false
        for key in targets:
            if not key.begins_with("travel:"): continue
            var node: Node3D = targets[key]
            var at := node.global_position+Vector3(0,.3,0)
            if not game.cam.is_position_behind(at) and game.cam.unproject_position(at).distance_to(event.position)<45:
                set_scene(key.substr(7))
                return true
    if event is InputEventKey and event.keycode == KEY_ESCAPE and look_drag:
        look_drag = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return true
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        look_drag = event.pressed
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if look_drag else Input.MOUSE_MODE_VISIBLE
        return true
    if event is InputEventMouseMotion and look_drag:
        yaw -= event.relative.x*.0035
        pitch = clampf(pitch-event.relative.y*.0035,-1.2,1.2)
        return true
    return event is InputEventKey and event.keycode in [KEY_V,KEY_C,KEY_H]

func set_reversal_tint(value: float) -> void:
    for mat in face_materials:
        mat.set_shader_parameter("ancient_mix",value)

func _scene_name(id: String) -> String:
    for scene in scenes:
        if scene.id == id: return scene.name
    return id

func _create_navigation() -> void:
    for node in navigation_nodes:
        node.queue_free()
    navigation_nodes.clear()
    for key in targets.keys():
        if key.begins_with("travel:"):
            targets.erase(key)
    var index := 0
    for i in range(scenes.size()):
        if scenes[i].id == current_scene: index=i
    var destinations := [scenes[posmod(index-1,scenes.size())],scenes[(index+1)%scenes.size()]]
    for i in range(2):
        var dest: Dictionary = destinations[i]
        var marker := Node3D.new()
        add_child(marker)
        marker.position = Basis(Vector3.UP,yaw)*Vector3(-1.9 if i==0 else 1.9,0,-3.0)
        game._ring(marker,Vector3(0,.025,0),.37,Color("5acbe3"),true)
        game._sphere(marker,Vector3(0,.35,0),.11,Color("73d4e4"))
        var label: Label3D = game._sign(marker,{"agora":"AGORA", "corridor":"LIBRARY APPROACH", "atac":"ATAC", "lake":"LAKE TAMBLYN"}.get(dest.id,dest.name)+"\n[E] / CLICK",Vector3(0,.83,0),Color("acf1ff"),23)
        label.pixel_size=.005
        var key := "travel:"+str(dest.id)
        targets[key]=marker
        navigation_nodes.append(marker)

func set_scene(id: String) -> void:
    if game.altar_started or game.is_map_open or game.finished: return
    var found := false
    for scene in scenes:
        if scene.id == id:
            scene_data=scene
            found=true
            break
    if not found: return
    current_scene=id
    yaw=deg_to_rad(float(scene_data.yaw_degrees))
    pitch=-.05
    for mi in cube_root.get_children():
        var face: String=mi.get_meta("face")
        mi.material_override.set_shader_parameter("photo",load(scene_data.texture_folder+"/"+face+".png"))
    game.player.position=Basis(Vector3.UP,yaw)*Vector3(.35,1,-1.6)
    _create_navigation()
    sync_scene_visibility()
    game._flash(scene_data.name+" — verified tour camera location",2)
    update(0)

func try_travel() -> bool:
    if focus.begins_with("travel:"):
        set_scene(focus.substr(7))
        return true
    return false

func sync_scene_visibility() -> void:
    for i in range(3):
        game.coin_nodes[i].visible = current_scene == ["agora","corridor","atac"][i] and game.ancient and not game.coins[i]
    scene_props.altar.visible = current_scene == "agora"
    game.vault_door.visible = current_scene == "atac" and not game.vault_open
    targets.map.visible = current_scene == "atac" and game.vault_open and not game.map_found
    game.queen.visible = current_scene == "lake"
    game.queen_cage.visible = current_scene == "lake" and not game.ancient
    for prop in game.past_objects:
        prop.visible = game.ancient and current_scene == ("lake" if prop == game.bridge else "agora")
    game.magic_particles.emitting = game.ancient and current_scene == "agora"
    game.magic_particles.visible = current_scene == "agora"
    if gallery_board != null: gallery_board.visible = current_scene == "corridor"

func _make_gallery() -> void:
    gallery_board=Node3D.new()
    add_child(gallery_board)
    gallery_board.position=Vector3(1.7,0,-3.0)
    var stand: Node3D=game._box(gallery_board,Vector3(0,.65,0),Vector3(.06,1.3,.06),Color("3e535b"))
    var photo:=MeshInstance3D.new()
    gallery_board.add_child(photo)
    var mesh:=QuadMesh.new()
    mesh.size=Vector2(1.0,.67)
    photo.mesh=mesh
    photo.position=Vector3(0,1.1,0)
    var mat:=StandardMaterial3D.new()
    mat.albedo_texture=load("res://assets/tour/library_gallery.jpg")
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    photo.material_override=mat
    var label: Label3D=game._sign(gallery_board,"PATERSON LIBRARY\nOfficial tour gallery photograph",Vector3(0,1.63,0),Color.WHITE,19)
    label.pixel_size=.006
