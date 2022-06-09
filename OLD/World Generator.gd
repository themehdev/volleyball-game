extends Node2D

var Food = preload("res://Food/Food.tscn")
var world_dims = Vector2(1000, 1000)

func new_food(pos, size):
	var f = Food.instance()
	f.position = pos
	f.size = size
	get_node("/root/World").call_deferred("add_child", f)

func spread_food(amt):
	for i in amt:
		var size = RNG.rand_range(5, 30)
		new_food(RNG.rand_vec(true) * world_dims, size)

func _ready():
	spread_food(10)
