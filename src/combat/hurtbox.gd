class_name Hurtbox
extends Area2D
## An area that projectiles and skill shapes can hit. The parent takes the damage.

@onready var unit: Node2D = get_parent()
