extends Control
## The four instrument bays share one machined housing.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var outline := PackedVector2Array([Vector2(0,12),Vector2(12,0),Vector2(size.x-12,0),Vector2(size.x,12),Vector2(size.x,size.y-12),Vector2(size.x-12,size.y),Vector2(12,size.y),Vector2(0,size.y-12),Vector2(0,12)])
	draw_colored_polygon(outline,Color("0b151eeb"))
	draw_polyline(outline,Color("45606d"),1.5,true)
	draw_line(Vector2(18,3),Vector2(size.x-18,3),Color("6a7880"),1,true)
	draw_line(Vector2(20,size.y-3),Vector2(size.x*0.20,size.y-3),Color("d5ac6e"),3,true)
	for x in [size.x*0.22,size.x*0.44,size.x*0.63,size.x*0.80]:
		draw_line(Vector2(x,20),Vector2(x,size.y-20),Color("2d4452"),2,true)
	for x in [14.0,size.x-14]:
		draw_circle(Vector2(x,15),3,Color("84949c"))
