extends Node3D
# Third-person presentation adapter. Inventory, altar, key/map and victory remain in main.gd.
var g: Node
var hero
var zoom := 7.7
var pitch := .28
var yaw := PI
var mouse_sensitivity := .003
var paused := false
var intro := 3.5
var victory_time := 0.0
var victory_queen_goal := Vector3.ZERO
var library_restored := false
var mechanism_active := false
var turn_velocity := 0.0
var last_safe := Vector3.ZERO
var hud: Control
var marker: Label
var prompt: Label
var title: Label
var subtitle: Label
var radar: Control
var mission_map: Control
var pause_panel: PanelContainer
var reference_panel: PanelContainer
var intro_panel: Control
var passage: Node3D
var gate: Node3D
var mechanic: Node3D
var atac_lock: Node3D
var passage_body: StaticBody3D
var glyphs: Control
var wash: ColorRect
var fade := 0.0
var photo_scene: Node3D
var source_index := 0
var reference_face := 0
const SCENES=["agora","library_approach","atac","lake_tamblyn"]
var tour_manifest: Dictionary

func setup(game: Node) -> void:
    g=game
    hero=preload("res://sphinx_hero.gd").new()
    for child in g.player_model.get_children(): child.free()
    hero.build_sphinx(g.player_model)
    g.player.position=Vector3(-5,1,-32)
    last_safe=g.player.position
    g.player_model.rotation.y=PI
    g.bridge.position=Vector3(4,-.60,0)
    g.bridge.scale.x=1.5
    # The camera is perspective and all world surfaces are genuine collision geometry.
    g.queen.scale=Vector3.ONE*.66
    var queen_body:=StaticBody3D.new()
    g.queen.add_child(queen_body)
    var queen_collision:=CollisionShape3D.new()
    var queen_shape:=CapsuleShape3D.new()
    queen_shape.radius=.7
    queen_shape.height=3.0
    queen_collision.shape=queen_shape
    queen_collision.position.y=1.5
    queen_body.add_child(queen_collision)
    g.cam.fov=62
    g.sunlight.light_energy=1.05
    g.sunlight.light_color=Color("fff0d5")
    g.world_environment.ambient_light_energy=.62
    g.world_environment.ambient_light_color=Color("b9c8d4")
    # Remove legacy floating instruction boards; physical facade signage remains.
    clean_labels(g)
    g.locator.hide()
    passage=Node3D.new()
    add_child(passage)
    passage.position=g.COIN_SPOTS[1]-Vector3(0,1.6,0)
    for x in [-1.7,1.7]:
        g._box(passage,Vector3(x,1.8,0),Vector3(.32,3.6,.4),Color("bc9b63"))
    g._box(passage,Vector3(0,3.55,0),Vector3(3.8,.32,.55),Color("dec17c"))
    gate=Node3D.new()
    passage.add_child(gate)
    for x in [-1.2,-.6,0,.6,1.2]:
        g._box(gate,Vector3(x,1.7,0),Vector3(.085,3.3,.12),Color("63b4db"))
    passage_body=StaticBody3D.new()
    gate.add_child(passage_body)
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=Vector3(3.4,3.2,.2)
    collision.shape=shape
    collision.position.y=1.6
    passage_body.add_child(collision)
    atac_lock=Node3D.new()
    add_child(atac_lock)
    atac_lock.position=g.COIN_SPOTS[2]-Vector3(0,1.6,0)
    for i in range(12):
        var a:=TAU*i/12
        g._cylinder(atac_lock,Vector3(cos(a)*1.25,1.3,sin(a)*1.25),.035,2.6,Color("4f9dca"))
    g._ring(atac_lock,Vector3(0,2.65,0),1.25,Color("84d4e8"),true)
    mechanic=Node3D.new()
    add_child(mechanic)
    mechanic.position=g.COIN_SPOTS[2]-Vector3(0,1.6,0)+Vector3(-2.4,0,0)
    g._cylinder(mechanic,Vector3(0,.6,0),.55,1.2,Color("b69461"))
    g._ankh(mechanic,Vector3(0,1.7,0),.65)
    g._ring(self,g.COIN_SPOTS[2]+Vector3(0,-1.35,0),1.8,Color("e9c368"),true)
    # A real curb prevents silently walking into the lake outside the restored span.
    for z in [9.0,31.0]:
        g._box(g,Vector3(-32,.25,z),Vector3(24,.5,.32),Color("7d8d83"))
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func clean_labels(node: Node) -> void:
    for child in node.get_children():
        if child is Label3D and child.billboard != BaseMaterial3D.BILLBOARD_DISABLED: child.hide()
        else: clean_labels(child)

