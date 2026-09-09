extends SceneTree
const Memory = preload("res://src/presentation/ui/run_memory.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var memory = Memory.new()
	memory.reset("diagnostic-a")
	check(not memory.snapshot().has_data and memory.peak_image() == null,"No samples means no invented history or image")
	check(not memory.observe(NAN,1,"bad") and not memory.observe(-1,1,"bad") and not memory.observe(0,-1,"bad"),"Invalid observations rejected")
	check(memory.observe(0,1,"tick0"),"Actual opening admitted")
	check(not memory.reset("x".repeat(257)) and not memory.reset("") and memory.snapshot().run_id == "diagnostic-a","Invalid bounded run IDs reject without clearing history")
	check(not memory.observe(0,1,"x".repeat(257)) and memory.snapshot().latest.state_id == "tick0","Oversized sample identity rejects without mutation")
	var old: Dictionary = memory.capture_ticket()
	check(memory.observe(0.5,2,"tick30"),"Actual new peak admitted")
	var pixels := Image.create(8,8,false,Image.FORMAT_RGBA8)
	pixels.fill(Color.RED)
	check(not memory.supply_capture(old,old,pixels),"Delayed earlier peak rejected")
	var ticket: Dictionary = memory.capture_ticket()
	var mipmapped := Image.create(8,8,true,Image.FORMAT_RGBA8)
	check(not memory.supply_capture(ticket,ticket,mipmapped),"Mipmaps rejected so retained image byte bound stays explicit")
	var changed := ticket.duplicate()
	changed.state_id = "later-state"
	check(not memory.supply_capture(ticket,changed,pixels),"Rendered identity must match request identity")
	check(memory.supply_capture(ticket,ticket,pixels),"Actual matching image retained")
	pixels.fill(Color.BLUE)
	check(memory.peak_image().get_pixel(0,0) == Color.RED,"Source image mutation cannot alter memory")
	var returned: Image = memory.peak_image()
	returned.fill(Color.GREEN)
	check(memory.peak_image().get_pixel(0,0) == Color.RED,"Returned image mutation cannot alter memory")
	check(not memory.observe(0.25,3,"backwards"),"Backward time rejected without replacing peak")
	memory.observe(1,3,"tick60")
	check(not memory.snapshot().has_peak_image,"New uncaptured higher peak never reuses lower-peak picture")
	for index in range(2,700):
		memory.observe(float(index),12 if index == 301 else 1+(index%5),"fixture-%d" % index)
	var state: Dictionary = memory.snapshot()
	check(state.samples.size() <= Memory.MAX_SAMPLES,"Long changing history remains bounded")
	check(state.samples[0].seconds == 0 and state.samples[-1].seconds == 699,"Actual first/latest endpoints survive reduction")
	check(state.peak.seconds == 301 and state.peak.radius == 12 and state.peak in state.samples,"Actual global peak survives reduction")
	var truthful := true
	for sample in state.samples:
		if sample.seconds >= 2: truthful = truthful and sample.state_id == "fixture-%d" % int(sample.seconds)
	check(truthful,"Reduced samples retain actual observed identities")
	state.samples.clear()
	check(not memory.snapshot().samples.is_empty(),"Snapshot mutation isolated")
	check(memory.finish("defeat") and memory.finish("defeat") and not memory.finish("victory"),"Terminal outcome idempotent and immutable")
	check(not memory.observe(900,12,"invented") and memory.snapshot().latest.seconds == 699,"Finish cannot manufacture 900-second endpoint")
	memory.reset("practice-b",true)
	check(not memory.supply_capture(ticket,ticket,pixels),"Reset invalidates old capture ticket")
	check(memory.snapshot().practice and not memory.snapshot().has_data and memory.peak_image() == null,"Practice reset clears prior run image/history")
	check(memory.finish("practice") and not memory.snapshot().has_data,"Empty practice result stays honestly empty")
	print("T088 run memory: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
