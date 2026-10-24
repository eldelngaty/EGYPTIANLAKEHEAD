extends SceneTree
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(value: bool, description: String) -> void:
    if not value:
        push_error(description)
        failures += 1
        return
    print("PASS: ", description)

func run_checks() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(game.help_panel.visible, "Field guide opens on launch")
    var key := InputEventKey.new()
    key.keycode = KEY_ENTER
    key.pressed = true
    game._unhandled_key_input(key)
    check(not game.help_panel.visible, "Enter closes field guide")
    var start_position: Vector3 = game.player.position
    var move_key := InputEventKey.new()
    move_key.keycode = KEY_W
    move_key.pressed = true
    Input.parse_input_event(move_key)
    for frame in range(4):
        await physics_frame
    move_key.pressed = false
    Input.parse_input_event(move_key)
    check(game.player.position.distance_to(start_position) > .01, "Keyboard movement works with new camera")
    var reverse := InputEventKey.new()
    reverse.keycode = KEY_R
    reverse.pressed = true
    game._unhandled_key_input(reverse)
    check(game.ancient and game.bridge.visible, "R reveals ancient world and bridge")
    await create_timer(1.6).timeout
    check(game.reversal_amount > .99 and game.magic_particles.emitting, "Golden transition and magic particles complete")
    var restored := true
    for segment in game.bridge.get_children():
        restored = restored and absf(segment.position.y-float(segment.get_meta("rest_y"))) < .01
    check(restored, "Staggered bridge restoration reaches original geometry")
    game._unhandled_key_input(reverse)
    await create_timer(1.2).timeout
    check(not game.ancient and not game.bridge.visible and game.reversal_amount < .01, "R returns to present and hides bridge")
    game.player.position = game.COIN_SPOTS[0]
    game._interact()
    check(not game.coins[0], "Present-day scarabs cannot be collected")
    game.ancient = true
    game._update_world_state()
    for i in range(3):
        game.player.position = game.COIN_SPOTS[i]
        game._interact()
    check(game.coins == [true, true, true], "Three ancient scarabs collected")
    game.player.position = game.ALTAR_SPOT + Vector3.UP
    game._interact()
    game._try_altar_number(1)
    check(game.altar_step == 0, "Wrong altar order resets progress")
    for n in [3, 2, 1]:
        game._try_altar_number(n)
    check(game.has_key, "Reverse altar sequence grants key")
    game.player.position = game.VAULT_SPOT + Vector3(0, 1, 5)
    game._interact()
    check(game.vault_open, "Key opens chamber")
    game.player.position = game.VAULT_SPOT + Vector3(0, 1, -2)
    game._interact()
    check(game.map_found and game.is_map_open, "Map discovered and displayed")
    game._show_map(false)
    game.player.position = game.QUEEN_SPOT + Vector3.UP
    game._interact()
    check(game.finished and game.win_panel.visible, "Queen rescue completes game")
    game._update_quest_guide()
    check("RESCUED" in game.guide_label.text, "Guidance reflects completion")
    game.fx_player.stop()
    game.fx_player.stream = null
    await create_timer(0.2).timeout
    game.queue_free()
    await create_timer(0.2).timeout
    quit(1 if failures else 0)