func panel(at: Vector2, dimensions: Vector2, parent: Node) -> PanelContainer:
    var p:=PanelContainer.new()
    parent.add_child(p)
    p.position=at
    p.size=dimensions
    var s:=StyleBoxFlat.new()
    s.bg_color=Color("0d1c29ed")
    s.border_color=Color("c9ac69")
    s.set_border_width_all(1)
    s.set_corner_radius_all(12)
    s.set_content_margin_all(18)
    p.add_theme_stylebox_override("panel",s)
    return p
func label(at: Vector2, words: String, font_size: int, parent: Node) -> Label:
    var l:=Label.new()
    parent.add_child(l)
    l.position=at
    l.text=words
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",Color("f3e6c8"))
    l.add_theme_color_override("font_shadow_color",Color("091725"))
    l.add_theme_constant_override("shadow_offset_y",2)
    l.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return l
func button(words: String, parent: Node, action: Callable) -> Button:
    var b:=Button.new()
    parent.add_child(b)
    b.text=words
    b.custom_minimum_size=Vector2(250,42)
    b.pressed.connect(action)
    return b

func create_hud() -> void:
    g.hud_root=CanvasLayer.new()
    g.add_child(g.hud_root)
    hud=Control.new()
    g.hud_root.add_child(hud)
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var top:=panel(Vector2(22,20),Vector2(560,100),hud)
    var box:=VBoxContainer.new()
    top.add_child(box)
    g.status_label=label(Vector2.ZERO,"SPHINX / LAKEHEAD RESCUE",13,box)
    g.objective_label=label(Vector2.ZERO,"",21,box)
    subtitle=label(Vector2.ZERO,"",14,box)
    g.message_label=label(Vector2(28,132),"",17,hud)
    g.hint_label=label(Vector2(350,620),"",20,hud)
    g.hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    g.hint_label.size=Vector2(580,38)
    g.guide_label=label(Vector2(26,682),"WASD move   SHIFT run   Mouse look   Wheel zoom   E interact   R reverse   M map   ESC pause",14,hud)
    marker=label(Vector2.ZERO,"◆",30,hud)
    marker.add_theme_color_override("font_color",Color("ffd56d"))
    prompt=label(Vector2.ZERO,"",17,hud)
    radar=preload("res://campus_radar.gd").new()
    radar.game=g
    hud.add_child(radar)
    radar.position=Vector2(1042,20)
    radar.size=Vector2(216,174)
    radar.mouse_filter=Control.MOUSE_FILTER_IGNORE
    g.help_panel=panel(Vector2.ZERO,Vector2.ZERO,hud)
    g.help_panel.hide()
    g.map_panel=panel(Vector2(230,130),Vector2(820,460),hud)
    var mapbox:=VBoxContainer.new()
    g.map_panel.add_child(mapbox)
    mission_map=preload("res://campus_radar.gd").new()
    mission_map.game=g
    mission_map.full=true
    mission_map.custom_minimum_size=Vector2(780,365)
    mapbox.add_child(mission_map)
    label(Vector2.ZERO,"Yellow: current mission   Cyan: you   |   M / ESC: return",16,mapbox)
    g.map_panel.hide()
    g.win_panel=panel(Vector2(360,180),Vector2(560,325),hud)
    var vb:=VBoxContainer.new()
    g.win_panel.add_child(vb)
    label(Vector2.ZERO,"NEFERTITI IS FREE",34,vb)
    label(Vector2.ZERO,"The Sphinx has reversed the curse.\nLakehead's two realities are at peace.",20,vb)
    button("PLAY AGAIN / ENTER",vb,func(): get_tree().reload_current_scene())
    g.win_panel.hide()
    pause_panel=panel(Vector2(415,145),Vector2(450,430),hud)
    var menu:=VBoxContainer.new()
    pause_panel.add_child(menu)
    label(Vector2.ZERO,"PAUSED",30,menu)
    button("RESUME",menu,func(): set_paused(false))
    label(Vector2.ZERO,"Mouse sensitivity",16,menu)
    var slider:=HSlider.new()
    menu.add_child(slider)
    slider.min_value=.001
    slider.max_value=.007
    slider.step=.0002
    slider.value=mouse_sensitivity
    slider.value_changed.connect(func(value): mouse_sensitivity=value)
    button("OFFICIAL TOUR / REFERENCE VIEW",menu,open_reference)
    button("RESTART MISSION",menu,func(): get_tree().reload_current_scene())
    button("QUIT",menu,func(): get_tree().quit())
    pause_panel.hide()
    intro_panel=panel(Vector2(22,150),Vector2(560,145),hud)
    var story:=VBoxContainer.new()
    intro_panel.add_child(story)
    label(Vector2.ZERO,"YOU ARE THE SPHINX.",29,story)
    label(Vector2.ZERO,"NEFERTITI IS TRAPPED IN TIME.\nFIND THE THREE SACRED SCARABS TO SAVE HER.",20,story)
    wash=ColorRect.new()
    hud.add_child(wash)
    wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    wash.color=Color(1,.7,.2,0)
    g.message_label.text=""

