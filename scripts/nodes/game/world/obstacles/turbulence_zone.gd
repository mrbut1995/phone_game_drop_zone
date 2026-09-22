class_name TurbulenceZoneObstacle
extends Obstacle

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.TURBULENCE
	zone_multiplier = 0.45 # Giảm hiệu lực tilt còn 45% theo GDD Section 12.4
	speed = 25.0
	auto_wrap_x = true

func on_setup(params: Dictionary) -> void:
	if params.has("multiplier"):
		zone_multiplier = params["multiplier"]
