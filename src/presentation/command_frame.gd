extends Control
## Fine structural framing drawn at the native output resolution.
var home := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var brass := Color("967e57")
	var steel := Color("324653")
	var left := 86.0
	var right := size.x - left
	draw_line(Vector2(left,96),Vector2(right,96),steel,2,true)
	draw_line(Vector2(left,size.y-104),Vector2(right,size.y-104),steel,2,true)
	for x in [left,right]:
		for y in [96.0,size.y-104]:
			draw_circle(Vector2(x,y),7,Color("142532"))
			draw_arc(Vector2(x,y),7,0,TAU,24,brass,1.5,true)
			draw_line(Vector2(x-3,y),Vector2(x+3,y),brass,1.5,true)
	if home:
		draw_line(Vector2(1434,190),Vector2(1434,1210),steel,2,true)
		draw_line(Vector2(1429,190),Vector2(1429,330),brass,5,true)
		for i in range(19):
			var y := 410.0+i*40
			draw_line(Vector2(1420,y),Vector2(1434,y),steel,1,true)
	else:
		draw_line(Vector2(144,178),Vector2(144,266),brass,6,true)
