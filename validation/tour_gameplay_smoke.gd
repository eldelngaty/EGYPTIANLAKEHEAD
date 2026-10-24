extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, label: String) -> void:
    checks += 1
    if value: print("PASS: ",label)
    else:
        failures += 1
        push_error(label)
func press(game: Node, key: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = key
    event.pressed = true
    game._unhandled_key_input(event)
func act(game: Node, target: String, approach := true) -> void:
    var tour = game.tour_world
    var node: Node3D = tour.targets[target]
    var offset := .35 if target.begins_with("travel:") else (.65 if target in ["altar","vault","queen"] else 0.0)
    var point := node.global_position+Vector3(0,offset,0)
    var dir: Vector3 = (point-tour.camera_origin).normalized()
    tour.yaw=atan2(-dir.x,-dir.z)
    tour.pitch=asin(dir.y)
    if approach: game.player.position=node.global_position+Vector3.UP
    tour.update(0)
    check(tour.focus == target,"Gaze selects "+target)
    press(game,KEY_E)
func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(game.tour_world != null,"Authentic tour mode is default")
    var tour=game.tour_world
    check(tour.scenes.size()==4,"Four metadata-verified campus photo locations")
    check(tour.cube_root.get_child_count()==6,"Six real textured cube faces render environment")
    check(tour.current_scene=="agora","Pharaoh arrives in actual Agora Circle")
    var before: Vector3=game.player.position
    var move:=InputEventKey.new()
    move.keycode=KEY_W
    move.pressed=true
    Input.parse_input_event(move)
    for frame in range(4): await physics_frame
    move.pressed=false
    Input.parse_input_event(move)
    check(game.player.position.distance_to(before)>.01,"Avatar movement survives photo integration")
    game.set_physics_process(false)
    check(not game.coin_nodes[0].visible,"Present reality hides sacred scarabs")
    press(game,KEY_R)
    await create_timer(1.5).timeout
    check(game.ancient and game.coin_nodes[0].visible and not game.coin_nodes[1].visible,"R reveals only the current scene scarab")
    act(game,"coin0")
    check(game.coins[0],"Agora scarab collected")
    act(game,"travel:corridor",false)
    check(tour.current_scene=="corridor" and tour.gallery_board.visible,"Hotspot reaches Campus Corridor and real library gallery")
    check(tour.face_materials[0].get_shader_parameter("photo").resource_path.contains("corridor"),"Hotspot replaces photographs, not just scene label")
    act(game,"coin1")
    check(game.coins[1],"Library approach scarab collected")
    act(game,"travel:atac",false)
    check(tour.current_scene=="atac","Hotspot reaches verified ATAC panorama")
    act(game,"vault")
    check(not game.vault_open,"Map chest cannot open without golden key")
    act(game,"coin2")
    check(game.coins==[true,true,true],"Three scarabs collected in three separate photo scenes")
    act(game,"travel:lake",false)
    act(game,"queen")
    check(not game.finished,"Nefertiti cannot be rescued before map discovery")
    act(game,"travel:agora",false)
    act(game,"altar")
    check(game.altar_started,"Return to Agora starts shrine puzzle")
    press(game,KEY_1)
    check(game.altar_step==0,"Wrong reverse-order input resets puzzle")
    for key in [KEY_3,KEY_2,KEY_1]: press(game,key)
    check(game.has_key and not game.altar_started,"Reverse order 3-2-1 grants golden key")
    act(game,"travel:corridor",false)
    act(game,"travel:atac",false)
    act(game,"vault")
    check(game.vault_open,"Golden key opens ATAC map chest")
    act(game,"map")
    check(game.map_found and game.is_map_open and game.map_panel.visible,"Map discovered and Nefertiti location revealed")
    press(game,KEY_M)
    check(not game.is_map_open,"Map closes using existing control")
    act(game,"travel:lake",false)
    press(game,KEY_R)
    await create_timer(1.2).timeout
    act(game,"queen")
    check(not game.finished and game.queen_cage.visible,"Present-day temporal prison blocks rescue")
    press(game,KEY_R)
    await create_timer(1.5).timeout
    check(not game.queen_cage.visible and game.bridge.visible,"Reversal removes prison and restores lake bridge")
    act(game,"queen")
    check(game.finished and game.win_panel.visible,"Full Nefertiti rescue reaches original victory screen")
    print("RESULT: ",checks-failures,"/",checks," passed")
    game.fx_player.stop()
    game.fx_player.stream=null
    await create_timer(.2).timeout
    game.queue_free()
    await create_timer(.2).timeout
    quit(1 if failures else 0)
