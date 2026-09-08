class_name PolarPosition
extends RefCounted

var ring: int = 0
var wedge: int = 0
var radial_fraction: float = 0.0
var angular_fraction: float = 0.0


func _init(p_ring: int = 0, p_wedge: int = 0, p_radial_fraction: float = 0.0, p_angular_fraction: float = 0.0) -> void:
	ring = p_ring
	wedge = p_wedge
	radial_fraction = p_radial_fraction
	angular_fraction = p_angular_fraction
