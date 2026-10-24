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
const LOCATION_NAMES = {"agora":"Agora Circle", "corridor":"Library Approach", "atac":"ATAC", "lake":"Lake Tamblyn"}
const LOCATION_PAGES = {"agora":13,"corridor":18,"atac":20,"lake":11}
const COIN_LOCATIONS = ["agora","corridor","atac"]
var hotspot: Button
var nav_buttons: Dictionary = {}
var reality_label: Label
var controls_label: Label
var opening_label: Label
var puzzle_panel: PanelContainer
var puzzle_progress: Label
var icon_flight: TextureRect
var victory_busy := false
var look_tween: Tween
var intro_time := 0.0
var hovered_key := ""
var ui_root: Control
var map_diagram: Control
var transition_flash: ColorRect
var mission_location := "agora"
var mission_key := "coin0"
var previous_phase := ""
var altar_symbols: Array[Label3D] = []
var portrait_texture: Texture2D
var portrait_pivots: Array[Node3D] = []
var hero_clock := 0.0
var flash_tween: Tween
var temporal_lock: Node3D
var broken_passage: Node3D
var chest_lid: Node3D

func build(g: Node3D) -> void:
    game = g
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/tour/manifest.json"))
    scenes = manifest.scenes
    for scene in scenes:
        assert(scene.verified and LOCATION_PAGES.get(scene.id, -1) == int(scene.page_id), "Unverified tour location")
    scene_data = scenes[0]
    game.COIN_SPOTS = [Vector3(2.5,1.0,-.2),Vector3(-1.9,1.0,-2.6),Vector3(.6,1.0,-2.6)]
    game.ALTAR_SPOT = Vector3(2.7,0,-.8)
    game.VAULT_SPOT = Vector3(-1.5,0,-2.4)
    game.QUEEN_SPOT = Vector3(-1.6,0,-2.8)
    game.vault_entry_offset = Vector3(0,1,0)
    game.map_pickup_offset = Vector3(1.2,1,0)
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
    for i in range(3):
        var symbol: Label3D = game._sign(altar,str(i+1),Vector3((i-1)*.32,.83,.18),Color("ffdc88"),28)
        symbol.pixel_size = .005
        altar_symbols.append(symbol)
    targets.altar = altar
    scene_props.altar = altar
    _shadow(altar,Vector3(0,.012,0),.8)
    var magic: Node3D = game._magic_decal(self,game.ALTAR_SPOT+Vector3(0,.02,0),2.4)
    game.past_objects.append(magic)
    scene_props.magic = magic
    game.vault_door = game._box(self,game.VAULT_SPOT+Vector3(0,.28,0),Vector3(.65,.5,.45),Color("8b673b"))
    chest_lid=Node3D.new()
    game.vault_door.add_child(chest_lid)
    chest_lid.position=Vector3(0,.29,-.22)
    game._box(chest_lid,Vector3(0,0,.22),Vector3(.7,.08,.5),Color("8b673b"))
    for x in [-.24,.24]:
        game._box(game.vault_door,Vector3(x,0,.24),Vector3(.055,.50,.035),Color("c6a55d"))
        game._box(chest_lid,Vector3(x,.05,.22),Vector3(.055,.025,.5),Color("c6a55d"))
    game._box(game.vault_door,Vector3(0,.06,.25),Vector3(.13,.15,.04),Color("c6a55d"))
    game._sphere(game.vault_door,Vector3(0,.06,.28),.03,Color("2d454e"))
    targets.vault = game.vault_door
    var map_marker: Node3D = game._cylinder(self,game.VAULT_SPOT+Vector3(1.2,.45,0),.25,.9,Color("aa8652"))
    game._box(map_marker,Vector3(0,.51,0),Vector3(.42,.05,.33),Color("dfc88c"))
    targets.map = map_marker
    game.queen = Node3D.new()
    game.add_child(game.queen)
    game.queen.position = game.QUEEN_SPOT
    game.queen.position.y = -.01
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
    game.bridge.position = Vector3(-2.6,.10,-4.2)
    for i in range(5):
        game._box(game.bridge,Vector3(i*.27,.035,0),Vector3(.24,.05,.5),Color("d6b268"))
    for x in [-.10,1.18]:
        game._box(game.bridge,Vector3(x,.65,0),Vector3(.055,1.2,.055),Color("d6b268"))
    game._box(game.bridge,Vector3(.54,1.24,0),Vector3(1.4,.06,.08),Color("d6b268"))
    game._ankh(game.bridge,Vector3(.54,1.47,0),.17)
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
    game.magic_particles.scale_amount_min=.008
    game.magic_particles.scale_amount_max=.025
    _make_reversal_puzzles()
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


