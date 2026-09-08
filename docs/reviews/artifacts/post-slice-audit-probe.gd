extends SceneTree
func _initialize() -> void:
    call_deferred("run_review")
func run_review() -> void:
    var view = load("res://scenes/live_view.tscn").instantiate()
    root.add_child(view)
    view.set_process(false)
    await process_frame
    var plate: Dictionary = view.simulation.state.rings[1].wedges[1]
    plate.max_hp = 400.0
    plate.hp = 50.0
    var valid = RingPurchaseRules.validate_state(view.simulation.state, view.profile).is_empty()
    var observed = view._ring_status_records()[0].wedges[0]
    print("AUDIT maxHP state_valid=%s hp=50 max_hp=400 expected=critical actual=%s" % [valid, observed])
    var created = LiveSimulation.create(view.profile, 12)
    view.simulation = created.simulation
    view.simulation.state.energy = 1000000
    for index in 11:
        assert(view.simulation.purchase_ring(3, 1).ok)
    view.sync_simulation()
    view._on_ring_status_focus(12, 12)
    print("AUDIT outer_focus rings=%d world_grid=%d selected=%s world_cell_at_focus=%s" % [view.state.rings.size(), view.grid.ring_count, view.selected_cell, view.grid.world_to_cell(view.camera.position)])
    quit(0 if valid and observed == "ok" and view.grid.ring_count == 3 else 1)
