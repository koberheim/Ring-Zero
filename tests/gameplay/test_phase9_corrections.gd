extends SceneTree
const DT := 1.0/60.0
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func sim(rings: int = 2, overrides: Dictionary = {}) -> LiveSimulation:
	var p: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile.with_overrides({"pressure":{"spawn_per_second":0},"flak":{"damage":0}}).profile.with_overrides(overrides).profile
	var s: LiveSimulation = LiveSimulation.create(p, 5).simulation
	s.state.energy=100000
	for r in range(2,rings+1): s.purchase_ring()
	return s
func transfer(s: LiveSimulation) -> int:
	return s.pool.spawn({"kind":&"transfer","hopped":true,"hop_cell":Vector2i(2,1),"position":PolarPosition.new(2,1,0,.5),"hp":100.0,"damage_per_second":6.0,"speed_ring_widths_per_second":1.0,"assimilation_stacks":[],"stun_remaining":0.0})
func _initialize() -> void:
	var s:=sim()
	s.place_wall(1,1)
	var id:=transfer(s)
	var hp:float=s.state.rings[1].wedges[1].wall.hp
	check(s.step(DT).ok and s.state.rings[1].wedges[1].wall.hp==hp,"Transfer detours rather than attacks inner wall while exposed neighbor exists")
	s=sim()
	s.place_terrain(1,1,0,&"debris_field")
	id=transfer(s)
	hp=s.state.rings[1].wedges[1].hp
	check(s.step(DT).ok and s.state.rings[1].wedges[1].hp==hp,"Transfer respects inner debris")
	s=sim()
	s.state.rings[1].wedges[1].hp=0
	id=transfer(s)
	check(s.step(DT).ok and s.core_hp==200 and s.pool.payload_for(id).position.ring==1 and absf(s.pool.payload_for(id).position.radial_fraction-(1.0-1.0/60.0))<1e-8,"Transfer crossing broken inner band spends travel time")
	s=sim(1,{"assembler":{"growth_damage_per_stack":1e308}})
	s.state.rings[1].wedges[1].hp=0
	id=s.pool.spawn({"kind":&"assembler","growth_stacks":2,"position":PolarPosition.new(1,1,0,.5),"hp":100.0,"damage_per_second":6.0,"speed_ring_widths_per_second":1.0,"assimilation_stacks":[],"stun_remaining":0.0})
	var before:=s.state.duplicate(true)
	check(not s.step(DT).ok and s.state==before and s.core_hp==200 and s.elapsed_seconds==0,"Assembler computed overflow fails atomically even on core-loss path")
	_extra_checks()
	print("Phase9 corrections: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

func _extra_checks() -> void:
	var s:=sim()
	s.place_wall(1,1)
	var id:=transfer(s)
	check(s.step(DT).ok,"Transfer starts private angular boundary route")
	var original:PolarPosition=s.pool.payload_for(id).position
	var before:=s.state.duplicate(true)
	var nav:=s._navigation
	var private_nav:=s._transfer_navigation.duplicate()
	var paths:=s._waypoints.duplicate()
	var summary:=s.run_summary()
	s.cooldowns={&"bad":1.0}
	check(not s.step(DT).ok and s.state==before and s._navigation==nav and s._transfer_navigation==private_nav and s._waypoints==paths and s.pool.payload_for(id).position==original and s.run_summary()==summary,"Failed boundary movement retains private cache, waypoint, original position and accounting")
	s.cooldowns={}
	var second:=transfer(s)
	check(s.step(DT).ok and s._transfer_navigation.size()==1 and s._transfer_navigation[2]==private_nav[2],"Transfers reuse one immutable boundary graph per skipped ring")
	check(not s._navigation.has_cell(Vector2i(2,1)),"Private corridor never opens intact skipped ring to other machines")
	# All inner debris is legal with intact outer frontier; Transfer waits safely.
	s=sim()
	for wedge in range(1,13): s.state.rings[1].wedges[wedge].occupants[1]={"kind":&"debris_field"}
	id=transfer(s)
	before=s.state.duplicate(true)
	check(s.step(DT).ok and s.state==before and s.pool.payload_for(id).position.ring==2,"Sealed inner target waits without wall/debris violation")
	s.state.rings[1].wedges[2].hp=0
	check(s.step(DT).ok and s.pool.payload_for(id).position.angular_fraction>.5,"Topology change wakes waiting Transfer toward new route")
	# Screen on ring1 slows physical angular movement on the skipped-ring boundary.
	s=sim()
	s.place_wall(1,1)
	s.place_terrain(1,1,0,&"occlusion_screen")
	id=transfer(s)
	check(s.step(DT).ok,"Shadowed boundary travel")
	var angle:float=s.pool.payload_for(id).position.angular_fraction-.5
	check(absf(absf(angle)*TAU/12.0*192.0-.8)<1e-8,"Transfer boundary shadow uses physical half speed")
	# Both a gain and a multiplier must be representable before any commit.
	for override in [{"growth_hp_per_stack":1e308},{"growth_damage_per_stack":0.0}]:
		s=sim(1,{"assembler":override})
		s.state.rings[1].wedges[1].hp=.01
		var hp:float=1e308 if override.has("growth_hp_per_stack") else 100.0
		var stacks:int=0 if override.has("growth_hp_per_stack") else 9223372036854775807
		id=s.pool.spawn({"kind":&"assembler","growth_stacks":stacks,"position":PolarPosition.new(2,1,0,.5),"hp":hp,"damage_per_second":6.0,"speed_ring_widths_per_second":1.0,"assimilation_stacks":[],"stun_remaining":0.0})
		before=s.state.duplicate(true)
		check(not s.step(DT).ok and s.state==before and s.pool.payload_for(id).growth_stacks==stacks and s.elapsed_seconds==0,"Prospective HP or integer growth overflow rolls back destruction")