func set_paused(value: bool) -> void:
    paused=value
    pause_panel.visible=value
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED

func handle(event: InputEvent) -> bool:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE:
            if reference_panel!=null and reference_panel.visible: close_reference()
            elif g.is_map_open: g._show_map(false); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
            elif g.altar_started: g.altar_started=false
            else: set_paused(not paused)
            return true
        if event.keycode==KEY_M and not paused:
            g._show_map(not g.is_map_open)
            Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if g.is_map_open else Input.MOUSE_MODE_CAPTURED
            return true
        if event.keycode in [KEY_H,KEY_V,KEY_C]:return true
    if paused or g.is_map_open or intro>0:return true
    if event is InputEventMouseMotion:
        yaw-=event.relative.x*mouse_sensitivity
        pitch=clampf(pitch+event.relative.y*mouse_sensitivity,.12,.95)
        return true
    if event is InputEventMouseButton and event.pressed:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom=clampf(zoom-.65,5.5,13)
        if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom=clampf(zoom+.65,5.5,13)
        return true
    return false

func move(delta: float) -> void:
    if paused or intro>0 or g.is_map_open or g.altar_started or g.finished:
        g.player.velocity=g.player.velocity.move_toward(Vector3.ZERO,delta*22)
        return
    var input:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W))).normalized()
    var forward:=Vector3(-sin(yaw),0,-cos(yaw))
    var right:=Vector3(cos(yaw),0,-sin(yaw))
    var direction:=right*input.x-forward*input.y
    var speed:=7.4 if Input.is_key_pressed(KEY_SHIFT) else 4.0
    g.player.velocity=g.player.velocity.move_toward(direction*speed,delta*(45 if input.length()<.1 else 22))
    var before:Vector3=g.player.position
    g.player.move_and_slide()
    g.player.position.x=clampf(g.player.position.x,-56,57)
    g.player.position.z=clampf(g.player.position.z,-41,45)
    # Lake is an obstacle; only the restored bridge is a traversable crossing.
    var flat:=Vector2(g.player.position.x+32,(g.player.position.z-20)/.88)
    if flat.length()<11.3 and flat.length()>3 and not (g.ancient and absf(g.player.position.z-20)<1.6):
        g.player.position=before
        g.player.velocity=Vector3.ZERO
    var bridge_height:=1.17 if g.ancient and g.player.position.x< -20 and g.player.position.x> -44 and absf(g.player.position.z-20)<1.6 else 1.0
    g.player.position.y=move_toward(g.player.position.y,bridge_height,delta*1.5)
    var actual:Vector3=(g.player.position-before)/maxf(delta,.001)
    if actual.length()>.08:
        var wanted:=atan2(actual.x,actual.z)
        turn_velocity=angle_difference(g.player_model.rotation.y,wanted)
        g.player_model.rotation.y=rotate_toward(g.player_model.rotation.y,wanted,delta*5.5)
    hero.animate_sphinx(delta,actual.length(),turn_velocity)
    last_safe=g.player.position

func target() -> Vector3:
    for i in range(3):
        if not g.coins[i]:
            if i==2 and not mechanism_active:return mechanic.global_position+Vector3.UP
            return g.COIN_SPOTS[i]
    if not g.has_key:return g.ALTAR_SPOT+Vector3.UP
    if not g.vault_open:return g.VAULT_SPOT+g.vault_entry_offset
    if not g.map_found:return g.VAULT_SPOT+g.map_pickup_offset
    if not g.ancient and g.player.position.x> -38:return Vector3(-17,1,20)
    return g.QUEEN_SPOT+Vector3.UP

