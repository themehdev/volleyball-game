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
var clock = 0
var pos_clock = 0

func _ready():
	add_to_group("player")
	add_to_group("players")
	GLOBAL.player = self
	$DashCooldown.wait_time = GLOBAL.dash_cooldown
	$DashTimer.wait_time = GLOBAL.dash_time
	$Area2D/CollisionShape2D.shape.radius = GLOBAL.hit_radius

func _physics_process(delta):
	delta_time = delta
	can_hit_ball()
	in_air += 60 * delta
	clock += 60 * delta
	pos_clock += delta
	
	if is_on_floor():
		in_air = 0
		vel.y = 0
	
	if is_on_wall():
		vel.x *= 0.2 * 60 * delta
	if Input.is_action_just_pressed("space") and not dashing and can_dash:
		dashing = true
		can_dash = false
		var prev_vel = vel
		vel *= 0
		$Area2D/CollisionShape2D.shape.radius *= GLOBAL.dash_radius_factor
		if Input.is_action_pressed("ui_right"):
			vel.x = 0.5
		if Input.is_action_pressed("ui_left"):
			vel.x = -0.5
		if Input.is_action_pressed("ui_up"):
			vel.y = -0.5
		if Input.is_action_pressed("ui_down"):
			vel.y = 0.5
		if vel.length_squared() == 0:
			vel = prev_vel
		
		vel = vel.normalized() * GLOBAL.dash_speed
		$DashTimer.start()
	
	if not dashing:
		if Input.is_action_pressed("ui_right"):
			vel.x += GLOBAL.accel * delta
		if Input.is_action_pressed("ui_left"):
			vel.x += -GLOBAL.accel * delta
		if Input.is_action_pressed("ui_up") and in_air < 8:
			vel.y = -GLOBAL.jump_height
		if not Input.is_action_pressed("ui_up") and in_air > 8 and vel.y < 0:
			vel.y *= 0.92 * 60 * delta
		
		vel.x *= (60.0 - GLOBAL.friction) * delta
		vel.y += GLOBAL.gravity * delta
	
	if Input.is_mouse_button_pressed(1):
		click()
		register_click = false
	if not Input.is_mouse_button_pressed(1):
		register_click = true
	
	move_and_slide(vel, Vector2.UP)
	
	$Graphics.animation_head_body()
	if dashing:
		$Graphics.animation_dash()
	else:
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
	update()
	
	if vel.length_squared() > 80 * 80 and clock > 3:
		var data = {
			"player": {
				"vel": {
				"x": vel.x,
				"y": vel.y
				},
				"is_dashing": dashing
			}
		}
		NetworkManager.send_direct_msg(data)
		clock = 0
	if pos_clock > 8:
		var data = {
			"player": {
				"pos": {
					"x": position.x,
					"y": position.y
				}
			}
		}
		NetworkManager.send_direct_msg(data)
		pos_clock = 0
	$Label.text = GLOBAL.has_authority as String
		

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
	vel *= GLOBAL.dash_stop
	$DashCooldown.start()
	$Graphics.reset_dash_anim()
	$Area2D/CollisionShape2D.shape.radius /= GLOBAL.dash_radius_factor

func _on_DashCooldown_timeout():
	can_dash = true
