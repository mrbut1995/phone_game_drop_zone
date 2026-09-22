# Cần cẩu xây dựng.
# Scene crane.tscn khai báo sẵn: CraneFrame (Sprite2D - thân cần), Trolley (Sprite2D - xe con),
# Sprite (AnimatedSprite2D - móc cẩu đung đưa, animation "swing"), kèm JibCollision (dầm ngang),
# CableCollision + HookCollision (gắn theo Sprite móc cẩu).
class_name CraneObstacle
extends Obstacle

@export var jib_length: float = 200.0
@export var cable_length: float = 75.0
@export var is_facing_right: bool = true

@onready var trolley: Sprite2D = $Trolley
@onready var hook: AnimatedSprite2D = $Sprite

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.STRUCTURAL
	auto_wrap_x = false
	speed = 0.0
	_apply_layout()

func on_setup(params: Dictionary) -> void:
	if params.has("jib_length"):
		jib_length = params["jib_length"]
	if params.has("cable_length"):
		cable_length = params["cable_length"]
	if params.has("is_facing_right"):
		is_facing_right = params["is_facing_right"]
	_apply_facing()
	_apply_layout()

# Hướng quay của cần cẩu do is_facing_right quyết định (thay vì direction)
func _apply_facing() -> void:
	scale.x = 1.0 if is_facing_right else -1.0

# Xe con chạy trên cần + móc cẩu treo bên dưới; cáp co giãn theo cable_length
func _apply_layout() -> void:
	var anchor := Vector2(jib_length * 0.75, 0.0)
	trolley.position = anchor
	hook.position = anchor
	hook.scale.y = cable_length / 75.0
