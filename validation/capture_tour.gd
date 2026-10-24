extends SceneTree
var game: Node3D
var output_dir: String
func _initialize() -> void:
    call_deferred("run")
func photo(id: String, angle: float, ancient: bool, filename: String) -> void:
    game.tour_world.set_scene(id)
    game.ancient = ancient
    game._update_world_state()
    game._animate_reversal()
    game.tour_world.yaw=deg_to_rad(angle)
    game.tour_world.pitch=-.05
    game.player.position=Basis(Vector3.UP,deg_to_rad(angle))*Vector3(.8,1,-2.7)
    game.player_model.rotation.y=deg_to_rad(angle)+PI
    game._update_hud()
    game.tour_world.update(0)
    game.message_label.text=""
    await create_timer(1.3).timeout
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(output_dir.path_join(filename))
    print("SCREENSHOT ",id," ",filename," status=",result)
    if result != OK:
        quit(1)
func run() -> void:
    output_dir=ProjectSettings.globalize_path("res://../screenshots")
    var args:=OS.get_cmdline_user_args()
    if not args.is_empty(): output_dir=args[0]
    DirAccess.make_dir_recursive_absolute(output_dir)
    game=load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game.set_process(false)
    game.set_physics_process(false)
    await photo("agora",-90,true,"real_tour_agora.png")
    await photo("corridor",35,true,"real_tour_library_approach.png")
    await photo("atac",0,true,"real_tour_atac.png")
    await photo("lake",-137,false,"real_tour_lake_prison.png")
    await photo("lake",-137,true,"real_tour_lake_reversed.png")
    game.fx_player.stop()
    game.fx_player.stream=null
    await create_timer(.2).timeout
    game.queue_free()
    await create_timer(.2).timeout
    quit()
