extends RefCounted
## D-134 provisional physical-pixel typography; width never changes UI density.
const BODY = preload("res://assets/ui/fonts/barlow/Barlow-Regular.ttf")
const STRONG = preload("res://assets/ui/fonts/barlow/Barlow-SemiBold.ttf")
const HEADING = preload("res://assets/ui/fonts/barlow/BarlowSemiCondensed-SemiBold.ttf")
const TYPE := {"caption":18,"body":22,"heading":32,"title":48,"value":36,"display":112,"world":18}
static func density(height: float) -> float:
	return clampf(height/1080.0,0.85,1.5)
static func text(role: String, scale_value: float = 1.0, height: float = 1080.0) -> int:
	return maxi(16,roundi(float(TYPE.get(role,22))*density(height)*scale_value))
static func gap(value: float, height: float) -> float:
	return roundf(value*density(height))
static func font(role: String) -> Font:
	return HEADING if role in ["display","title","heading"] else (STRONG if role in ["value","world"] else BODY)