func _style(color: Color, border: Color = Color("345265"), width := 1) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(10)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

func _label(parent: Node, at: Vector2, size: int, text := "") -> Label:
    var label := Label.new()
    parent.add_child(label)
    label.position = at
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color("edf3f3"))
    label.add_theme_color_override("font_shadow_color",Color("08121e"))
    label.add_theme_constant_override("shadow_offset_y",2)
    return label

func _button(parent: Node, key: String, text: String, at: Vector2, size: Vector2, icon := "") -> Button:
    var button := Button.new()
    button.name = key
    parent.add_child(button)
    button.text = text
    button.position = at
    button.size = size
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size",16)
    button.add_theme_stylebox_override("normal",_style(Color("102736eb")))
    button.add_theme_stylebox_override("hover",_style(Color("234451f5"),Color("f0cd79"),2))
    button.add_theme_stylebox_override("pressed",_style(Color("486057"),Color("f5d283"),2))
    button.add_theme_stylebox_override("disabled",_style(Color("101f2bcc"),Color("334857")))
    if icon != "":
        button.icon = load("res://assets/ui/"+icon+".svg")
        button.add_theme_constant_override("icon_max_width",28)
        button.expand_icon = true
    return button

func create_hud() -> void:
    game.hud_root = CanvasLayer.new()
    game.add_child(game.hud_root)
    ui_root = Control.new()
    game.hud_root.add_child(ui_root)
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var mission_panel := Panel.new()
    ui_root.add_child(mission_panel)
    mission_panel.position = Vector2(20,18)
    mission_panel.size = Vector2(750,110)
    mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mission_panel.add_theme_stylebox_override("panel",_style(Color("091d2aeb")))
    game.objective_label = _label(mission_panel,Vector2(120,12),23)
    game.objective_label.size = Vector2(610,55)
    game.objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    game.status_label = _label(mission_panel,Vector2(120,75),15)
    reality_label = _label(ui_root,Vector2(1030,62),18)
    reality_label.size = Vector2(230,34)
    reality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    caption = _label(ui_root,Vector2(820,24),17)
    caption.size = Vector2(440,30)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    game.hint_label = _label(ui_root,Vector2(375,539),18)
    game.hint_label.size = Vector2(530,40)
    game.hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game.message_label = _label(ui_root,Vector2(270,145),18)
    game.message_label.size = Vector2(740,45)
    game.message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game.message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var reticle := _label(ui_root,Vector2(634,346),24,"·")
    reticle.name = "Reticle"
    hotspot = _button(ui_root,"QuestHotspot","",Vector2(530,360),Vector2(220,72),"scarab")
    hotspot.mouse_entered.connect(func(): hovered_key = mission_key)
    hotspot.mouse_exited.connect(func(): hovered_key = "")
    hotspot.pressed.connect(func(): activate(mission_key))
    _label(ui_root,Vector2(24,590),12,"CAMPUS DESTINATIONS")
    var ids := ["agora","corridor","atac","lake"]
    for i in range(ids.size()):
        var id: String = ids[i]
        var button := _button(ui_root,"Travel_"+id,LOCATION_NAMES[id],Vector2(20+i*246,612),Vector2(234,64),"nav")
        nav_buttons[id] = button
        button.pressed.connect(func(): activate("travel:"+id))
        button.mouse_entered.connect(func(): hovered_key = "travel:"+id)
        button.mouse_exited.connect(func(): hovered_key = "")
    var map_button := _button(ui_root,"OpenMap","MAP — LOCKED",Vector2(1004,612),Vector2(256,64),"map")
    map_button.pressed.connect(func(): if game.map_found: game._show_map(true))
    nav_buttons["map"] = map_button
    controls_label = _label(ui_root,Vector2(24,691),14,"Right-drag / arrows: look    Click a hotspot or press E    R: reverse reality")
    game.help_panel = PanelContainer.new()
    ui_root.add_child(game.help_panel)
    game.help_panel.hide()
    _make_guardian_portrait(mission_panel)
    _make_puzzle()
    _make_map()
    _make_victory()
    opening_label = _label(ui_root,Vector2(270,204),24,"SPHINX REVERSAL  /  LAKEHEAD RESCUE")
    opening_label.size = Vector2(740,76)
    opening_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    transition_flash=ColorRect.new()
    ui_root.add_child(transition_flash)
    transition_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    transition_flash.color=Color(0,0,0,0)
    intro_time = 3.0
    game.player.show()
    game.player.position=Basis(Vector3.UP,yaw)*Vector3(.65,1,-2.8)
    game.player_model.rotation.y=yaw
    _shadow(game.player,Vector3(0,-.99,0),.7)
    refresh_hud()

