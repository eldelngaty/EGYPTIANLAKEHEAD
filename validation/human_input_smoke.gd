extends SceneTree
# All progression uses screen clicks and ordinary key events. No teleporting,
# camera assignments, direct quest setters, or calls to gameplay action methods.
var failures := 0
var checks := 0
var game: Node
var capture_dir := ""
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, label: String) -> void:
    checks+=1
    if value: print("PASS: ",label)
    else:
        failures+=1
        push_error(label)
func pause(seconds := .15) -> void:
    await create_timer(seconds).timeout
func key(code: Key) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=true
    Input.parse_input_event(event)
    await process_frame
    event=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=false
    Input.parse_input_event(event)
    await pause()
func click(name: String) -> void:
    var control: Control=game.find_child(name,true,false)
    check(control!=null and control.is_visible_in_tree(),"Visible screen control: "+name)
    if control==null or not control.is_visible_in_tree(): return
    var point:=control.get_global_rect().get_center()
    var motion:=InputEventMouseMotion.new()
    motion.position=point
    motion.global_position=point
    root.push_input(motion,true)
    await process_frame
    for down in [true,false]:
        var event:=InputEventMouseButton.new()
        event.button_index=MOUSE_BUTTON_LEFT
        event.position=point
        event.global_position=point
        event.pressed=down
        root.push_input(event,true)
        await process_frame
    await pause(.4)
func screenshot(name: String) -> void:
    if capture_dir=="": return
    await RenderingServer.frame_post_draw
    var result:=root.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))
    check(result==OK,"Actual rendered screenshot: "+name)
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if not args.is_empty():
        capture_dir=args[0]
        DirAccess.make_dir_recursive_absolute(capture_dir)
    change_scene_to_file("res://main.tscn")
    await pause(.5)
    game=current_scene
    check(game!=null and game.tour_world!=null,"Existing real-photo project starts")
    check(game.player.visible,"Opening shot presents the guardian at human scale")
    check(game.find_child("GuardianPortrait",true,false)!=null,"Guardian stays recognizable in a live 3D portrait")
    await screenshot("00_guardian_intro")
    await pause(2.8)
    check(not game.player.visible,"First-person exploration avoids fake walking avatar")
    var position_before: Vector3=game.player.position
    await key(KEY_W)
    check(game.player.position==position_before,"No tiny-radius fake movement")
    check(game.objective_label.text.contains("Press R"),"First objective is explicit immediately")
    var rotation_before: Vector3=game.cam.rotation
    var drag:=InputEventMouseButton.new()
    drag.button_index=MOUSE_BUTTON_RIGHT
    drag.position=Vector2(640,360)
    drag.pressed=true
    root.push_input(drag,true)
    var motion:=InputEventMouseMotion.new()
    motion.position=Vector2(800,380)
    motion.relative=Vector2(160,20)
    root.push_input(motion,true)
    drag=InputEventMouseButton.new()
    drag.button_index=MOUSE_BUTTON_RIGHT
    drag.pressed=false
    root.push_input(drag,true)
    await pause()
    check(game.cam.rotation.distance_to(rotation_before)>.1,"Ordinary right-drag rotates the panorama")
    await click("Travel_corridor")
    check(game.tour_world.current_scene=="corridor","Screen click travels to Library")
    check(game.objective_label.text.contains("Agora"),"Off-route player is guided back to Agora")
    await click("Travel_agora")
    check(game.tour_world.current_scene=="agora","Screen click returns to Agora")
    await click("QuestHotspot")
    check(not game.coins[0],"Hidden scarab cannot be collected before reversal")
    await key(KEY_R)
    await pause(1.2)
    check(game.ancient and game.coin_nodes[0].visible,"Reversal reveals the first scarab")
    await screenshot("01_agora_revealed")
    await click("QuestHotspot")
    check(game.coins[0] and not game.coins[1],"First scarab collected by screen click without teleport")
    check(game.status_label.text.contains("1 / 3") and game.objective_label.text.contains("Library"),"Counter and next objective agree")
    await click("Travel_corridor")
    check(not game.ancient,"Library begins with its own present-day puzzle")
    await key(KEY_R)
    await pause(1.2)
    check(game.bridge.visible and game.coin_nodes[1].visible,"Reversal restores Library passage")
    var passage_screen: Vector2=game.cam.unproject_position(game.bridge.global_position+Vector3(.54,.65,0))
    check(Rect2(0,145,1280,430).has_point(passage_screen),"Restored passage is visible above navigation controls")
    await screenshot("02_library_passage")
    await click("QuestHotspot")
    check(game.coins[1],"Second scarab collected through ordinary click")
    await click("Travel_atac")
    await key(KEY_R)
    await pause(1.2)
    check(game.tour_world.temporal_lock.scale.y<.08,"ATAC time-lock geometry opens after reversal")
    await screenshot("03_atac_lock")
    await click("QuestHotspot")
    check(game.coins==[true,true,true],"All three scarabs collected using public input")
    check(game.status_label.text.contains("3 / 3") and game.objective_label.text.contains("Agora"),"Three-scarab objective sends player to shrine")
    await click("Travel_agora")
    await click("QuestHotspot")
    check(game.altar_started and game.tour_world.puzzle_panel.visible,"Altar opens clear symbol puzzle")
    await click("Altar_1")
    check(game.altar_step==0 and not game.has_key,"Wrong symbol does not grant key")
    await click("Altar_3")
    await key(KEY_2)
    await click("Altar_1")
    check(game.has_key and not game.altar_started,"Mouse and keyboard reverse order grants golden key")
    await click("Travel_atac")
    await click("QuestHotspot")
    check(game.vault_open,"Key opens map chest through a screen hotspot")
    await click("QuestHotspot")
    check(game.map_found and game.map_panel.visible,"Map is discovered through ordinary input")
    await screenshot("04_ancient_map")
    await click("MapTravel_lake")
    check(game.tour_world.current_scene=="lake" and not game.is_map_open,"Map travel button reaches Lake Tamblyn")
    await click("QuestHotspot")
    check(not game.finished and game.queen_cage.visible,"Present prison prevents premature rescue")
    await key(KEY_R)
    await pause(1.2)
    check(not game.queen_cage.visible,"Reversal removes the Queen's prison")
    # Hover and E use the same large highlighted target as the mouse.
    var target: Control=game.find_child("QuestHotspot",true,false)
    var hover:=InputEventMouseMotion.new()
    hover.position=target.get_global_rect().get_center()
    hover.global_position=hover.position
    root.push_input(hover,true)
    await pause(.2)
    await key(KEY_E)
    await pause(.45)
    await screenshot("05_rescue_closeup")
    await pause(1.0)
    check(game.finished and game.win_panel.visible,"Highlighted target + E completes actual rescue")
    await screenshot("06_victory")
    var previous:=game
    await click("RestartGame")
    await pause(.5)
    game=current_scene
    check(game!=previous and not game.finished and game.coins==[false,false,false],"Restart resets quest without developer shortcuts")
    check(game.tour_world.current_scene=="agora" and not game.ancient,"Restart restores initial location and reality")
    print("RESULT: ",checks-failures,"/",checks," passed; public screen/keyboard input only")
    if game.fx_player!=null: game.fx_player.stop()
    await pause(.2)
    quit(1 if failures else 0)
