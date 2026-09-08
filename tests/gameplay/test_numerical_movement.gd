extends SceneTree
const DT:=1.0/60.0
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:
		failures+=1
		push_error(label)
func fixture()->LiveSimulation:
	var profile:BalanceProfile=BalanceProfile.load_json("res://data/balance/testing.json").profile.with_overrides({"pressure":{"spawn_per_second":0},"flak":{"damage":0},"health":{"wall_hp":1e9,"wedge_base_hp":1e9}}).profile
	var sim:LiveSimulation=LiveSimulation.create(profile,3).simulation
	sim.state.energy=1e9
	for wedge in [1,3,5,7,9]: sim.place_wall(1,wedge)
	for entry in [[11,&"debris_field"],[4,&"tractor_lane"],[2,&"occlusion_screen"]]: sim.place_terrain(1,entry[0],0,entry[1])
	sim.pool.spawn({"kind":&"breacher","position":PolarPosition.new(2,11,0,.5),"hp":1e9,"damage_per_second":.01,"speed_ring_widths_per_second":1.0,"assimilation_stacks":[],"stun_remaining":.2})
	return sim
func _initialize()->void:
	var sim:=fixture()
	var id:int=sim.pool.active_ids()[0]
	for tick in range(13):check(sim.step(DT).ok,"Original pre-topology ticks progress")
	check(sim.place_wall(1,2).ok,"Original mid-window wall placement")
	var before:=sim.targets_snapshot()[0]
	var result:=sim.step(DT)
	check(result.ok and sim.elapsed_seconds==14.0/60.0 and sim.pool.active_count()==1,"T069 exact topology/realignment tick succeeds")
	check(sim._waypoints.has(id),"Unrepresentable residual keeps next waypoint")
	var p:PolarPosition=sim.pool.payload_for(id).position
	check(p.ring==2 and p.wedge==11 and p.angular_fraction==.5,"Residual does not fabricate movement")
	var old_turn:float=p.wedge+p.angular_fraction
	check(sim.step(DT).ok,"Next full tick resumes same actor")
	p=sim.pool.payload_for(id).position
	check(absf((p.wedge+p.angular_fraction-old_turn)*TAU/12.0*192.0-1.6)<1e-8,"Next tick preserves full physical angular travel")
	# Failure later in combat must still discard the successful movement scratch.
	sim=fixture();id=sim.pool.active_ids()[0]
	for tick in range(13):sim.step(DT)
	sim.place_wall(1,2)
	var state:=sim.state.duplicate(true)
	var position:PolarPosition=sim.pool.payload_for(id).position
	var paths:=sim._waypoints.duplicate()
	var nav:=sim._navigation
	var summary:=sim.run_summary()
	sim.cooldowns={&"invalid":1.0}
	check(not sim.step(DT).ok and sim.state==state and sim.pool.payload_for(id).position==position and sim._waypoints==paths and sim._navigation==nav and sim.run_summary()==summary,"Residual correction does not bypass downstream atomic failure")
	# Genuine unsupported slow full-tick movement is still rejected, not swallowed.
	sim=fixture();id=sim.pool.active_ids()[0]
	sim.pool.payload_for(id).stun_remaining=0.0
	sim.pool.payload_for(id).speed_ring_widths_per_second=1e-20
	check(not sim.step(DT).ok and sim.elapsed_seconds==0,"Initial unrepresentable motion still fails")
	# Slow but representable motion must accumulate across ticks rather than snap.
	sim=fixture();id=sim.pool.active_ids()[0]
	sim.pool.payload_for(id).stun_remaining=0.0
	sim.pool.payload_for(id).speed_ring_widths_per_second=1e-6
	for tick in range(20):check(sim.step(DT).ok,"Representable slow motion remains valid")
	p=sim.pool.payload_for(id).position
	check(absf((p.wedge+p.angular_fraction-11.5)*TAU/12.0*192.0-3.2e-5)<1e-10,"Representable slow progress is retained across ticks")
	print("Numerical movement: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