func _make_puzzle() -> void:
    puzzle_panel = PanelContainer.new()
    puzzle_panel.name = "AltarPuzzle"
    ui_root.add_child(puzzle_panel)
    puzzle_panel.position = Vector2(370,245)
    puzzle_panel.custom_minimum_size = Vector2(540,245)
    puzzle_panel.add_theme_stylebox_override("panel",_style(Color("0b1c2af5"),Color("c2a96e"),2))
    var content := Control.new()
    content.custom_minimum_size = Vector2(510,220)
    puzzle_panel.add_child(content)
    _label(content,Vector2(10,0),22,"Restore the scarabs: 3 → 2 → 1")
    puzzle_progress = _label(content,Vector2(10,40),16)
    for i in range(3):
        var number := i+1
        var button := _button(content,"Altar_"+str(number),str(number),Vector2(15+i*165,85),Vector2(148,64),"scarab")
        button.pressed.connect(func():
            if game.altar_started:
                game._try_altar_number(number)
                refresh_hud())
    _label(content,Vector2(16,175),14,"Click a symbol or use number keys. ESC: step back.")
    puzzle_panel.hide()

func _make_map() -> void:
    game.map_panel = PanelContainer.new()
    game.map_panel.name = "CampusMap"
    ui_root.add_child(game.map_panel)
    game.map_panel.position = Vector2(280,175)
    game.map_panel.custom_minimum_size = Vector2(720,380)
    game.map_panel.add_theme_stylebox_override("panel",_style(Color("0b1d2af8"),Color("bda776"),2))
    var content := Control.new()
    content.custom_minimum_size = Vector2(690,354)
    game.map_panel.add_child(content)
    _label(content,Vector2(12,0),24,"THE ANCIENT MAP")
    _label(content,Vector2(12,38),16,"Nefertiti is held at Lake Tamblyn. Reverse her temporal prison.")
    map_diagram = preload("res://adventure_map.gd").new()
    content.add_child(map_diagram)
    map_diagram.position = Vector2(14,70)
    map_diagram.size = Vector2(660,212)
    var close := _button(content,"CloseMap","CLOSE  [M / ESC]",Vector2(12,292),Vector2(232,52))
    close.pressed.connect(func(): game._show_map(false))
    var travel := _button(content,"MapTravel_lake","TRAVEL TO LAKE TAMBLYN",Vector2(270,292),Vector2(398,52),"nav")
    travel.pressed.connect(func():
        game._show_map(false)
        set_scene("lake"))
    game.map_panel.hide()

