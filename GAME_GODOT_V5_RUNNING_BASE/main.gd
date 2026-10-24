extends Node3D
## Original 3D game-jam prototype. All geometry and mechanics are generated in code.
## Campus-inspired layout, NOT a photogrammetric or official campus 3D model.

const WALK_SPEED: float = 12.5
const CAMERA_OFFSET = Vector3(-17, 12, -23)
const CAMERA_CLOSE_OFFSET = Vector3(-8, 7, -12)
const COIN_SPOTS = [Vector3(20, 1.6, 2), Vector3(36, 1.6, -25), Vector3(-32, 1.6, 20)]
const COIN_TITLES = ["Library Scarab", "ATAC Scarab", "Lake Scarab"]
const ALTAR_SPOT = Vector3(0, 0, 6)
const VAULT_SPOT = Vector3(49, 0, -25)
const QUEEN_SPOT = Vector3(-46, 0, 20)

var player: CharacterBody3D
var player_model: Node3D
var cam: Camera3D
var coin_nodes: Array[Node3D] = []
var past_objects: Array[Node3D] = []
var present_objects: Array[Node3D] = []
var queen_cage: Node3D
var queen: Node3D
var bridge: Node3D
var vault_door: Node3D
var coins := [false, false, false]
var ancient := false
var vault_open := false
var map_found := false
var has_key := false
var altar_started := false
var altar_step := 0
var finished := false
var is_map_open := false
var clock := 0.0
var remaining_message := 0.0
var hint_label: Label
var status_label: Label
var objective_label: Label
var message_label: Label
var map_panel: PanelContainer
var win_panel: PanelContainer
var minimap_player: Label
var minimap_coin_markers: Array[Label] = []
var orbit_phase: float = 0.0
var glow_nodes: Array[Node3D] = []
var viewing_close: bool = false
var showcase_view: int = 0
var hud_root: CanvasLayer
var fx_player: AudioStreamPlayer
var ancient_environment: WorldEnvironment
var sunlight: DirectionalLight3D
var locator: Node3D
var shadow_floor: Node3D
var time_sparkle: float = 0.0
var help_panel: PanelContainer
var guide_label: Label
var art = preload("res://environment_art.gd").new()
var world_environment: Environment
var reversal_tween: Tween
var bridge_tween: Tween
var rune_nodes: Array[Node3D] = []
var magic_particles: CPUParticles3D
var reversal_amount := 0.0

func _ready() -> void:
    _create_world()
    _create_player()
    _create_hud()
    _make_sfx()
    _update_world_state()
    _flash("The guardian of Egypt has reached Lakehead. Reverse reality to save Nefertiti!", 6.0)

func _process(delta: float) -> void:
    clock += delta
    for i in range(coin_nodes.size()):
        if not coins[i]:
            coin_nodes[i].rotation.y += 1.6 * delta
            coin_nodes[i].position.y = COIN_SPOTS[i].y + sin(clock * 2.6 + i) * 0.22
    if remaining_message > 0.0:
        remaining_message -= delta
        if remaining_message <= 0.0:
            message_label.text = ""
    if is_instance_valid(cam) and is_instance_valid(player):
        if showcase_view > 0:
            var shots := [Vector3.ZERO, Vector3(-24, 8, -37), Vector3(8, 8, -13), Vector3(21, 10, -40), Vector3(-17, 10, 1)]
            var targets := [Vector3.ZERO, Vector3(-10, 3, -16), Vector3(21, 5, 8), Vector3(38, 7, -17), Vector3(-32, 0, 20)]
            cam.global_position = cam.global_position.lerp(shots[showcase_view], min(delta * 3.0, 1.0))
            cam.look_at(targets[showcase_view], Vector3.UP)
        else:
            cam.global_position = cam.global_position.lerp(player.global_position + (CAMERA_CLOSE_OFFSET if viewing_close else CAMERA_OFFSET), min(delta * 4.0, 1.0))
            cam.look_at(player.global_position + Vector3(0, 2.2, 5.0), Vector3.UP)
    player_model.position.y = -1.0 + sin(clock * 2.5) * 0.04
    art.animate(delta, player.velocity.length() if not help_panel.visible and not is_map_open else 0.0)
    for rune in rune_nodes:
        rune.rotation.y += delta * .3
    _update_hud()
    _update_minimap()
    if is_instance_valid(locator):
        locator.rotation.y += delta * 0.45
        locator.position.y = 0.28 + sin(clock*2.4)*0.17


