extends SceneTree
# Public input end-to-end test. Reads positions for steering; never assigns player/camera/quest state.
var g
var failures:=0
var checks:=0
var captures:=false
var out:="/workspace/sphinx_adventure_release"
func _initialize() -> void:
    captures=DisplayServer.get_name()!="headless"
    call_deferred("run")
func check(ok: bool, words: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(words)
    else: print("PASS: ",words)
func key(code: int, down: bool=true) -> void:
    var e:=InputEventKey.new()
    e.keycode=code
    e.physical_keycode=code
    e.pressed=down
    Input.parse_input_event(e)
func tap(code: int) -> void:
    key(code)
    await process_frame
    key(code,false)
    await process_frame
func turn_to(direction: Vector3) -> void:
    var desired:=atan2(-direction.x,-direction.z)
    var difference:=angle_difference(g.adventure.yaw,desired)
    var event:=InputEventMouseMotion.new()
    event.relative=Vector2(-difference/g.adventure.mouse_sensitivity,0)
    root.push_input(event,true)
func walk(point: Vector3, tolerance:=.6, run_fast:=true) -> bool:
    var frame:=0
    var stuck:=0
    var previous:Vector3=g.player.position
    key(KEY_SHIFT,run_fast)
    while frame<2100:
        var direction:Vector3=point-g.player.position
        direction.y=0
        if direction.length()<tolerance:break
        turn_to(direction)
        key(KEY_W,true)
        await physics_frame
        frame+=1
        if frame%60==0:
            if g.player.position.distance_to(previous)<.08:stuck+=1
            else:stuck=0
            previous=g.player.position
            if stuck>=3:break
    key(KEY_W,false)
    key(KEY_SHIFT,false)
    for i in range(14):await physics_frame
    var reached:=Vector2(g.player.position.x-point.x,g.player.position.z-point.z).length()<tolerance+1
    check(reached,"Walked to "+str(point)+"; actual "+str(g.player.position))
    return reached
func shot(name: String) -> void:
    if not captures:return
    await create_timer(.35).timeout
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK,"Actual rendered screenshot "+name)
func find_button(node: Node, words: String) -> Button:
    for child in node.get_children():
        if child is Button and child.text==words:return child
        var found:=find_button(child,words)
        if found!=null:return found
    return null
func click(words: String) -> void:
    var b:=find_button(root,words)
    check(b!=null,"Visible UI button: "+words)
    if b==null:return
    var event:=InputEventMouseButton.new()
    event.position=b.get_global_rect().get_center()
    event.button_index=MOUSE_BUTTON_LEFT
    event.pressed=true
    root.push_input(event,true)
    event.pressed=false
    root.push_input(event,true)
    await process_frame