func _make_victory() -> void:
    game.win_panel = PanelContainer.new()
    game.win_panel.name = "Victory"
    ui_root.add_child(game.win_panel)
    game.win_panel.position = Vector2(330,185)
    game.win_panel.custom_minimum_size = Vector2(620,355)
    game.win_panel.add_theme_stylebox_override("panel",_style(Color("0b1f2af5"),Color("f2cd78"),2))
    var content := Control.new()
    content.custom_minimum_size = Vector2(590,330)
    game.win_panel.add_child(content)
    _label(content,Vector2(22,20),16,"SPHINX REVERSAL  /  MISSION COMPLETE")
    var portrait:=TextureRect.new()
    content.add_child(portrait)
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.texture=portrait_texture
    portrait.position=Vector2(22,70)
    portrait.size=Vector2(150,150)
    portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
    _label(content,Vector2(188,76),27,"NEFERTITI IS FREE")
    _label(content,Vector2(188,125),17,"Three scarabs restored.\nThe curse is reversed.\nYou brought the Queen through time.")
    var restart := _button(content,"RestartGame","PLAY AGAIN  [ENTER]",Vector2(22,232),Vector2(546,64),"queen")
    restart.pressed.connect(func(): game.get_tree().reload_current_scene())
    game.win_panel.hide()

func setup_player() -> void:
    game.player.position = Vector3(0,1,0)
    game.player.velocity = Vector3.ZERO
    game.player.hide()
    game.player_model.scale = Vector3.ONE*.5
    for child in game.player_model.get_children():
        if child is Label3D: child.hide()

func move_player(_delta: float) -> void:
    # No fake walking inside a fixed photographic camera location.
    game.player.velocity = Vector3.ZERO

func phase() -> Dictionary:
    for i in range(3):
        if not game.coins[i]:
            return {"key":"coin%d" % i,"location":COIN_LOCATIONS[i],"index":i}
    if not game.has_key: return {"key":"altar","location":"agora"}
    if not game.vault_open: return {"key":"vault","location":"atac"}
    if not game.map_found: return {"key":"map","location":"atac"}
    return {"key":"queen","location":"lake"}

func _objective() -> String:
    if game.finished: return "Nefertiti is free. You reversed the curse."
    var next := phase()
    if current_scene != next.location:
        return "Travel to "+LOCATION_NAMES[next.location]+"."
    match str(next.key):
        "coin0": return "Collect the Agora scarab." if game.ancient else "Press R to reveal the hidden Agora scarab."
        "coin1": return "The passage is restored. Collect the second scarab." if game.ancient else "Press R to restore the Library's echo passage."
        "coin2": return "The time lock is open. Collect the third scarab." if game.ancient else "Press R to open ATAC's temporal lock."
        "altar": return "Enter the symbols in reverse order: 3, 2, 1." if game.altar_started else "Restore the three scarabs at the Agora shrine."
        "vault": return "Use the golden key on the map chest."
        "map": return "Read the ancient map beside the unlocked chest."
        "queen": return "Free Nefertiti. Click her or press E." if game.ancient else "Press R to reverse Nefertiti's prison."
    return "Follow the highlighted destination."

func _target_title(key: String) -> String:
    if key.begins_with("travel:"): return "Travel to "+LOCATION_NAMES.get(key.substr(7),key.substr(7))
    match key:
        "coin0": return "SCARAB I\nCollect" if game.ancient else "HIDDEN SCARAB\nReveal with R"
        "coin1": return "SCARAB II\nCollect" if game.ancient else "BROKEN PASSAGE\nRestore with R"
        "coin2": return "SCARAB III\nCollect" if game.ancient else "TIME LOCK\nOpen with R"
        "altar": return "AGORA SHRINE\nRestore scarabs"
        "vault": return "MAP CHEST\nUse golden key"
        "map": return "ANCIENT MAP\nRead"
        "queen": return "NEFERTITI\nRescue" if game.ancient else "TEMPORAL PRISON\nReverse with R"
    return key

