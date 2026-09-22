class_name UpdraftZoneObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.UPDRAFT
	zone_force = 480.0 # Lực đẩy lên (px/s² chống lại trọng lực 800)
	speed = 20.0 # Cột khí có thể trôi ngang rất chậm
	auto_wrap_x = true

func on_setup(params: Dictionary) -> void:
	if params.has("lift_force"):
		zone_force = params["lift_force"]