func run() -> void:
    g=load("res://main.tscn").instantiate()
    root.add_child(g)
    current_scene=g
    await create_timer(.8).timeout
    check(g.tour_world==null,"Default is walkable 3D, not panorama")
    check(g.adventure.hero.legs.size()==4,"Sphinx has four articulated IK legs")
    await shot("01_sphinx_arrival")
    await create_timer(3.0).timeout
    check(not g.help_panel.visible,"No blocking tutorial at startup")
    var before:float=g.adventure.zoom
    var wheel:=InputEventMouseButton.new()
    wheel.button_index=MOUSE_BUTTON_WHEEL_UP
    wheel.pressed=true
    root.push_input(wheel,true)
    await process_frame
    check(g.adventure.zoom<before,"Wheel zoom uses public input")
    await tap(KEY_ESCAPE)
    check(g.adventure.paused and g.adventure.pause_panel.visible,"ESC opens pause/settings")
    var start:Vector3=g.player.position
    key(KEY_W)
    for i in range(10):await physics_frame
    key(KEY_W,false)
    check(g.player.position.distance_to(start)<.02,"Pause blocks movement")
    await click("OFFICIAL TOUR / REFERENCE VIEW")
    check(g.adventure.reference_panel!=null,"Official photographic reference viewer opens")
    for scene_id in range(4):
        var texture=g.adventure.reference_panel.find_child("ReferenceTexture",true,false)
        check(texture!=null and texture.texture!=null,"Verified reference photo loaded for scene "+str(scene_id))
        if scene_id<3:await click("NEXT VERIFIED LOCATION")
    await click("ROTATE VIEW / NEXT CUBE FACE")
    await click("BACK TO GAME")
    await tap(KEY_ESCAPE)
    await tap(KEY_M)
    check(g.is_map_open,"Mission map available immediately")
    await tap(KEY_ESCAPE)
    await walk(Vector3(-5,1,-26.5),.4,false)
    await tap(KEY_E)
    check(not g.coins[0],"Present scarab cannot be collected")
    await tap(KEY_R)
    await create_timer(1.1).timeout
    check(g.ancient and g.coin_nodes[0].visible,"R materializes Agora scarab")
    await shot("02_agora_reversal")
    await tap(KEY_E)
    check(g.coins==[true,false,false],"First scarab collected by normal E")
    # Deliberately walk into the Agora facade; collision must stop the hero.
    turn_to(Vector3(0,0,1))
    key(KEY_W)
    await create_timer(2.5).timeout
    key(KEY_W,false)
    check(g.player.position.z< -18.5,"Cannot walk through Agora building")
    await walk(Vector3(10,1,-24))
    await walk(Vector3(10,1,-2))
    await walk(Vector3(21,1,-3.5))
    await tap(KEY_E)
    check(not g.coins[1],"Library time passage requires reversal")
    await tap(KEY_R)
    await create_timer(1).timeout
    check(g.adventure.library_restored and g.adventure.gate.scale.y<.1,"R restores library passage")
    turn_to(Vector3(0,0,1))
    await create_timer(.6).timeout
    await shot("03_library_passage")
    await tap(KEY_E)
    check(g.coins==[true,true,false],"Second scarab collected by walking")
    await walk(Vector3(26,1,-3))
    await walk(Vector3(26,1,-26))
    await walk(Vector3(35.6,1,-26),.7)
    await tap(KEY_R)
    await tap(KEY_E)
    check(g.adventure.mechanism_active,"ATAC ancient mechanism activated with E")
    await walk(Vector3(38,1,-26),.6,false)
    turn_to(Vector3(0,0,1))
    await create_timer(.6).timeout
    await shot("04_atac_mechanism")
    await tap(KEY_E)
    check(g.coins==[true,true,true],"All three scarabs collected without teleporting")
    await walk(Vector3(26,1,-26))
    await walk(Vector3(26,1,-3))
    await walk(Vector3(0,1,-3))
    await walk(Vector3(0,1,3.3))
    await tap(KEY_E)
    check(g.altar_started,"Agora altar reached and activated")
    await tap(KEY_1)
    check(g.altar_step==0 and not g.has_key,"Wrong altar input grants no key")
    for n in [KEY_3,KEY_2,KEY_1]:await tap(n)
    check(g.has_key,"3-2-1 grants golden key")
    await shot("05_altar_key")
    await walk(Vector3(11,1,0))
    await walk(Vector3(26,1,0))
    await walk(Vector3(49,1,0))
    await walk(Vector3(49,1,-20))
    await tap(KEY_E)
    check(g.vault_open,"Golden key opens ATAC chamber")
    await walk(Vector3(49,1,-27))
    await tap(KEY_E)
    check(g.map_found and g.is_map_open,"Secret map found by walking into chamber")
    await shot("06_secret_map")
    await tap(KEY_M)
    await walk(Vector3(49,1,0))
    await walk(Vector3(-17,1,0))
    await walk(Vector3(-17,1,20))
    turn_to(Vector3(-1,0,0))
    key(KEY_W)
    await create_timer(2.0).timeout
    key(KEY_W,false)
    check(g.player.position.x> -21,"Present water blocks crossing without a bridge")
    await tap(KEY_R)
    await create_timer(1.3).timeout
    check(g.bridge.visible and g.ancient,"Lake bridge restored with R")
    await shot("07_lake_bridge")
    await walk(Vector3(-46,1,20),1.4)
    await tap(KEY_E)
    check(g.finished,"Nefertiti rescued through complete walking quest")
    await create_timer(1.1).timeout
    await shot("08_rescue")
    check(g.queen.position.distance_to(Vector3(g.player.position.x,0,g.player.position.z))>2.0,"Rescue composition clearly separates Sphinx and Nefertiti")
    await create_timer(2.8).timeout
    check(g.win_panel.visible,"Victory follows short cinematic")
    await shot("09_victory")
    await tap(KEY_ENTER)
    await create_timer(.8).timeout
    var restarted=current_scene
    # Main was added to root by harness, so reload_current_scene can lack current_scene.
    check(restarted!=null and restarted.coins==[false,false,false] and not restarted.finished,"Enter restarts entire mission")
    print("RESULT: ",checks-failures,"/",checks," checks passed")
    quit(1 if failures else 0)