func _icon(key: String) -> String:
    if key.begins_with("coin"): return "scarab"
    return {"altar":"altar","vault":"chest","map":"map","queen":"queen"}.get(key,"nav")

func _active(key: String) -> bool:
    if game.finished or game.is_map_open or game.altar_started or victory_busy: return false
    if key.begins_with("travel:"): return key.substr(7) != current_scene and LOCATION_PAGES.has(key.substr(7))
    var next := phase()
    return key == next.key and current_scene == next.location

func can_target(key: String) -> bool:
    return key == focus and _active(key)

func _target_point(key: String) -> Vector3:
    var node: Node3D = targets[key]
    return node.global_position+Vector3(0,1.05 if key=="queen" else (.65 if key=="altar" else (.5 if key in ["vault","map"] else .15)),0)

func refresh_hud() -> void:
    if not is_instance_valid(hotspot): return
    var next := phase()
    mission_location = next.location
    mission_key = next.key
    game.objective_label.text = _objective()
    var count := 0
    for value in game.coins:
        if value: count += 1
    game.status_label.text = "SACRED SCARABS  %d / 3" % count
    reality_label.text = "ANCIENT ECHO" if game.ancient else "PRESENT DAY"
    reality_label.add_theme_color_override("font_color",Color("f1cd7a") if game.ancient else Color("82d6ee"))
    caption.text = LOCATION_NAMES[current_scene]
    var modal: bool = game.is_map_open or game.altar_started or game.finished or victory_busy
    for id in LOCATION_NAMES:
        var button: Button = nav_buttons[id]
        button.disabled = modal or id == current_scene
        button.text = LOCATION_NAMES[id]+("\nYOU ARE HERE" if id==current_scene else ("\nNEXT DESTINATION" if id==mission_location else ""))
        button.add_theme_stylebox_override("normal",_style(Color("193a40f2"),Color("e7c777"),2) if id==mission_location and id!=current_scene else _style(Color("102736eb")))
    nav_buttons.map.disabled = not game.map_found or game.altar_started or game.finished or victory_busy
    nav_buttons.map.text = "ANCIENT MAP  [M]" if game.map_found else "MAP — LOCKED"
    puzzle_panel.visible = game.altar_started
    puzzle_progress.text = "Restored: %d / 3" % game.altar_step
    for i in range(altar_symbols.size()):
        altar_symbols[i].modulate = Color("f6d378") if game.has_key or i >= 3-game.altar_step else Color("607a88")
    hotspot.visible = not modal and current_scene == mission_location
    hotspot.text = _target_title(mission_key)
    hotspot.icon = load("res://assets/ui/"+_icon(mission_key)+".svg")
    if hotspot.visible:
        var point := _target_point(mission_key)
        var screen: Vector2 = game.cam.unproject_position(point)
        var behind: bool = game.cam.is_position_behind(point)
        if behind:
            var local: Vector3 = game.cam.global_transform.affine_inverse()*point
            screen=Vector2(122 if local.x<0 else 1158,345)
            hotspot.text = "LOOK TOWARD "+("SCARAB" if mission_key.begins_with("coin") else {"altar":"SHRINE","vault":"CHEST","map":"MAP","queen":"NEFERTITI"}.get(mission_key,"TARGET"))+"\nClick or press E"
        hotspot.position = Vector2(clampf(screen.x-110,24,1036),clampf(screen.y-36,190,460))
    if is_instance_valid(map_diagram):
        map_diagram.set("current_location",current_scene)
        map_diagram.queue_redraw()
    if game.finished or victory_busy: game.hint_label.text = ""
    elif game.altar_started: game.hint_label.text = "Click a symbol, or use the 3, 2, 1 keys."
    elif game.is_map_open: game.hint_label.text = ""
    elif focus != "" and _active(focus): game.hint_label.text = "Press E  /  "+_target_title(focus).replace("\n"," — ")
    else: game.hint_label.text = "Click the highlighted hotspot." if hotspot.visible else "Choose the highlighted destination below."

