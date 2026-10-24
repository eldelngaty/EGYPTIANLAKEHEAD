extends SceneTree
# Asset, layout and named-navigation regression checks. Full completion by public
# input is in human_input_smoke.gd; the former teleport-and-aim harness is retired.
var checks:=0
var failures:=0
var game: Node
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
    checks+=1
    if value: print("PASS: ",label)
    else:
        failures+=1
        push_error(label)
func click(control: Control) -> void:
    var p:=control.get_global_rect().get_center()
    var move:=InputEventMouseMotion.new()
    move.position=p
    root.push_input(move,true)
    for down in [true,false]:
        var e:=InputEventMouseButton.new()
        e.position=p
        e.button_index=MOUSE_BUTTON_LEFT
        e.pressed=down
        root.push_input(e,true)
        await process_frame
    await create_timer(.1).timeout
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await create_timer(.4).timeout
    game=current_scene
    var tour=game.tour_world
    check(tour.scenes.size()==4,"Four authentic panoramas retained")
    var expected: Dictionary={"agora":13,"corridor":18,"atac":20,"lake":11}
    for scene in tour.scenes:
        check(scene.verified and int(scene.page_id)==expected[scene.id],"Verified official source identity: "+scene.id)
        for face in scene.faces:
            var path: String=scene.texture_folder+"/"+face+".png"
            var texture: Texture2D=load(path)
            check(texture!=null and texture.get_width()==1024 and texture.get_height()==1024,"Offline photo texture: "+scene.id+"/"+face)
    var portrait: Control=game.find_child("GuardianPortrait",true,false)
    check(portrait.get_global_rect().size.x<=96,"Portrait has compact readable HUD size")
    check(not portrait.get_global_rect().intersects(game.objective_label.get_global_rect()),"Portrait does not overlap objective")
    var viewport:=Rect2(0,0,1280,720)
    for id in ["lake","atac","agora","corridor","lake","agora"]:
        var button: Button=game.find_child("Travel_"+id,true,false)
        check(viewport.encloses(button.get_global_rect()),"Navigation fits 1280x720: "+id)
        await click(button)
        check(tour.current_scene==id,"Named screen hotspot selects correct verified location: "+id)
        var material: ShaderMaterial=tour.face_materials[0]
        var texture: Texture2D=material.get_shader_parameter("photo")
        check(texture.resource_path.contains("/"+id+"/"),"Navigation changes actual photograph: "+id)
    check(viewport.encloses(tour.hotspot.get_global_rect()),"Current objective hotspot stays on screen")
    check(game.coins==[false,false,false] and not game.has_key,"Navigation alone never grants quest progress")
    print("RESULT: ",checks-failures,"/",checks," passed; assets, public navigation, layout")
    game.fx_player.stop()
    await create_timer(.2).timeout
    quit(1 if failures else 0)