func allowed(key: String) -> bool:
    if key.begins_with("coin"):
        var i:=int(key.right(1))
        for j in range(i):
            if not g.coins[j]:return false
        if i==1:return library_restored
        if i==2:return mechanism_active
    return true

func intercept() -> bool:
    if paused or intro>0:return true
    if g.coins[1] and not g.coins[2] and not mechanism_active and g.player.position.distance_to(mechanic.global_position+Vector3.UP)<3.5:
        if g.ancient:
            mechanism_active=true
            var unlock:=create_tween()
            unlock.tween_property(atac_lock,"scale:y",.01,.65).set_trans(Tween.TRANS_CUBIC)
            unlock.parallel().tween_property(mechanic,"rotation:y",TAU,1.2)
            g._flash("TIME MECHANISM RESTORED / Collect the third scarab",2.5)
            g._play_sfx("res://assets/unlock.wav")
            on_reversal()
        else:g._flash("PRESS R / Awaken the ancient mechanism",2.0)
        return true
    return false

func on_reversal() -> void:
    fade=1.0
    glyphs=preload("res://reversal_glyphs.gd").new()
    hud.add_child(glyphs)
    if g.coins[0] and not g.coins[1] and g.ancient and g.player.position.distance_to(g.COIN_SPOTS[1])<8:
        library_restored=true
        passage_body.collision_layer=0
        var tween:=create_tween()
        tween.tween_property(gate,"scale:y",.02,.8).set_trans(Tween.TRANS_CUBIC)
    if g.magic_particles!=null:g.magic_particles.global_position=g.player.global_position+Vector3.UP

func update(delta: float) -> void:
    intro=maxf(0,intro-delta)
    intro_panel.visible=intro>0
    if g.finished:
        if victory_time==0:
            victory_queen_goal=Vector3(g.player.position.x-2.4,0,g.player.position.z)
        victory_time+=delta
        # Nefertiti steps clear of the prison into a two-character victory composition.
        g.queen.position=g.queen.position.move_toward(victory_queen_goal,delta*1.4)
        g.player_model.rotation.y=rotate_toward(g.player_model.rotation.y,0,delta*2.5)
        g.queen.rotation.y=rotate_toward(g.queen.rotation.y,0,delta*2.5)
    var focus:Vector3=g.player.global_position+Vector3(0,.7,.3)
    var orbit:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*zoom
    if intro>0:
        focus=g.player.global_position+Vector3(0,.65,.35)
        orbit=Vector3(-4.7,2.0,-6.0)
    elif g.finished:
        focus=(g.player.global_position+g.queen.global_position)*.5+Vector3(0,1.5,0)
        orbit=Vector3(0,2.8,8.2)
    var desired:=focus+orbit
    var ray:=PhysicsRayQueryParameters3D.create(focus,desired,1)
    ray.exclude=[g.player.get_rid()]
    var hit:Dictionary=g.get_world_3d().direct_space_state.intersect_ray(ray)
    if not hit.is_empty():desired=hit.position+hit.normal*.5
    # Snap inward for obstruction, smooth outward for release. Radius checks around camera.
    for side in [-1,1]:
        var probe:=PhysicsRayQueryParameters3D.create(focus+Vector3(side*.23,.18,0),desired+Vector3(side*.23,.18,0),1)
        var obstacle:Dictionary=g.get_world_3d().direct_space_state.intersect_ray(probe)
        if not obstacle.is_empty() and obstacle.position.distance_to(focus)<desired.distance_to(focus):desired=obstacle.position+obstacle.normal*.5
    if g.cam.global_position.distance_to(focus)>desired.distance_to(focus)+.2:g.cam.global_position=desired
    else:g.cam.global_position=g.cam.global_position.lerp(desired,1-exp(-delta*9))
    g.cam.look_at(focus)
    if paused:hero.animate_sphinx(delta,0,0)
    elif intro>0 or g.finished:hero.animate_sphinx(delta,0,0)
    g.player_model.position.y=-1
    fade=maxf(0,fade-delta*1.4)
    wash.color=Color(1,.7,.18,fade*.2) if g.ancient else Color(.12,.52,1,fade*.15)
    g.win_panel.visible=g.finished and victory_time>2.5
    if g.finished and victory_time>2.5:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    if g.is_map_open:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    if not mechanism_active:
        g.coin_nodes[2].visible=false
    update_hud()