func update(delta: float) -> void:
    hero_clock+=delta
    for i in range(portrait_pivots.size()):
        portrait_pivots[i].rotation.x=sin(hero_clock*1.6+i*PI)*.022
    var modal: bool = game.is_map_open or game.altar_started or game.finished or victory_busy
    if not modal:
        if Input.is_key_pressed(KEY_LEFT): yaw += delta*1.2
        if Input.is_key_pressed(KEY_RIGHT): yaw -= delta*1.2
        if Input.is_key_pressed(KEY_UP): pitch = minf(pitch+delta*.8,1.15)
        if Input.is_key_pressed(KEY_DOWN): pitch = maxf(pitch-delta*.8,-1.15)
    game.cam.position = camera_origin
    game.cam.rotation = Vector3(pitch,yaw,0)
    game.cam.fov = 78
    sync_scene_visibility()
    refresh_hud()
    if not modal:
        focus = ""
        if hovered_key != "" and _active(hovered_key): focus = hovered_key
        elif hotspot.visible and hotspot.get_global_rect().has_point(ui_root.get_global_mouse_position()): focus = mission_key
        elif hotspot.visible and hotspot.get_global_rect().get_center().distance_to(Vector2(640,360))<165: focus = mission_key
    else: focus = ""
    if intro_time>0:
        intro_time=maxf(0,intro_time-delta)
        opening_label.modulate.a=minf(intro_time,1)
        if intro_time==0:
            opening_label.hide()
            if not game.finished: game.player.hide()
    controls_label.text = "ENTER / PLAY AGAIN: restart" if game.finished else ("M / ESC: close map" if game.is_map_open else "Right-drag / arrows: look    Click a hotspot or press E    R: reverse reality")
    var current_phase := str(phase().key)
    if previous_phase != "" and previous_phase != current_phase:
        game.hint_label.modulate = Color("f5d68b")
    previous_phase=current_phase

func activate(key: String) -> void:
    if not _active(key): return
    if key.begins_with("travel:"):
        set_scene(key.substr(7))
        return
    focus = key
    _look_at_target(key)
    if key.begins_with("coin") and not game.ancient:
        game._flash(_objective(),2.2)
        return
    if key=="queen" and not game.ancient:
        game._flash("The blue prison is locked in time. Press R.",2.2)
        return
    var collected_before: int = game.coins.count(true)
    var was_finished: bool = game.finished
    game._interact()
    if game.coins.count(true)>collected_before:
        _collection_feedback()
        game._flash("Scarab %d of 3 secured. %s" % [game.coins.count(true),_objective()],3.3)
    if game.finished and not was_finished: _rescue_sequence()
    refresh_hud()

func _look_at_target(key: String) -> void:
    var direction := (_target_point(key)-camera_origin).normalized()
    var destination := atan2(-direction.x,-direction.z)
    destination = yaw+wrapf(destination-yaw,-PI,PI)
    if is_instance_valid(look_tween): look_tween.kill()
    look_tween=create_tween().set_parallel(true)
    look_tween.tween_property(self,"yaw",destination,.3).set_trans(Tween.TRANS_SINE)
    look_tween.tween_property(self,"pitch",asin(direction.y),.3).set_trans(Tween.TRANS_SINE)

func _collection_feedback() -> void:
    var icon := TextureRect.new()
    ui_root.add_child(icon)
    icon.texture=load("res://assets/ui/scarab.svg")
    icon.position=hotspot.position+Vector2(90,10)
    icon.size=Vector2(44,44)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var tween:=create_tween().set_parallel(true)
    tween.tween_property(icon,"position",Vector2(42,89),.65).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(icon,"scale",Vector2.ONE*.45,.65)
    tween.chain().tween_callback(icon.queue_free)

func _scene_name(id: String) -> String:
    return LOCATION_NAMES.get(id,id)

