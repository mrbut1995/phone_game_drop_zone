class_name ThinAirZoneObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.THIN_AIR
	zone_multiplier = 1.5 # Gia tốc rơi tăng 50%
	speed = 15.0
	auto_wrap_x = true

func on_setup(params: Dictionary) -> void:
	if params.has("multiplier"):
		zone_multiplier = params["multiplier"]
