extends KinematicBody2D

var friction = 0.24 #0.004
var vel = Vector2.ZERO
var bounce = 0.9
var gravity = 1200 #14
var last_hit = null
var physics = true
var max_speed = 2400
var spawn

signal hit_ground
signal hit(who)

func _ready():
	add_to_group("ball")
	GLOBAL.ball = self
	spawn = position

func new_data(_pos, _vel):
	position.x = -_pos.x
	position.y = _pos.y
	#Flip vel x
	vel.x = -_vel.x
	vel.y = _vel.y

func reset():
	position = spawn
	vel *= 0
	last_hit = null

func _physics_process(delta):
#	Update collision response to be better with raycasting.
	
	if not physics:
		return
	vel.x *= (60.0 - friction) * delta
	vel.y += gravity * delta
	if is_on_floor() or is_on_ceiling():
		vel.y *= -bounce
	if is_on_wall():
		vel.x *= -bounce
	move_and_slide(vel, Vector2(0, -1))

func _draw():
	draw_circle(Vector2.ZERO, $CollisionShape2D.shape.radius, Color(0.284119, 0.720484, 0.765625))

func hit(pos, dir, v, power, who):
	
	if position.x < 10 and position.x > -10:
		return
	
	emit_signal("hit", who)
	last_hit = who
	var rel_vec = position - pos
	var dist = rel_vec.length() / 200
	dist = max(0.6, dist)
	vel = (dist + 0.5) * rel_vec * 0.2 + dir * power + v * 0.4
	vel = vel.clamped(max_speed)
	GLOBAL.has_authority = true
	var data = {
		"ball": {
			"pos": {
				"x": position.x,
				"y": position.y,
			},
			"vel": {
				"x": vel.x,
				"y": vel.y,
			}
		},
		"ball_hit": true,
		"current_scores": { #Data is from the perspective of the receiver
			"enemy": GLOBAL.level.p1_score,
			"self": GLOBAL.level.p2_score
		}
	}
	NetworkManager.send_direct_msg(data)
	NetworkManager.send_direct_msg(data)

func _on_Area2D_body_entered(body):
	if body.is_in_group("in_bounds"):
		emit_signal("hit_ground", true, position.x > 0)
	elif body.is_in_group("out_bounds"):
		emit_signal("hit_ground", false, position.x > 0)