func _create_navigation() -> void:
    # Locations are verified peers in official Thunder Bay tour 52 / group 51.
    # The selector makes no unsupported claims about direct footpaths or adjacency.
    for id in LOCATION_NAMES:
        assert(LOCATION_PAGES.has(id))

func set_scene(id: String) -> void:
    if not LOCATION_PAGES.has(id) or game.altar_started or game.is_map_open or game.finished or victory_busy: return
    for scene in scenes:
        if scene.id == id:
            scene_data=scene
            break
    current_scene=id
    yaw=deg_to_rad(float(scene_data.yaw_degrees))
    pitch=-.05
    if is_instance_valid(look_tween): look_tween.kill()
    look_drag=false
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    hovered_key=""
    focus=""
    # Each location has its own present-day lock. Earned quest items persist.
    if is_instance_valid(game.reversal_tween): game.reversal_tween.kill()
    if is_instance_valid(game.bridge_tween): game.bridge_tween.kill()
    if is_instance_valid(flash_tween): flash_tween.kill()
    transition_flash.color=Color(0,0,0,0)
    game.ancient=false
    game._set_reversal_color(0)
    intro_time=0
    opening_label.hide()
    game.player.hide()
    for mi in cube_root.get_children():
        var face: String=mi.get_meta("face")
        mi.material_override.set_shader_parameter("photo",load(scene_data.texture_folder+"/"+face+".png"))
    game._update_world_state()
    game._flash(LOCATION_NAMES[id]+" — "+_objective(),2.5)
    refresh_hud()

func try_travel() -> bool:
    if focus.begins_with("travel:"):
        set_scene(focus.substr(7))
        return true
    return false

func handle_input(event: InputEvent) -> bool:
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
        if game.is_map_open or game.altar_started or game.finished: return false
        look_drag=event.pressed
        if is_instance_valid(look_tween): look_tween.kill()
        Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if look_drag else Input.MOUSE_MODE_VISIBLE
        return true
    if event is InputEventMouseMotion and look_drag:
        yaw-=event.relative.x*.0035
        pitch=clampf(pitch-event.relative.y*.0035,-1.15,1.15)
        return true
    if event is InputEventKey:
        if event.keycode==KEY_ESCAPE and look_drag:
            look_drag=false
            Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
            return true
        if event.keycode==KEY_E:
            if event.pressed and not event.echo and focus!="": activate(focus)
            return true
        if event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_V,KEY_C,KEY_H]: return true
    return false

func set_reversal_tint(value: float) -> void:
    for mat in face_materials: mat.set_shader_parameter("ancient_mix",value)
    if temporal_lock!=null:
        temporal_lock.scale=Vector3(1+value*.6,maxf(.025,1-value),1+value*.6)
    if game.queen_cage!=null:
        game.queen_cage.scale.y=maxf(.015,1-value)

func on_reversal() -> void:
    game._flash(_objective(),2.5)
    if is_instance_valid(flash_tween): flash_tween.kill()
    transition_flash.color=Color(.13,.55,.85,.20) if game.ancient else Color(1,.72,.24,.18)
    flash_tween=create_tween()
    flash_tween.tween_property(transition_flash,"color",Color(1,.77,.26,.24) if game.ancient else Color(.2,.58,.8,.2),.22)
    flash_tween.tween_property(transition_flash,"color",Color(0,0,0,0),.58)
    var glyphs:=preload("res://reversal_glyphs.gd").new()
    ui_root.add_child(glyphs)

