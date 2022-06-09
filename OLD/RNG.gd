extends Node2D

var rng = RandomNumberGenerator.new()

func rand_vec(neg = false):
	rng.randomize()
	var x = rng.randf()
	rng.randomize()
	var y = rng.randf()
	if neg:
		x = x * 2 - 1
		y = y * 2 - 1
	return Vector2(x, y)

func rand_num(neg = false):
	rng.randomize()
	if neg:
		return rng.randf() * 2 - 1
	return rng.randf()

func rand_range(a, b):
	rng.randomize()
	return rand_range(a, b)