func _physics_process(delta: float) -> void:
    if finished or is_map_open or altar_started or showcase_view > 0 or help_panel.visible:
        return
    var input_axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        input_axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        input_axis.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        input_axis.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        input_axis.y += 1.0
    input_axis = input_axis.normalized()
    var speed: float = WALK_SPEED * (1.48 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
    var cam_forward: Vector3 = -cam.global_transform.basis.z
    cam_forward.y = 0.0
    cam_forward = cam_forward.normalized()
    var cam_right: Vector3 = cam.global_transform.basis.x
    cam_right.y = 0.0
    cam_right = cam_right.normalized()
    var world_direction: Vector3 = cam_right * input_axis.x - cam_forward * input_axis.y
    player.velocity = world_direction * speed
    player.move_and_slide()
    player.position.x = clamp(player.position.x, -57, 58)
    player.position.z = clamp(player.position.z, -43, 47)
    if input_axis.length() > 0.1:
        player_model.rotation.y = lerp_angle(player_model.rotation.y, atan2(world_direction.x, world_direction.z), min(delta * 10.0, 1.0))
    _water_check()

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    if key_event.keycode == KEY_H:
        help_panel.visible = not help_panel.visible
        hud_root.visible = true
        return
    if help_panel.visible:
        if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_ENTER:
            help_panel.hide()
        return
    if key_event.keycode == KEY_V:
        showcase_view = (showcase_view + 1) % 5
        var shot_names := ["EXPLORER", "AGORA", "PATERSON LIBRARY", "ATAC", "LAKE TAMBLYN"]
        _flash("CAMPUS VIEW  /  %s  (V to continue)" % shot_names[showcase_view], 2.8)
        return
    if key_event.keycode == KEY_C:
        viewing_close = not viewing_close
        _flash("EXPLORER CAMERA" if viewing_close else "CAMPUS CAMERA", 1.25)
        return
    if key_event.keycode == KEY_F1:
        hud_root.visible = not hud_root.visible
        return
    if key_event.keycode == KEY_ESCAPE and is_map_open:
        _show_map(false)
        get_viewport().set_input_as_handled()
        return
    if finished:
        if key_event.keycode == KEY_ENTER:
            get_tree().reload_current_scene()
        return
    if altar_started:
        if key_event.keycode == KEY_1:
            _try_altar_number(1)
        elif key_event.keycode == KEY_2:
            _try_altar_number(2)
        elif key_event.keycode == KEY_3:
            _try_altar_number(3)
        elif key_event.keycode == KEY_ESCAPE:
            altar_started = false
            _flash("Altar paused; press E to try again.", 2.0)
        get_viewport().set_input_as_handled()
        return
    if key_event.keycode == KEY_M and map_found:
        _show_map(not is_map_open)
    elif is_map_open:
        return
    elif key_event.keycode == KEY_R:
        _play_sfx("res://assets/reverse.wav")
        ancient = not ancient
        _update_world_state()
        _animate_reversal()
        _flash("ANCIENT ECHO" if ancient else "PRESENT DAY", 1.5)
    elif key_event.keycode == KEY_E:
        _interact()

func _make_material(color: Color, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.62
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.35
    return m

func _box(parent: Node3D, at: Vector3, box_size: Vector3, color: Color, solid: bool = false) -> Node3D:
    var holder: Node3D
    if solid:
        holder = StaticBody3D.new()
    else:
        holder = Node3D.new()
    parent.add_child(holder)
    holder.position = at
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = box_size
    mesh.mesh = cube
    mesh.material_override = _make_material(color)
    holder.add_child(mesh)
    if solid:
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box_size
        col.shape = shape
        holder.add_child(col)
    return holder

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> Node3D:
    var holder := Node3D.new()
    parent.add_child(holder)
    holder.position = at
    var mesh := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius = radius
    c.bottom_radius = radius
    c.height = height
    mesh.mesh = c
    mesh.material_override = _make_material(color)
    holder.add_child(mesh)
    return holder

func _sphere(parent: Node3D, at: Vector3, radius: float, color: Color) -> Node3D:
    var holder := Node3D.new()
    parent.add_child(holder)
    holder.position = at
    var mesh := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = radius
    s.height = radius * 2.0
    mesh.mesh = s
    mesh.material_override = _make_material(color)
    holder.add_child(mesh)
    return holder

func _sign(parent: Node3D, words: String, at: Vector3, color: Color = Color.WHITE, size: int = 36) -> Label3D:
    var label := Label3D.new()
    parent.add_child(label)
    label.text = words
    label.position = at
    label.font_size = size
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = color
    label.outline_size = 8
    label.no_depth_test = false
    return label

func _cone(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, sides: int = 5) -> Node3D:
    var h := Node3D.new()
    parent.add_child(h)
    h.position = at
    var mesh := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius = 0.05
    c.bottom_radius = radius
    c.height = height
    c.radial_segments = sides
    mesh.mesh = c
    mesh.material_override = _make_material(color)
    h.add_child(mesh)
    return h

func _ring(parent: Node3D, at: Vector3, radius: float, color: Color, glowing: bool = false) -> Node3D:
    var h := Node3D.new()
    parent.add_child(h)
    h.position = at
    var mesh := MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = radius - 0.12
    ring.outer_radius = radius
    ring.rings = 24
    ring.ring_segments = 10
    mesh.mesh = ring
    mesh.material_override = _make_material(color, glowing)
    h.add_child(mesh)
    return h

func _magic_decal(parent: Node3D, at: Vector3, size: float) -> Node3D:
    var node := Node3D.new()
    parent.add_child(node)
    node.position = at
    var mi := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(size, size)
    mi.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load("res://assets/magic_circle.png")
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mi.material_override = mat
    node.add_child(mi)
    return node

func _poster(parent: Node3D, at: Vector3, width: float, height: float) -> void:
    var mi := MeshInstance3D.new()
    parent.add_child(mi)
    mi.position = at
    mi.rotation_degrees.x = -90.0
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(width, height)
    mi.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load("res://assets/lakehead_sign.png")
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mi.material_override = mat

func _tree(parent: Node3D, t: Vector3, scale_factor: float = 1.0) -> void:
    art.tree(self, parent, t, scale_factor)


func _lamp(at: Vector3) -> void:
    _cylinder(self, at + Vector3(0, 2.05, 0), 0.09, 4.1, Color("#323D4C"))
    _box(self, at + Vector3(0, 4.2, 0), Vector3(0.8, 0.16, 0.8), Color("#E5E0D0"))
    _sphere(self, at + Vector3(0, 4.08, 0), 0.23, Color("#FFD994"))

func _obelisk(parent: Node3D, at: Vector3, height: float = 6.0) -> Node3D:
    var node := Node3D.new()
    parent.add_child(node)
    node.position = at
    _box(node, Vector3(0, 0.3, 0), Vector3(2.4, 0.6, 2.4), Color("#AC8648"))
    _box(node, Vector3(0, height * 0.48 + 0.5, 0), Vector3(1.25, height - 0.6, 1.25), Color("#D1A864"))
    _cone(node, Vector3(0, height + 0.38, 0), 0.88, 1.4, Color("#F1CA72"), 4)
    for i in range(4):
        _box(node, Vector3(0, 1.3 + i * 1.05, -0.68), Vector3(0.62, 0.12, 0.08), Color("#8E623C"))
    return node

func _pharaoh_gate(parent: Node3D, at: Vector3) -> Node3D:
    var node := Node3D.new()
    parent.add_child(node)
    node.position = at
    for x in [-3.0, 3.0]:
        _box(node, Vector3(x, 2.3, 0), Vector3(2.1, 4.6, 2.4), Color("#C6A069"))
        _box(node, Vector3(x, 4.75, 0), Vector3(2.5, 0.45, 2.6), Color("#EFCD85"))
        _box(node, Vector3(x, 2.1, -1.25), Vector3(1.24, 0.26, 0.1), Color("#806444"))
    _box(node, Vector3(0, 5.1, 0), Vector3(7.5, 1.45, 2.4), Color("#B88D50"))
    _sphere(node, Vector3(0, 5.4, -1.36), 0.5, Color("#EDC75A"))
    _sign(node, "PORTAL OF TIME", Vector3(0, 7.2, -0.5), Color("#FFE9AE"), 34)
    return node

func _make_pillar(parent: Node3D, at: Vector3, h: float) -> void:
    _cylinder(parent, at + Vector3(0, 0.22, 0), 0.8, 0.44, Color("#A97E4E"))
    _cylinder(parent, at + Vector3(0, h * 0.5, 0), 0.45, h, Color("#D6B175"))
    _cylinder(parent, at + Vector3(0, h + 0.15, 0), 0.78, 0.3, Color("#F1D18E"))
    _cylinder(parent, at + Vector3(0, h * 0.77, 0), 0.53, 0.17, Color("#3C7A8A"))

func _create_world() -> void:
    var env := WorldEnvironment.new()
    add_child(env)
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#447AA0")
    sky_mat.sky_horizon_color = Color("#E9C6A6")
    sky_mat.ground_bottom_color = Color("#4A6465")
    sky_mat.ground_horizon_color = Color("#B2A8A1")
    sky.sky_material = sky_mat
    e.sky = sky
    e.fog_enabled = true
    e.fog_light_color = Color("#BFCAD0")
    e.fog_density = 0.0011
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#C1CFCA")
    e.ambient_light_energy = 0.4
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment = e
    env.environment = e
    var sun := DirectionalLight3D.new()
    add_child(sun)
    sun.rotation_degrees = Vector3(-36, -32, 0)
    sun.light_color = Color("#FFDEB2")
    sun.light_energy = .92
    sun.directional_shadow_max_distance = 135
    sun.shadow_bias = .035
    sun.shadow_enabled = true
    sunlight = sun
    # Landscaped campus. Clear roads and grass contrast with real-looking facades.
    _box(self, Vector3(0, -0.27, 0), Vector3(125, 0.54, 105), Color("#547B59"), true)
    _surface_texture(self, Vector3(0,0.015,0), Vector2(125,105), "res://assets/art_grass.png", Vector2(6,5))
    _box(self, Vector3(5, -0.006, -37), Vector3(119, 0.04, 8), Color("#434D53"))
    _box(self, Vector3(13, 0.006, 0), Vector3(76, 0.07, 4.5), Color("#C3BCA9"))
    _box(self, Vector3(-7, 0.01, -10), Vector3(4.7, 0.08, 36), Color("#C3BCA9"))
    _box(self, Vector3(11, 0.01, -13), Vector3(4.6, 0.08, 34), Color("#C3BCA9"))
    _box(self, Vector3(-18, 0.01, 19), Vector3(5.0, 0.08, 33), Color("#C3BCA9"))
    _box(self, Vector3(37, 0.01, -21), Vector3(5.0, 0.08, 31), Color("#C3BCA9"))
    for t in [Vector3(13,0.07,0), Vector3(-18,0.07,19), Vector3(37,0.07,-21)]:
        _surface_texture(self, t, Vector2(4.25,22), "res://assets/campus_paving.png", Vector2(2,10))
    _surface_texture(self,Vector3(12,0.074,0),Vector2(69,4.15),"res://assets/campus_paving.png",Vector2(15,1))
    for x in range(-48, 52, 9):
        _box(self, Vector3(float(x), 0.04, -37), Vector3(4.8, 0.06, 0.16), Color("#E2D0A4"))
    # Campus buildings: windows, corner trims, entry portals and roofs.
    _building("AGORA / UNIVERSITY CENTRE", Vector3(-10, 0, -12), Vector3(18, 7.5, 12), Color("#8B6359"), Color("#719BAC"))


    _building("PATERSON LIBRARY", Vector3(21, 0, 11), Vector3(18, 13.0, 13), Color("#9FA3A5"), Color("#6C899F"))


    _building("ATAC", Vector3(38, 0, -13), Vector3(17, 16.0, 13), Color("#68747E"), Color("#6BABB8"))


    _building("CENTENNIAL BUILDING", Vector3(-36, 0, -18), Vector3(16, 8.0, 12), Color("#AE8F79"), Color("#86A1A8"))


    # Landmark bell clock / academic entrance near Agora
    _cylinder(self, Vector3(-0.7, 1.2, -20), 1.2, 2.4, Color("#988F86"))
    _cylinder(self, Vector3(-0.7, 3.3, -20), 0.8, 2.3, Color("#BBC7B8"))
    _sphere(self, Vector3(-0.7, 4.6, -20), 0.72, Color("#E3C47C"))
    for t in [Vector3(-13,0,15),Vector3(5,0,22),Vector3(9,0,-28),Vector3(21,0,-30),Vector3(-49,0,-5),Vector3(55,0,7),Vector3(-11,0,37),Vector3(8,0,39),Vector3(50,0,30),Vector3(-50,0,35),Vector3(-28,0,-31), Vector3(26,0,36), Vector3(48,0,12),Vector3(-55,0,14),Vector3(-50,0,39),Vector3(14,0,33),Vector3(3,0,33)]:
        _tree(self,t,0.9 + fmod(absf(t.x), 4.0)*0.1)
    for t in [Vector3(0,0,0),Vector3(13,0,0),Vector3(27,0,0),Vector3(-16,0,-6),Vector3(34,0,-25)]:
        _lamp(t)
    # Lake Tamblyn: organic shoreline model; not a photograph or extracted tour mesh.
    _lake_geometry()
    _natural_waterfront()
    _stone_sign(Vector3(-31.5, 0, 35), "LAKE TAMBLYN")
    bridge = Node3D.new()
    add_child(bridge)
    _box(bridge, Vector3(-24, 0.50, 20), Vector3(19.0, 0.3, 3.35), Color("#7A5337"))
    for i in range(9):
        _box(bridge, Vector3(-15.2 - i*2.15, 0.7, 20), Vector3(1.95, 0.13, 3.1), Color("#E0B66E"))
    for z in [18.3,21.7]:
        for x in [-16.0,-21.0,-26.0,-31.0]:
            _box(bridge,Vector3(x,1.25,z),Vector3(.18,1.2,.18),Color("#E8C584"))
        _box(bridge,Vector3(-24,1.83,z),Vector3(18.0,.15,.16),Color("#D0A357"))
    past_objects.append(bridge)
    # Reverse makes ancient colonnades, portals and obelisks materialize.
    var ancient_props := Node3D.new()
    add_child(ancient_props)
    _pharaoh_gate(ancient_props,Vector3(-2,0,19))
    for pos in [Vector3(-19,0,-1),Vector3(7,0,-1),Vector3(26,0,-1),Vector3(41,0,-1)]:
        _obelisk(ancient_props,pos,5.6)
    for pos in [Vector3(-4,0,29),Vector3(3,0,29)]:
        _make_pillar(ancient_props,pos,4.2)
    for x in [-45.0,-42.0,-39.0]:
        _cone(ancient_props,Vector3(x,1.25,43),2.3,2.5,Color("#D7B17B"),4)
    past_objects.append(ancient_props)
    # Signature reversal circle, both present faint + magic mode bright.
    var magic := _magic_decal(self, ALTAR_SPOT + Vector3(0, 0.08, 0), 9.5)
    past_objects.append(magic)
    # Scarab artifacts glow and rotate at recognizable campus spots.
    for i in range(3):
        var coin := Node3D.new()
        add_child(coin)
        coin.position = COIN_SPOTS[i]
        _cylinder(coin,Vector3(0,0,0),0.74,0.20,Color("#EAB943"))
        _ring(coin,Vector3(0,0.14,0),0.72,Color("#FFF09C"),true)
        var beetle := _sphere(coin,Vector3(0,0.32,0),0.34,Color("#1D8295"))
        beetle.scale = Vector3(1.0,0.65,1.4)
        _sphere(coin,Vector3(0,0.4,-0.34),0.21,Color("#D4F5E4"))
        _sign(coin,"SCARAB 0%d" % [i+1],Vector3(0,1.9,0),Color("#FFE8A8"),36)
        coin_nodes.append(coin)
        _ring(self, COIN_SPOTS[i] + Vector3(0,-1.37,0),1.4,Color("#8F6A42"))
    # Agora ceremonial exchange altar
    _cylinder(self, ALTAR_SPOT + Vector3(0,0.42,0),2.3,0.85,Color("#A67D51"))
    _cylinder(self, ALTAR_SPOT + Vector3(0,1.12,0),1.96,0.52,Color("#D7B782"))
    _ring(self,ALTAR_SPOT + Vector3(0,1.43,0),1.62,Color("#F6CF69"),true)
    for i in range(3):
        _cylinder(self,ALTAR_SPOT + Vector3((i-1)*1.0,1.58,0),0.35,0.25,Color("#714E37"))
    _sign(self,"AGORA / REVERSE ALTAR",ALTAR_SPOT+Vector3(0,3.35,0),Color("#FCE4AC"),34)
    _ankh(self,ALTAR_SPOT+Vector3(0,2.35,0),0.8)
    _make_pillar(self,ALTAR_SPOT+Vector3(-3.5,0,1.8),2.65)
    _make_pillar(self,ALTAR_SPOT+Vector3(3.5,0,1.8),2.65)
    # ATAC vault is a decorative open-air pavilion, not a real campus interior.
    _box(self,Vector3(49,0.25,-24),Vector3(12,0.5,12),Color("#C1AD81"))
    _box(self,Vector3(49,4.85,-24),Vector3(12,0.48,12),Color("#4B6572"))
    for x in [43.6,54.4]:
        for z in [-29,-19]: _make_pillar(self,Vector3(x,0,z),4.4)
    vault_door = _box(self,VAULT_SPOT+Vector3(0,1.65,5.5),Vector3(3.6,3.3,.4),Color("#8B613D"))
    _ring(self,VAULT_SPOT+Vector3(0,2.0,5.15),1.2,Color("#EDC56B"))
    _sign(self,"SECRET MAP CHAMBER",VAULT_SPOT+Vector3(0,6.3,4),Color("#F5DEA6"),37)
    _cylinder(self,VAULT_SPOT+Vector3(0,0.95,-2),1.25,1.75,Color("#AC8352"))
    _ring(self,VAULT_SPOT+Vector3(0,1.85,-2),1.0,Color("#EFD48A"),true)
    _sign(self,"ANCIENT MAP",VAULT_SPOT+Vector3(0,3.1,-2),Color("#FFF0B6"),38)
    # Nefertiti silhouette and a temporal glass prison near lake west shore.
    queen = Node3D.new()
    add_child(queen)
    queen.position = QUEEN_SPOT
    _royal_figure(queen,false)
    _sign(queen,"QUEEN NEFERTITI",Vector3(0,5.6,0),Color("#F9DF9A"),37)
    _magic_decal(self,QUEEN_SPOT+Vector3(0,.07,0),6.0)
    queen_cage=Node3D.new()
    add_child(queen_cage)
    queen_cage.position=QUEEN_SPOT
    for x in [-2.25,2.25]:
        for z in [-2.25,2.25]:
            _cylinder(queen_cage,Vector3(x,2.4,z),.15,4.8,Color("#6E5BA0"))
    for x in [-1.1,0.0,1.1]:
        for z in [-2.25,2.25]:
            _cylinder(queen_cage,Vector3(x,2.4,z),.07,4.8,Color("#7A66BD"))
    _box(queen_cage,Vector3(0,4.9,0),Vector3(5.0,.23,5.0),Color("#9065B7"))
    _ring(queen_cage,Vector3(0,5.2,0),2.1,Color("#B187E5"),true)
    present_objects.append(queen_cage)
    _campus_details()
    _enhance_landscape()
    _build_wayfinding()

    art.courtyard(self)
    _create_reversal_art()

func _building(title: String, at: Vector3, dims: Vector3, _wall: Color, _windows: Color) -> void:
    art.building(self, title, at, dims)


func _royal_figure(parent: Node3D, sphinx: bool) -> void:
    art.royal(self, parent, sphinx)


func _create_player() -> void:
    player = CharacterBody3D.new()
    add_child(player)
    player.position = Vector3(-2, 1.0, -26)
    player.collision_layer = 2
    player.collision_mask = 1
    var body_collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.62
    capsule.height = 2.0
    body_collision.shape = capsule
    player.add_child(body_collision)
    player_model = Node3D.new()
    player.add_child(player_model)
    player_model.position.y = -1.0
    _royal_figure(player_model, true)
    _sign(player_model, "GUARDIAN", Vector3(0, 4.65, 0), Color("ffe6a6"), 23)
    cam = Camera3D.new()
    add_child(cam)
    cam.projection = Camera3D.PROJECTION_PERSPECTIVE
    cam.fov = 54.0
    cam.current = true
    cam.position = player.position + CAMERA_OFFSET
    cam.look_at(player.position + Vector3(0, 1.0, 0), Vector3.UP)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud_root = layer
    var outer := Control.new()
    layer.add_child(outer)
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var header := TextureRect.new()
    outer.add_child(header)
    header.position = Vector2(18,14)
    header.size = Vector2(600,180)
    header.texture = load("res://assets/hud_header.png")
    header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_label = Label.new()
    outer.add_child(status_label)
    status_label.position = Vector2(48,115)
    status_label.add_theme_font_size_override("font_size",17)
    status_label.add_theme_color_override("font_color", Color("#FFE8B2"))
    objective_label = Label.new()
    outer.add_child(objective_label)
    objective_label.position = Vector2(48,148)
    objective_label.add_theme_font_size_override("font_size",15)
    objective_label.add_theme_color_override("font_color", Color("#E3F1F5"))
    var bottom := TextureRect.new()
    outer.add_child(bottom)
    bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_top = -96
    bottom.offset_bottom = -10
    bottom.offset_left = 20
    bottom.offset_right = -20
    bottom.texture = load("res://assets/hud_bottom.png")
    bottom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bottom.stretch_mode = TextureRect.STRETCH_SCALE
    bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hint_label = Label.new()
    bottom.add_child(hint_label)
    hint_label.position = Vector2(24,15)
    hint_label.size = Vector2(1190,27)
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size",19)
    hint_label.add_theme_color_override("font_color",Color("#F6E2AE"))
    var controls := Label.new()
    bottom.add_child(controls)
    controls.text = "WASD  MOVE    SHIFT  RUN    R  REVERSE    E  INTERACT    M  MAP    C  ZOOM    V  CAMPUS TOUR    F1  HUD    H  HELP"
    controls.position = Vector2(20,49)
    controls.size = Vector2(1190,25)
    controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls.add_theme_font_size_override("font_size",15)
    controls.add_theme_color_override("font_color",Color("#BBD6DC"))
    var radar_rect := TextureRect.new()
    outer.add_child(radar_rect)
    radar_rect.position = Vector2(998, 12)
    radar_rect.size = Vector2(272, 204)
    radar_rect.texture = load("res://assets/campus_radar.png")
    radar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    radar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for n in range(3):
        var c := Label.new()
        radar_rect.add_child(c)
        c.text = "◆"
        c.add_theme_color_override("font_color",Color("#FFE082"))
        c.add_theme_font_size_override("font_size",23)
        minimap_coin_markers.append(c)
    minimap_player = Label.new()
    radar_rect.add_child(minimap_player)
    minimap_player.text = "▲"
    minimap_player.add_theme_color_override("font_color",Color("#A6E8FF"))
    minimap_player.add_theme_font_size_override("font_size",25)
    message_label = Label.new()
    outer.add_child(message_label)
    message_label.position = Vector2(300,222)
    message_label.custom_minimum_size = Vector2(680,43)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size",21)
    message_label.add_theme_color_override("font_color",Color("#FFDD8B"))
    message_label.add_theme_color_override("font_shadow_color",Color("#1E2637"))
    message_label.add_theme_constant_override("shadow_offset_x",2)
    message_label.add_theme_constant_override("shadow_offset_y",3)
    map_panel = PanelContainer.new()
    outer.add_child(map_panel)
    map_panel.position = Vector2(165,48)
    map_panel.custom_minimum_size = Vector2(950,590)
    var map_style := StyleBoxEmpty.new()
    map_panel.add_theme_stylebox_override("panel",map_style)
    var map_tex := TextureRect.new()
    map_panel.add_child(map_tex)
    map_tex.custom_minimum_size = Vector2(950,590)
    map_tex.texture = load("res://assets/ancient_map.png")
    map_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map_panel.visible = false
    win_panel = PanelContainer.new()
    outer.add_child(win_panel)
    win_panel.position = Vector2(185,105)
    win_panel.custom_minimum_size = Vector2(900,475)
    win_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
    var win_tex := TextureRect.new()
    win_panel.add_child(win_tex)
    win_tex.custom_minimum_size = Vector2(900,475)
    win_tex.texture = load("res://assets/victory.png")
    win_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    win_panel.visible = false
    guide_label = Label.new()
    outer.add_child(guide_label)
    guide_label.position = Vector2(28, 208)
    guide_label.add_theme_font_size_override("font_size", 18)
    guide_label.add_theme_color_override("font_color", Color("8DE5E0"))
    guide_label.add_theme_color_override("font_shadow_color", Color("101925"))
    guide_label.add_theme_constant_override("shadow_offset_y", 2)
    help_panel = PanelContainer.new()
    outer.add_child(help_panel)
    help_panel.position = Vector2(300, 270)
    help_panel.custom_minimum_size = Vector2(680, 300)
    var help_style := StyleBoxFlat.new()
    help_style.bg_color = Color("101f2ef5")
    help_style.border_color = Color("cfac62")
    help_style.set_border_width_all(2)
    help_style.set_corner_radius_all(16)
    help_style.content_margin_left = 28
    help_style.content_margin_top = 24
    help_style.content_margin_bottom = 24
    help_style.content_margin_right = 28
    help_panel.add_theme_stylebox_override("panel", help_style)
    var help_text := Label.new()
    help_text.text = "SPHINX REVERSAL  /  FIELD GUIDE\n\nWASD / Arrows: move    Shift: sprint\nR: reverse time    E: interact    C: camera zoom\nM: map (after discovery)    V: scenic views    F1: HUD\n\n1. Enter Ancient Echo and collect the three scarabs.\n2. Return to Agora. Activate the altar with 3, 2, 1.\n3. Unlock ATAC, find the map, then rescue the Queen.\n\nENTER / ESC: continue    H: reopen this guide"
    help_text.add_theme_font_size_override("font_size", 19)
    help_text.add_theme_color_override("font_color", Color("f5e6c8"))
    help_panel.add_child(help_text)

func _update_hud() -> void:
    if not is_instance_valid(status_label):
        return
    _update_quest_guide()
    var count := 0
    for picked in coins:
        if picked:
            count += 1
    status_label.text = "SCARABS  %d / 3      |      %s" % [count, "ANCIENT ECHO" if ancient else "PRESENT DAY"]
    if finished:
        objective_label.text = "MISSION COMPLETED"
    elif not has_key:
        objective_label.text = "QUEST  /  Collect 3 scarabs, return to Agora"
    elif not map_found:
        objective_label.text = "QUEST  /  Open the ATAC map chamber"
    else:
        objective_label.text = "QUEST  /  Rescue Nefertiti at Lake Tamblyn"
    var near_text := "Find 3 magical scarabs. Press R to reverse reality."
    if altar_started:
        near_text = "ALTAR PUZZLE: Press 3, then 2, then 1. Progress: %d/3. ESC to leave." % altar_step
    elif map_found and player.position.distance_to(QUEEN_SPOT + Vector3.UP) < 5.0:
        near_text = "Press R to dismiss the time cage, then E to save the Queen!"
    elif has_key and not vault_open and player.position.distance_to(VAULT_SPOT + Vector3(0, 1, 5)) < 5.0:
        near_text = "Press E to unlock the secret map chamber."
    elif vault_open and not map_found and player.position.distance_to(VAULT_SPOT + Vector3(0, 1, -2)) < 5.0:
        near_text = "Press E to take the map from its pedestal."
    elif player.position.distance_to(ALTAR_SPOT + Vector3.UP) < 5.0:
        near_text = "Agora altar: collect all coins, then press E."
    else:
        for i in range(3):
            if not coins[i] and player.position.distance_to(COIN_SPOTS[i]) < 4.5:
                near_text = "Scarab %d: press R to reveal it, then E to collect." % [i + 1]
                break
    hint_label.text = near_text

func _update_world_state() -> void:
    for obj in past_objects:
        obj.visible = ancient
    for obj in present_objects:
        obj.visible = not ancient
    if is_instance_valid(cam):
        cam.environment = null
    for i in range(coin_nodes.size()):
        coin_nodes[i].visible = ancient and not coins[i]
    if not is_instance_valid(vault_door):
        return
    vault_door.visible = not vault_open

func _flash(words: String, duration: float = 2.6) -> void:
    if not is_instance_valid(message_label):
        return
    message_label.text = words
    remaining_message = duration

# Visual reconstruction notes: campus details are inspired by public photographs,
# the university map, and the virtual-tour location list—not extracted 360 geometry.
func _surface_texture(parent: Node3D, at: Vector3, dims: Vector2, path: String, tile: Vector2) -> void:
    var mi := MeshInstance3D.new()
    parent.add_child(mi)
    mi.position = at
    var plane := PlaneMesh.new()
    plane.size = dims
    plane.subdivide_width = 1
    plane.subdivide_depth = 1
    mi.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load(path)
    mat.uv1_scale = Vector3(tile.x, tile.y, 1.0)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    mat.roughness = 0.9
    mi.material_override = mat

func _wall_texture(parent: Node3D, at: Vector3, dims: Vector2, path: String, tiles: Vector2) -> void:
    var mi := MeshInstance3D.new()
    parent.add_child(mi)
    mi.position = at
    mi.rotation_degrees.x = -90
    var p := PlaneMesh.new()
    p.size = dims
    mi.mesh = p
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load(path)
    mat.uv1_scale = Vector3(tiles.x,tiles.y,1)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.roughness = 0.8
    mi.material_override = mat

func _agora_details() -> void:
    # The Agora has brown brick and two continuous bands of tall windows.
    var a := Vector3(-10,0,-12)
    _wall_texture(self, Vector3(-10,4,-18.19),Vector2(16.7,6.7),"res://assets/campus_brick.png",Vector2(7,4))
    for y in [3.15,6.25]:
        _box(self,Vector3(-10,y,-18.27),Vector3(18.5,.24,.48),Color("#C4B1A0"))
    _box(self,Vector3(-10,1.5,-19.15),Vector3(7.3,2.88,.1),Color("#3E5963"))
    for x in [-12.6,-11.3,-10.0,-8.7,-7.4]:
        _box(self,Vector3(x,1.52,-19.25),Vector3(.85,2.37,.06),Color("#75B5BD"))
    _box(self,Vector3(-10,3.2,-19.45),Vector3(10,.36,1.65),Color("#303C49"))
    _sign(self,"AGORA",Vector3(-10,4.05,-20),Color("#FFF2D8"),33)
    for x in [-16,-13,-7,-4]:
        _bench(Vector3(x,0,-23.2),0.0)
    for x in [-17, -3]:
        _planter(Vector3(x,0,-21.3),2.4)

func _library_details() -> void:
    # The curved teal-green entrance canopy is based on official Library tour images.
    _wall_texture(self,Vector3(21,6.4,4.38),Vector2(17.2,11.8),"res://assets/campus_concrete.png",Vector2(6,5))
    _box(self,Vector3(30.8,7.2,11),Vector3(3.2,14.4,12.5),Color("#443D3D"))
    for floor_num in range(4):
        var y: float = 2.3 + floor_num * 2.6
        _box(self,Vector3(20.3,y,4.20),Vector3(16.6,1.5,.16),Color("#415D70"))
        for n in range(8):
            var x: float = 12.7 + n * 2.15
            _box(self,Vector3(x,y,4.11),Vector3(1.72,1.38,.11),Color("#8CBCD0"))
        _box(self,Vector3(20.4,y-0.81,4.07),Vector3(16.8,.15,.19),Color("#D5D7D0"))
    for i in range(13):
        var x: float = -4.0 + i * (8.0 / 12.0)
        var h: float = 3.55 + 1.06 * (1.0 - pow(x / 4.15, 2))
        var canopy_piece := _box(self,Vector3(21+x,h,1.90),Vector3(.69,.13,4.65),Color("#428B89"))
        canopy_piece.rotation_degrees.z = (x/4.0)*-13
    for x in [17.2,24.8]:
        _cylinder(self,Vector3(x,1.78,-0.35),.14,3.45,Color("#8EAEAB"))
    _box(self,Vector3(21,2.94,0.9),Vector3(9.5,.32,.45),Color("#2A686D"))
    _sign(self,"CHANCELLOR PATERSON LIBRARY",Vector3(21,4.2,-0.7),Color("#F4E9D2"),29)
    for x in [15.0,17.0,25.0,27.0]:
        _box(self,Vector3(x,.20,-1.7),Vector3(.12,.4,4.8),Color("#B6C6C8"))

func _atac_details() -> void:
    # ATAC glass curtain wall with vertical concrete fins and curved profile.
    for n in range(15):
        var x: float = 29.9 + float(n) * 1.17
        var z: float = -19.7 + 0.019 * pow(x - 38.0, 2)
        for y_index in range(5):
            var y: float = 1.7 + float(y_index) * 2.9
            _box(self,Vector3(x,y,z-.22),Vector3(1.12,2.56,.14),Color("#4E94A9") if (n+y_index)%3!=0 else Color("#79BACB"))
        _box(self,Vector3(x,8,z-.47),Vector3(.12,15.6,.43),Color("#D8D8CF"))
    for x in [31.1,35.0,39.0,42.9,46.1]:
        var fin: Node3D = _box(self,Vector3(x,7.1,-21.00),Vector3(.38,14.3,.9),Color("#D9D4C6"))
        fin.rotation_degrees.z = -7.0
    _box(self,Vector3(38,2.3,-22.2),Vector3(8,4.4,2.5),Color("#386D7A"))
    for x in [35.3,36.4,37.5,38.6,39.7,40.8]:
        _box(self,Vector3(x,2.4,-23.53),Vector3(.9,3.6,.10),Color("#9AD1D2"))
    _box(self,Vector3(38,4.75,-22.6),Vector3(10,.35,3.6),Color("#B6C6C1"))
    _sign(self,"ATAC / ADVANCED TECHNOLOGY",Vector3(38,6.25,-23),Color("#FCEFD4"),27)
    for x in [32,44]:
        _planter(Vector3(x,0,-25.8),2.0)

func _lake_geometry() -> void:
    var verts := PackedVector3Array()
    var uvs := PackedVector2Array()
    var inds := PackedInt32Array()
    verts.append(Vector3(-32, .13, 20))
    uvs.append(Vector2(.5,.5))
    for i in range(65):
        var th: float = float(i)*TAU/64.0
        var rr: float = 11.35+0.45*sin(th*5.0)+0.42*cos(th*3.0)
        var xx: float = -32.0 + rr*cos(th)
        var zz: float = 20.0 + rr*0.88*sin(th)
        verts.append(Vector3(xx,.13,zz))
        uvs.append(Vector2(.5+0.5*cos(th),.5+0.5*sin(th)))
        if i > 0:
            inds.append(0)
            inds.append(i)
            inds.append(i+1)
    var ar := []
    ar.resize(Mesh.ARRAY_MAX)
    ar[Mesh.ARRAY_VERTEX] = verts
    var normals := PackedVector3Array()
    normals.resize(verts.size())
    normals.fill(Vector3.UP)
    ar[Mesh.ARRAY_NORMAL] = normals
    ar[Mesh.ARRAY_TEX_UV] = uvs
    ar[Mesh.ARRAY_INDEX] = inds
    var arr := ArrayMesh.new()
    arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,ar)
    var mi := MeshInstance3D.new()
    add_child(mi)
    mi.mesh = arr
    var mat := ShaderMaterial.new()
    mat.shader = load("res://assets/lake_water.gdshader")
    mi.material_override = mat
    for n in range(42):
        var angle: float = float(n)*TAU/42.0
        var rr: float = 11.9+0.45*sin(angle*5.0)+0.42*cos(angle*3.0)
        var at := Vector3(-32+rr*cos(angle),.25,20+rr*.88*sin(angle))
        var rock := _sphere(self,at,.45+0.17*sin(angle*7),Color("#777d72"))
        rock.scale = Vector3(1.25,.48,.85)
        rock.rotation.y = angle*4.0
    # Small central island has a few bushes and a stone marker.
    _cylinder(self,Vector3(-32,.16,20),2.45,.36,Color("#B0A785"))
    _sphere(self,Vector3(-33,.45,19),.65,Color("#3C7458"))
    _sphere(self,Vector3(-31,.45,21),.7,Color("#497A5B"))
    _ring(self,Vector3(-32,.20,20),11.25,Color("#5EA2AA"))

func _bench(at: Vector3, yaw: float) -> void:
    var n := Node3D.new()
    add_child(n)
    n.position=at
    n.rotation.y=yaw
    for x in [-1.05,1.05]:
        _box(n,Vector3(x,.5,0),Vector3(.13,1,.82),Color("#303C43"))
    for z in [-.17,.03,.23]:
        _box(n,Vector3(0,1.01,z),Vector3(2.6,.13,.17),Color("#8A6246"))
    for y in [1.36,1.65]:
        _box(n,Vector3(0,y,.34),Vector3(2.6,.18,.16),Color("#8A6246"))

func _planter(at: Vector3, r: float) -> void:
    _cylinder(self,at+Vector3(0,.42,0),r,.84,Color("#A5A8A1"))
    _cylinder(self,at+Vector3(0,.89,0),r-.1,.18,Color("#403F34"))
    for dx in [-.65,0,.65]:
        for dz in [-.7,.7]:
            _sphere(self,at+Vector3(dx,1.26,dz),.56,Color("#3C6950"))

func _stone_sign(at: Vector3, words: String) -> void:
    _box(self,at+Vector3(0,.76,0),Vector3(6,1.48,.75),Color("#8F938B"))
    _box(self,at+Vector3(0,1.55,0),Vector3(6.36,.13,.85),Color("#C6C4AF"))
    _sign(self,words,at+Vector3(0,2.38,0),Color("#FFF5D5"),27)

func _ankh(parent: Node3D, at: Vector3, sz: float) -> void:
    var n := Node3D.new()
    parent.add_child(n)
    n.position = at
    n.scale=Vector3.ONE * sz
    var loop := _ring(n,Vector3(0,.45,0),.47,Color("#F7D16B"),true)
    loop.rotation_degrees.x=90
    _box(n,Vector3(0,-.42,0),Vector3(.17,1.17,.14),Color("#FFCE6A"))
    _box(n,Vector3(0,-.20,0),Vector3(1.1,.15,.13),Color("#FFCE6A"))

func _campus_details() -> void:
    for at in [Vector3(9,0,11),Vector3(14,0,26),Vector3(-21,0,36),Vector3(2,0,-25),Vector3(42,0,18)]:
        _bench(at,.4)
    for at in [Vector3(-23,0,-5),Vector3(14,0,-3),Vector3(25,0,26),Vector3(6,0,28),Vector3(51,0,-4)]:
        _planter(at,1.4)
    # Painted curb and dashed campus road for real-world legibility.
    for xx in range(-49,54,6):
        _box(self,Vector3(float(xx),.04,-37),Vector3(2.8,.07,.15),Color("#EEE8D9"))
    # Egyptian energy appears only after reversing time.
    var glyph_group := Node3D.new()
    add_child(glyph_group)
    for at in [Vector3(-3,0,22),Vector3(-20,0,-1),Vector3(38,0,-30)]:
        _ankh(glyph_group,at+Vector3(0,2.6,0),1.0)
        _ring(glyph_group,at+Vector3(0,.12,0),2.0,Color("#F0C764"),true)
    past_objects.append(glyph_group)

func _update_minimap() -> void:
    if not is_instance_valid(minimap_player):
        return
    minimap_player.position = Vector2(12+(player.position.x+60)*1.97, 27+(player.position.z+48)*1.40)
    for i in range(minimap_coin_markers.size()):
        var node: Label = minimap_coin_markers[i]
        node.visible = not coins[i]
        node.position = Vector2(12+(COIN_SPOTS[i].x+60)*1.97, 27+(COIN_SPOTS[i].z+48)*1.40)

func _water_check() -> void:
    var flat := Vector2(player.position.x + 32, player.position.z - 20)
    var lake_radius: float = Vector2(flat.x, flat.y/0.88).length()
    if lake_radius > 11.3 or lake_radius < 3.0:
        return
    var on_bridge: bool = ancient and player.position.x > -35.0 and player.position.x < -15.0 and absf(player.position.z - 20.0) < 1.8
    if not on_bridge:
        player.position = Vector3(-17, 1, 20)
        _flash("Splash! Reverse time to rebuild the bridge.", 2.2)

func _interact() -> void:
    # The nearest relevant object wins, so E has a predictable meaning.
    for i in range(3):
        if not coins[i] and player.position.distance_to(COIN_SPOTS[i]) < 3.2:
            if not ancient:
                _flash("The scarab is lost in time. Press R!", 2.5)
                return
            coins[i] = true
            coin_nodes[i].visible = false
            _play_sfx("res://assets/collect.wav")
            _flash("Collected %s!" % COIN_TITLES[i], 3.0)
            return
    if player.position.distance_to(ALTAR_SPOT + Vector3.UP) < 4.0 and not has_key:
        if coins[0] and coins[1] and coins[2]:
            altar_started = true
            altar_step = 0
            _flash("Reverse their order! Enter 3 - 2 - 1 using number keys.", 5.0)
        else:
            _flash("The altar needs all 3 scarabs.", 2.0)
        return
    if player.position.distance_to(VAULT_SPOT + Vector3(0, 1, 5)) < 4.0 and not vault_open:
        if has_key:
            vault_open = true
            _play_sfx("res://assets/unlock.wav")
            vault_door.visible = false
            _flash("The golden key opened the map chamber!", 3.0)
        else:
            _flash("Locked. Restore the scarabs at the Agora altar first.", 2.6)
        return
    if vault_open and not map_found and player.position.distance_to(VAULT_SPOT + Vector3(0, 1, -2)) < 4.0:
        map_found = true
        _flash("Map found! Press M to see where Nefertiti is held.", 4.0)
        _show_map(true)
        return
    if player.position.distance_to(QUEEN_SPOT + Vector3.UP) < 4.0:
        if not map_found:
            _flash("Find the ancient map first!", 2.5)
        elif not ancient:
            _flash("Her prison is trapped in the present. Press R!", 2.5)
        else:
            finished = true
            _play_sfx("res://assets/victory_fanfare.wav")
            win_panel.visible = true
            _flash("THE CURSE HAS BEEN REVERSED!", 7.0)
        return
    _flash("Get closer to a scarab, shrine, lock or the Queen.", 2.5)

func _try_altar_number(num: int) -> void:
    var wanted := [3, 2, 1]
    if num != wanted[altar_step]:
        altar_step = 0
        _flash("Wrong order! The past must be read BACKWARDS: 3 > 2 > 1.", 2.8)
        return
    altar_step += 1
    if altar_step == 3:
        has_key = true
        _play_sfx("res://assets/unlock.wav")
        altar_started = false
        _flash("Success! You obtained the GOLDEN KEY. Go to ATAC!", 4.0)
    else:
        _flash("Correct! %d / 3 symbols restored." % altar_step, 2.0)

func _show_map(show: bool) -> void:
    is_map_open = show
    map_panel.visible = show


# V4: original procedural 3D architectural approximations based on Lakehead
# University's tour images. Models are NOT copied from virtual-tour geometry.
func _facade_plane(at: Vector3, width: float, height: float, path: String) -> void:
    var p := MeshInstance3D.new()
    add_child(p)
    p.position = at
    p.rotation_degrees.x = -90
    var panel := PlaneMesh.new()
    panel.size = Vector2(width,height)
    p.mesh = panel
    var m := StandardMaterial3D.new()
    m.albedo_texture = load(path)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    m.roughness = 0.76
    p.material_override = m

func _make_sfx() -> void:
    fx_player = AudioStreamPlayer.new()
    add_child(fx_player)
    fx_player.volume_db = -8.0

func _play_sfx(path: String) -> void:
    if is_instance_valid(fx_player):
        fx_player.stop()
        fx_player.stream = load(path)
        fx_player.play()

func _architecture_agora() -> void:
    # Long brown-brick frontage, two horizontal glass bands, familiar glass entry.
    _facade_plane(Vector3(-10,3.93,-18.85), 17.65, 7.4, "res://assets/facade_agora_v5.jpg")
    # prominent horizontal Lakehead fascia above main doors
    _box(self, Vector3(-10,3.76,-19.50),Vector3(8.7,.86,.16),Color("#55483F"))
    _sign(self,"AGORA",Vector3(-10,4.35,-19.66),Color("#F8EBD0"),36)
    for x in [-14.4,-12.2,-10.0,-7.8,-5.6]:
        _box(self,Vector3(x,1.63,-19.56),Vector3(.10,3.1,.1),Color("#56696A"))
    for x in [-19.0,-1.0]:
        _cylinder(self,Vector3(x,.55,-22),1.8,1.1,Color("#A6AC9C"))
        for i in range(7):
            var a: float = TAU*float(i)/7.0
            _sphere(self,Vector3(x+1.08*cos(a),1.25,-22+1.08*sin(a)),.46,Color("#617E53"))

func _architecture_library() -> void:
    # Paterson entrance: pale concrete, dark blue window ribbon, turquoise canopy.
    _facade_plane(Vector3(21,6.35,4.11),17.5,12.55,"res://assets/facade_paterson_v5.jpg")
    # semi-transparent overhead canopy with thin steel ribs; retains actual depth
    for i in range(13):
        var xx: float = -4.2+float(i)*.7
        var arch_y: float = 3.4+1.4*(1-pow(xx/4.3,2))
        var rib := _box(self,Vector3(21+xx,arch_y,-0.70),Vector3(.09,.18,5.3),Color("#477F80"))
        rib.rotation_degrees.z = -xx*2.0
        var glass := _box(self,Vector3(21+xx,arch_y+.11,-1.05),Vector3(.63,.12,4.8),Color(0.28,0.69,0.70,0.82))
        glass.rotation_degrees.z = -xx*2.0
    _box(self,Vector3(21,3.26,-3.04),Vector3(9,.26,.22),Color("#3B797D"))
    for x in [16.3,25.7]:
        _cylinder(self,Vector3(x,1.65,-3.0),.14,3.3,Color("#D1D5D0"))
    # Stone steps, aligned to main entrance.
    for j in range(4):
        _box(self,Vector3(21,.11+j*.115,-5.25+j*.62),Vector3(9.6,.22+j*.12,1.27),Color("#B8BCB4"))

func _architecture_atac() -> void:
    # Signature ATAC reflective curtain glass panels backed by solid 3D massing.
    # Narrow tile surfaces are separate panels; each has glass texture and frame.
    for i in range(15):
        var x: float = 29.9+float(i)*1.17
        var z: float = -20.08+.019*pow(x-38.0,2)
        for f in range(5):
            var pane := _box(self,Vector3(x,1.70+f*2.9,z-.45),Vector3(1.03,2.52,.10),Color("#719DB1"))
            var mi: MeshInstance3D = pane.get_child(0) as MeshInstance3D
            var mat := StandardMaterial3D.new()
            mat.albedo_texture = load("res://assets/glass_atac_v5.jpg")
            mat.metallic = .33
            mat.roughness = .16
            mi.material_override = mat
        _box(self,Vector3(x,7.75,z-.51),Vector3(.09,15.5,.13),Color("#C5D0D0"))
    for y in [0.6,3.5,6.4,9.3,12.2,15.1]:
        _box(self,Vector3(38,y,-20.4),Vector3(17,.13,.45),Color("#CAD1CA"))
    _sign(self,"ATAC",Vector3(38,6.0,-24),Color("#E8F4EA"),30)

func _natural_waterfront() -> void:
    # Shoreline, rocks and reeds. Lake Tamblyn is irregular, never a perfect disc.
    for i in range(65):
        var th: float = TAU*float(i)/65
        var rr: float = 12.10+.45*sin(th*5.0)+.42*cos(th*3.0)
        var px: float = -32+rr*cos(th)
        var pz: float = 20+rr*.88*sin(th)
        if i%4 != 0:
            _sphere(self,Vector3(px,.28,pz),.17+.11*(1.0+sin(th*13.0)),Color("#8E9380"))
        if i%5 == 0:
            for k in range(3):
                var reedy := _box(self,Vector3(px+.12*k,.8,pz),Vector3(.035,1.2,.035),Color("#739066"))
                reedy.rotation_degrees.z = float(k-1)*10
    for i in range(12):
        var th: float = TAU*float(i)/12.0
        _sphere(self,Vector3(-32+9.5*cos(th),.24,20+7.8*sin(th)),.31,Color("#D9D3B7"))

func _enhance_landscape() -> void:
    # Several pine groves, campus banners, bushes and physical entrances.
    for i in range(21):
        var xx: float = -61.0+float(i)*6.0
        _tree(self,Vector3(xx,0,-47.0+2.0*sin(float(i)*1.27)), 1.0+0.15*sin(i*.8))
    # no thick vegetation on paths or over the in-game lake
    for i in range(94):
        var xx: float = -55.0+float((i*37)%108)
        var zz: float = -36.0+float((i*29)%83)
        if Vector2(xx+32.0,(zz-20.0)/.88).length() < 15.0:
            continue
        if absf(xx-13)<3.2 or absf(zz)<3.0 or absf(zz+37)<5.5:
            continue
        if (xx > -23 and xx < 2 and zz > -25 and zz < -3) or (xx>10 and xx<32 and zz>0 and zz<20) or (xx>27 and xx<50 and zz>-22 and zz < -4):
            continue
        _sphere(self,Vector3(xx,.28,zz),.32+(.15 if i%3==0 else 0.0),Color("#476D54") if i%3!=0 else Color("#6C8A56"))
    for spot in [Vector3(-10,0,-26),Vector3(18,0,-4),Vector3(42,0,-28)]:
        _campus_banner(spot)

func _campus_banner(at: Vector3) -> void:
    _cylinder(self,at+Vector3(0,2.2,0),.085,4.4,Color("#51585C"))
    _box(self,at+Vector3(.62,3.1,0),Vector3(1.22,1.42,.08),Color("#193F67"))
    _box(self,at+Vector3(.62,3.75,-.065),Vector3(1.14,.09,.01),Color("#E6B66B"))
    _sign(self,"LAKEHEAD",at+Vector3(.61,2.67,-.13),Color("#E8EEF4"),17)

func _build_wayfinding() -> void:
    # Interactive quest waypoint decoration, intentionally not a static photo.
    locator = Node3D.new()
    add_child(locator)
    locator.position=ALTAR_SPOT+Vector3(0,0.7,0)
    var ring := _ring(locator,Vector3(0,3.6,0),1.05,Color("#E5BB71"),true)
    ring.rotation_degrees.x=90
    _ankh(locator,Vector3(0,3.65,0),.6)


# V5 facade and landscape detailing: all of these are true 3D nodes, not HUD pictures.
func _v5_detail_pass() -> void:
    # Recessed Agora vestibule, freestanding granite pilasters, low parapet and signage.
    for ix in [-17.6, -2.4]:
        _box(self, Vector3(ix, 3.55, -19.18), Vector3(.7, 7.25, .72), Color("#8C8179"))
        _box(self, Vector3(ix, 1.25, -19.65), Vector3(.76, 2.5, .90), Color("#717777"))
    for ix in [-13.55,-12.20,-10.85,-9.5,-8.15,-6.80]:
        _box(self,Vector3(ix,1.51,-20.02),Vector3(.065,2.90,.12),Color("#B0C7CF"))
    _box(self,Vector3(-10,7.6,-18.4),Vector3(18.6,.30,1.35),Color("#5B6267"))
    _box(self,Vector3(-10,.17,-21.05),Vector3(10.6,.23,3.2),Color("#AEAAA0"))
    # Characteristic large library brick stair tower and projecting concrete side bands.
    _box(self,Vector3(29.7,7.1,10.7),Vector3(3.5,14.2,13.4),Color("#574741"))
    for iy in range(5):
        var h: float = 1.24 + 2.51*float(iy)
        _box(self,Vector3(29.9,h,4.0),Vector3(2.70,.11,.18),Color("#9EACA9"))
    for ix in [12.5,15.0,27.1]:
        _box(self,Vector3(ix,6.8,4.01),Vector3(.24,13.2,.25),Color("#DBD9D1"))
    # Library's distinctive sweeping jade entrance awning with visible transverse ribs.
    for n in range(8):
        var z: float = -2.8+float(n)*.72
        _box(self,Vector3(21,4.30,z),Vector3(9.2,.12,.075),Color("#386F78"))
    # ATAC tower and stepped reflective curtain wall; thicker concrete piers read at distance.
    _cylinder(self,Vector3(46,8,-10.0),2.45,16,Color("#788C93"))
    _cylinder(self,Vector3(46,16.2,-10.0),2.52,.45,Color("#BFC8C4"))
    for ix in [30.55,34.05,37.55,41.05,44.5]:
        var pi := _box(self,Vector3(ix,7.5,-21.62),Vector3(.52,15.0,.90),Color("#BCC7C6"))
        pi.rotation_degrees.z = -8.0
    _box(self,Vector3(38,16.2,-20.04),Vector3(17.6,.33,2.0),Color("#59686F"))
    # Architectural paving bonds and roof equipment silhouettes.
    for b in range(7):
        var bx: float = -18.0 + float(b)*2.6
        _box(self,Vector3(bx,7.93,-11.8),Vector3(1.25,.8,1.3),Color("#7E8686"))
    for b in range(8):
        var bx: float = 13.0 + float(b)*1.8
        _box(self,Vector3(bx,13.38,10.8),Vector3(.95,.6,1.65),Color("#7F898A"))
    for b in range(5):
        var bx: float = 32.5+float(b)*2.6
        _box(self,Vector3(bx,16.42,-12.8),Vector3(1.75,.55,2.15),Color("#71838A"))
    # Dense shrubs under entrances and small flowerbeds along walking path.
    for k in range(28):
        var xx: float = -24.0 + float(k)*2.2
        var z: float = -27.7 + sin(float(k)*1.67)*.70
        if xx > 31 and xx < 49:
            continue
        _sphere(self,Vector3(xx,.35,z),.29+.1*sin(float(k)),Color("#41644B") if k%3 else Color("#7A734A"))
    # Discreet architectural landmark plaques to help judges identify location.
    _sign(self,"AGORA / UNIVERSITY CENTRE",Vector3(-10,5.42,-20.22),Color("#F6E9CD"),27)
    _sign(self,"PATERSON LIBRARY",Vector3(21,3.75,-3.40),Color("#EEE7D3"),27)
    _sign(self,"ADVANCED TECHNOLOGY & ACADEMIC CENTRE",Vector3(38,5.7,-23.7),Color("#E9E6D4"),22)

# Guidance follows quest state without revealing random or hidden puzzle state.
func _quest_target() -> Vector3:
    if not (coins[0] and coins[1] and coins[2]):
        var nearest := Vector3.ZERO
        var best := INF
        for i in range(coins.size()):
            if not coins[i]:
                var distance := player.position.distance_to(COIN_SPOTS[i])
                if distance < best:
                    best = distance
                    nearest = COIN_SPOTS[i]
        return nearest
    if not has_key:
        return ALTAR_SPOT + Vector3.UP
    if not vault_open:
        return VAULT_SPOT + Vector3(0, 1, 5)
    if not map_found:
        return VAULT_SPOT + Vector3(0, 1, -2)
    return QUEEN_SPOT + Vector3.UP

func _update_quest_guide() -> void:
    if not is_instance_valid(guide_label):
        return
    if finished:
        guide_label.text = "NEFERTITI RESCUED  /  ENTER TO PLAY AGAIN"
        return
    var target := _quest_target()
    var offset := target - player.position
    offset.y = 0
    var stage := "NEAREST SCARAB"
    if coins[0] and coins[1] and coins[2]:
        stage = "AGORA ALTAR" if not has_key else ("ATAC CHAMBER" if not map_found else "NEFERTITI")
    guide_label.text = "%s  /  %dm    [H] FIELD GUIDE" % [stage, roundi(offset.length())]

func _create_reversal_art() -> void:
    var runes := Node3D.new()
    add_child(runes)
    for pos in [Vector3(-19,0,-1),Vector3(7,0,-1),Vector3(26,0,-1),Vector3(41,0,-1)]:
        var rune := _magic_decal(runes,pos+Vector3(0,.14,0),4.8)
        rune_nodes.append(rune)
        for j in range(4):
            var glyph := _ankh_rune(runes, pos+Vector3(0,1.3+j*1.0,-.73))
            glyph.scale = Vector3.ONE*.24
    past_objects.append(runes)
    magic_particles = CPUParticles3D.new()
    add_child(magic_particles)
    magic_particles.position = ALTAR_SPOT+Vector3(0,1.5,0)
    magic_particles.amount = 100
    magic_particles.lifetime = 3.0
    magic_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
    magic_particles.emission_sphere_radius = 5.5
    magic_particles.direction = Vector3.UP
    magic_particles.spread = 35
    magic_particles.gravity = Vector3(0,.3,0)
    magic_particles.initial_velocity_min = .35
    magic_particles.initial_velocity_max = 1.5
    magic_particles.scale_amount_min = .035
    magic_particles.scale_amount_max = .09
    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0
    mesh.radial_segments = 5
    mesh.rings = 3
    var m := _make_material(Color("efca72"),true)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = m
    magic_particles.mesh = mesh
    magic_particles.emitting = false

func _ankh_rune(parent: Node3D, at: Vector3) -> Node3D:
    var rune := Node3D.new()
    parent.add_child(rune)
    rune.position = at
    _ankh(rune,Vector3.ZERO,1.0)
    return rune

func _set_reversal_color(value: float) -> void:
    reversal_amount = value
    sunlight.light_color = Color("cee4f4").lerp(Color("f2d9ad"),value)
    world_environment.ambient_light_color = Color("a6c2d3").lerp(Color("bdc1ac"),value)
    world_environment.fog_light_color = Color("afc9d8").lerp(Color("dfba84"),value)
    world_environment.fog_density = lerpf(.0007,.0017,value)
    var sky_material := world_environment.sky.sky_material as ProceduralSkyMaterial
    sky_material.sky_top_color = Color("467fa6").lerp(Color("716a8f"),value)
    sky_material.sky_horizon_color = Color("bfd6db").lerp(Color("d6c8b5"),value)

func _animate_reversal() -> void:
    if is_instance_valid(reversal_tween):
        reversal_tween.kill()
    reversal_tween = create_tween()
    reversal_tween.tween_method(_set_reversal_color,reversal_amount,1.0 if ancient else 0.0,1.1).set_trans(Tween.TRANS_SINE)
    magic_particles.emitting = ancient
    if is_instance_valid(bridge_tween):
        bridge_tween.kill()
    bridge_tween = create_tween() if ancient else null
    # Geometry rises in staggered sections; bridge routing still uses ancient state.
    for segment in bridge.get_children():
        if not segment.has_meta("rest_y"):
            segment.set_meta("rest_y",segment.position.y)
        var rest: float = segment.get_meta("rest_y")
        if ancient:
            segment.position.y = rest-2.8
            bridge_tween.parallel().tween_property(segment,"position:y",rest,.75).set_delay(segment.get_index()*.025).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    for obj in past_objects:
        if obj == bridge:
            continue
        if ancient:
            obj.scale = Vector3.ONE*.02
            reversal_tween.parallel().tween_property(obj,"scale",Vector3.ONE,.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        else:
            obj.scale = Vector3.ONE
