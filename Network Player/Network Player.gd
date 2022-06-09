extends KinematicBody2D
var col = Color(0.119019, 0.657082, 0.78125)
var vel = Vector2.ZERO
var in_air = 0
var register_click = true
var can_hit_ball
var ball_in_range = false
var dashing = false
var can_dash = true
onready var start_pos = position
onready var base_color = $Graphics.modulate
var delta_time
var dest = Vector2.ZERO

func _ready():
	add_to_group("network player")
	add_to_group("players")
	GLOBAL.network_player = self
	$DashCooldown.wait_time = GLOBAL.dash_cooldown
	$DashTimer.wait_time = GLOBAL.dash_time

func new_data(player_data):
	if "vel" in player_data:
		#Flip vel x because everything is mirrored over the network
		vel.x = -player_data.vel.x
		vel.y = player_data.vel.y
	if "is_dashing" in player_data:
		dashing = player_data.is_dashing
	if "pos" in player_data:
		#Flip position x
		position.x = -player_data.pos.x
		position.y = player_data.pos.y

func _physics_process(delta):
	delta_time = delta
	in_air += 60 * delta
	
	move_and_slide(vel, Vector2.UP)
	
	if is_on_floor():
		in_air = 0

	$Graphics.animation_head_body()
	if dashing:
		$Graphics.animation_dash()
	else:
		$Graphics.reset_dash_anim()
		if is_on_floor():
			if abs(vel.x) > 100:
				$Graphics.animation_walk()
			else:
				$Graphics.animation_idle()
		else:
			$Graphics.animation_jump()
		$Graphics.animation_hands()
	$Graphics.vel = vel
	$Graphics.in_air = in_air

func reset():
	position = start_pos
	can_dash = true
	$DashCooldown.stop()

func _draw():
	var w = 6
	var c = Color(0, 1, 0.788235, 0.74902)
	$Graphics.modulate = base_color
	if can_hit_ball:
		w *= 1.4
		w += (cos(Engine.get_frames_drawn() * 1) + 0) * 2
		c = Color(1, 0.421875, 0, 0.74902)
		$Graphics.modulate = Color(1, 0.421875, 0, 1)
	var r = $Area2D/CollisionShape2D.shape.radius * 0.85
	var dir = position.angle_to_point(GLOBAL.ball.position)
	dir += PI
	var dist_per = max(0,
	min(position.distance_to(GLOBAL.ball.position) / 1200, 1))
	dist_per = 1 - dist_per
	c.a = dist_per
	var arc_width = PI * (dist_per) * 1.2 #Im too lazy to implement this correctly
	arc_width = 0.3
#	draw_arc(Vector2.ZERO, r, dir - arc_width, dir + arc_width, 30, c, w)
#	draw_line(Vector2.ZERO, to_local(GLOBAL.ball.position), c, w)
#	draw_arc(Vector2.ZERO, r, dir + arc_width, dir - arc_width, 20, c)
	
	var p = $DashCooldown.time_left / $DashCooldown.wait_time
	draw_arc(Vector2.ZERO, 80, 0, p * TAU, 30, Color(0, 1, 0.039063, 0.74902), 6)

func can_hit_ball():
	can_hit_ball = not raycast(position, GLOBAL.ball.position, 2).is_collision and GLOBAL.hit_counter < 2 and ball_in_range

func click():
	if register_click and can_hit_ball:
		GLOBAL.ball.hit(position, position.direction_to(get_global_mouse_position()), vel, GLOBAL.hit_power, self)
		$Graphics.throwing_hands = true
		$Graphics.ball_pos = GLOBAL.ball.position

func raycast(from, to, layer = 1, exceptions = [self]):
	var result = get_world_2d().direct_space_state.intersect_ray(from, to, exceptions, layer)
	if not result:
		result["position"] = to
		result["is_collision"] = false
	else:
		result["is_collision"] = true
	return result


func _on_Area2D_body_entered(body):
	if body == GLOBAL.ball:
		ball_in_range = true

func _on_Area2D_body_exited(body):
	if body == GLOBAL.ball:
		ball_in_range = false

func _on_DashTimer_timeout():
	dashing = false
	vel *= 0.4 * 60 * delta_time
	$DashCooldown.start()
	$Graphics.reset_dash_anim()
	$Area2D/CollisionShape2D.shape.radius /= GLOBAL.dash_radius_factor

func _on_DashCooldown_timeout():
	can_dash = true