func sync_scene_visibility() -> void:
    for i in range(3):
        game.coin_nodes[i].visible=current_scene==COIN_LOCATIONS[i] and game.ancient and not game.coins[i]
    scene_props.altar.visible=current_scene=="agora" and game.coins.count(true)==3
    game.vault_door.visible=current_scene=="atac"
    if chest_lid!=null: chest_lid.rotation.x=-1.15 if game.vault_open else 0.0
    targets.map.visible=current_scene=="atac" and game.vault_open and not game.map_found
    game.queen.visible=current_scene=="lake"
    game.queen_cage.visible=current_scene=="lake" and game.reversal_amount<.98 and not game.finished
    if temporal_lock!=null: temporal_lock.visible=current_scene=="atac" and game.reversal_amount<.98 and not game.coins[2]
    if broken_passage!=null: broken_passage.visible=current_scene=="corridor" and not game.ancient
    for prop in game.past_objects:
        prop.visible=game.ancient and current_scene==("corridor" if prop==game.bridge else "agora")
    game.magic_particles.emitting=game.ancient and current_scene=="agora"
    game.magic_particles.visible=current_scene=="agora"
    if gallery_board!=null: gallery_board.hide()

func _rescue_sequence() -> void:
    victory_busy=true
    game.win_panel.hide()
    game._flash("Nefertiti is free. The curse is reversed.",3)
    _look_at_target("queen")
    game.player.show()
    game.player.position=game.QUEEN_SPOT+Vector3(.88,1,.12)
    var facing: Vector3=game.QUEEN_SPOT-camera_origin
    game.player_model.rotation.y=atan2(-facing.x,-facing.z)
    var tween:=create_tween()
    tween.tween_interval(1.25)
    tween.tween_callback(func():
        victory_busy=false
        game.win_panel.show())

func _exit_tree() -> void:
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _make_guardian_portrait(panel: Control) -> void:
    var viewport:=SubViewport.new()
    viewport.name="GuardianPortraitViewport"
    game.add_child(viewport)
    viewport.size=Vector2i(192,192)
    viewport.own_world_3d=true
    viewport.transparent_bg=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    var stage:=Node3D.new()
    viewport.add_child(stage)
    var hero:=Node3D.new()
    stage.add_child(hero)
    var builder=preload("res://guardian_art.gd").new()
    portrait_pivots=builder.build(game,hero,true)
    var environment:=WorldEnvironment.new()
    stage.add_child(environment)
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("0b2634")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color("a3bdcf")
    environment.environment.ambient_light_energy=.65
    var key:=DirectionalLight3D.new()
    stage.add_child(key)
    key.rotation_degrees=Vector3(-30,-25,0)
    key.light_color=Color("f3dfba")
    key.light_energy=1.1
    var fill:=DirectionalLight3D.new()
    stage.add_child(fill)
    fill.rotation_degrees=Vector3(-15,150,0)
    fill.light_energy=.45
    fill.light_color=Color("8fc6e4")
    var camera:=Camera3D.new()
    stage.add_child(camera)
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=1.8
    camera.position=Vector3(.22,3.12,5)
    camera.look_at(Vector3(0,3.0,0))
    camera.current=true
    portrait_texture=viewport.get_texture()
    var picture:=TextureRect.new()
    picture.name="GuardianPortrait"
    panel.add_child(picture)
    picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    picture.texture=portrait_texture
    picture.position=Vector2(10,10)
    picture.size=Vector2(90,90)
    picture.mouse_filter=Control.MOUSE_FILTER_IGNORE

func _make_reversal_puzzles() -> void:
    broken_passage=Node3D.new()
    add_child(broken_passage)
    broken_passage.position=game.bridge.position
    for i in range(5):
        var shard: Node3D=game._box(broken_passage,Vector3(i*.27,-.02,0),Vector3(.20,.06,.45),Color("546a7a"))
        shard.rotation=Vector3(.12*(i%2),.22*(i-2),.12*(i%3))
    temporal_lock=Node3D.new()
    add_child(temporal_lock)
    temporal_lock.position=Vector3(game.COIN_SPOTS[2].x,0,game.COIN_SPOTS[2].z)
    for x in [-.33,.33]:
        for z in [-.3,.3]:
            game._cylinder(temporal_lock,Vector3(x,.73,z),.035,1.46,Color("498ea9"))
    game._ring(temporal_lock,Vector3(0,1.48,0),.47,Color("68c7e9"),true)
    game._ring(temporal_lock,Vector3(0,.05,0),.47,Color("68c7e9"),true)