func update_hud() -> void:
    var count:=int(g.coins[0])+int(g.coins[1])+int(g.coins[2])
    g.status_label.text="SPHINX  /  %d OF 3 SCARABS   ·   %s" % [count,"ANCIENT ECHO" if g.ancient else "PRESENT DAY"]
    var place: String=["AGORA","PATERSON LIBRARY","ATAC"][mini(count,2)]
    var objective: String="GO TO THE "+place
    if count==3:objective="RETURN TO THE AGORA ALTAR" if not g.has_key else ("OPEN THE ATAC MAP CHAMBER" if not g.map_found else "RESCUE NEFERTITI / LAKE TAMBLYN")
    var distance:float=Vector2(target().x-g.player.position.x,target().z-g.player.position.z).length()
    var hint:="Follow the yellow marker"
    if distance<4.3:
        if count<3:
            if count==1 and not library_restored:hint="R  /  RESTORE THE TIME PASSAGE"
            elif count==2 and not mechanism_active:hint="E  /  ACTIVATE MECHANISM" if g.ancient else "R  /  AWAKEN THE MECHANISM"
            else:hint="E  /  COLLECT THE SACRED SCARAB" if g.ancient else "R  /  REVEAL THE SCARAB"
        elif not g.has_key:hint="E  /  ACTIVATE THE ALTAR"
        elif not g.vault_open:hint="E  /  UNLOCK WITH THE GOLDEN KEY"
        elif not g.map_found:hint="E  /  TAKE THE SECRET MAP"
        elif not g.ancient:hint="R  /  RESTORE THE BRIDGE AND FREE THE PRISON"
        else:hint="E  /  FREE NEFERTITI"
    if g.altar_started:hint="REVERSE THE SYMBOLS: 3 → 2 → 1    /    %d OF 3" % g.altar_step
    if g.finished:objective="NEFERTITI IS FREE";hint=""
    g.objective_label.text=objective
    subtitle.text="%d m  /  %s" % [roundi(distance),hint] if distance>=4.3 else hint
    g.hint_label.text=hint if distance<4.3 else ""
    radar.queue_redraw()
    mission_map.queue_redraw()
    var point:Vector3=target()+Vector3(0,2,0)
    var location:=Vector2(640,350)
    if not g.cam.is_position_behind(point):location=g.cam.unproject_position(point)
    else:
        var relative:Vector3=g.cam.to_local(point)
        location=Vector2(1230 if relative.x>0 else 30,350)
    location=location.clamp(Vector2(28,205),Vector2(1210,570))
    marker.position=location-Vector2(12,20)
    marker.visible=not g.finished and intro<=0 and not paused and not g.is_map_open
    prompt.position=location+Vector2(-45,20)
    prompt.text="%dm" % roundi(distance)
    prompt.visible=marker.visible

func open_reference() -> void:
    pause_panel.hide()
    source_index=0
    reference_face=0
    tour_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/tour/manifest.json"))
    reference_panel=panel(Vector2(120,65),Vector2(1040,590),hud)
    var vb:=VBoxContainer.new()
    reference_panel.add_child(vb)
    title=label(Vector2.ZERO,"",20,vb)
    var texture:=TextureRect.new()
    vb.add_child(texture)
    texture.name="ReferenceTexture"
    texture.custom_minimum_size=Vector2(980,430)
    texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var row:=HBoxContainer.new()
    vb.add_child(row)
    button("NEXT VERIFIED LOCATION",row,func(): source_index=(source_index+1)%4;show_reference(texture))
    button("ROTATE VIEW / NEXT CUBE FACE",row,func(): reference_face=(reference_face+1)%6;show_reference(texture))
    button("BACK TO GAME",row,close_reference)
    show_reference(texture)

func show_reference(texture: TextureRect) -> void:
    var entries: Array=tour_manifest.get("scenes",[])
    if entries.size()!=4:return
    var scene:Dictionary=entries[source_index]
    var faces:Dictionary=scene.get("faces",{})
    var keys:=faces.keys()
    if keys.size()<6:return
    var value=faces[keys[reference_face]]
    var path: String=value if value is String else value.get("local_file",value.get("file",""))
    if not path.begins_with("res://"):path=str(scene.get("texture_folder",""))+"/"+path
    texture.texture=load(path)
    title.text="OFFICIAL TOUR REFERENCE / "+str(scene.get("title",scene.get("name","")))+" / "+str(keys[reference_face])+"\nPhotographic viewpoint. Separate from the walkable 3D model."

func close_reference() -> void:
    if reference_panel!=null:reference_panel.queue_free();reference_panel=null
    pause_panel.show()
