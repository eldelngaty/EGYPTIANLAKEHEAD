extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    await create_timer(2.0).timeout
    assert(game.tour_world == null, "Default must be actual modeled 3D")
    var enter := InputEventKey.new()
    enter.keycode = KEY_ENTER
    enter.pressed = true
    Input.parse_input_event(enter)
    await process_frame
    var start: Vector3 = game.player.position
    var walk := InputEventKey.new()
    walk.keycode = KEY_W
    walk.pressed = true
    Input.parse_input_event(walk)
    await create_timer(0.35).timeout
    walk.pressed = false
    Input.parse_input_event(walk)
    assert(game.player.position.distance_to(start) > 0.5, "Actual 3D movement")
    var yaw: float = game.camera_yaw
    var button := InputEventMouseButton.new()
    button.button_index = MOUSE_BUTTON_RIGHT
    button.pressed = true
    root.push_input(button, true)
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(90, 0)
    root.push_input(motion, true)
    button.pressed = false
    root.push_input(button, true)
    await create_timer(1.0).timeout
    assert(absf(game.camera_yaw - yaw) > 0.1, "Mouse orbit works")
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("/workspace/sphinx_3d_release/3d_gameplay.png")
    print("PASS: modeled default, public-input movement, mouse orbit, actual screenshot")
    quit()
