class_name WorldActor
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var is_active: bool = false

func reset_actor() -> void:
	velocity = Vector2.ZERO
	is_active = false
