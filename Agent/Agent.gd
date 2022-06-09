extends KinematicBody2D
var col = Color(0.78125, 0.305271, 0.119019)
var vel = Vector2.ZERO
var in_air = 0
var register_click = true
var click_pos = Vector2.ZERO
var ball_in_range = false
onready var start_pos = position
var delta_time
var right_side = true
var state = "chase"

enum {
	POOR,
	GOOD,
	EXCELLENT,
	MASTER
}

export var skill_level = EXCELLENT

var can_dash = true
var dashing = false

var actions = {
	"jump": false,
	"left": false,
	"right": false,
	"down": false,
	"click": false,
	"dash": false
}

func _ready():
	GLOBAL.agent = self
	$DashCooldown.wait_time = GLOBAL.dash_cooldown
	$DashTimer.wait_time = GLOBAL.dash_time
	$Area2D/CollisionShape2D.shape.radius = GLOBAL.hit_radius

#Change code depending on side

func _physics_process(delta):
	delta_time = delta
	right_side = position.x > 0
	in_air += 60 * delta
	
	if is_on_floor():
		in_air = 0
		vel.y = 0
	
	if is_on_wall():
		vel.x *= 0.2 * 60 * delta
	
	act(delta)
	
	if actions.dash and not dashing and can_dash:
		dashing = true
		can_dash = false
		vel *= 0
		$Area2D/CollisionShape2D.shape.radius *= GLOBAL.dash_radius_factor
		if actions.right:
			vel.x = 0.5
		if actions.left:
			vel.x = -0.5
		if actions.jump:
			vel.y = -0.5
		if actions.down:
			vel.y = 0.5
		vel = vel.normalized() * GLOBAL.dash_speed
		$DashTimer.start()
	
	if not dashing:
		if actions.right:
			vel.x += GLOBAL.accel * delta
		if actions.left:
			vel.x += -GLOBAL.accel * delta
		if actions.jump and in_air < 8:
			vel.y = -GLOBAL.jump_height
		if not actions.jump and in_air > 8 and vel.y < 0:
			vel.y *= 0.92 * 60 * delta
		
		vel.x *= (60.0 - GLOBAL.friction) * delta
		vel.y += GLOBAL.gravity * delta
	
	if actions.click:
		click()
		register_click = false
	if not actions.click:
		register_click = true
	
	move_and_slide(vel, Vector2.UP)
	$Graphics.animation_head_body()
	if dashing:
		$Graphics.animation_dash()
	else:
		if is_on_floor():
			if abs(vel.x) > 50:
				$Graphics.animation_walk()
			else:
				$Graphics.animation_idle()
		else:
			$Graphics.animation_jump()
		$Graphics.animation_hands()
	$Graphics.vel = vel
	$Graphics.click_pos = click_pos
	$Graphics.in_air = in_air
	
	actions.left = false
	actions.right = false
	actions.jump = false
	actions.click = false
	actions.dash = false

func act(delta):
	var ball = GLOBAL.ball
	var player = GLOBAL.player
	if skill_level == GOOD:
		var future_pos = ball.position + ball.vel.normalized() * 200
		#Left and right movement
		if future_pos.x > position.x:
			actions.right = true
		else:
			actions.left = true
		
		#Hitting the ball
		var best_pos = Vector2(-750, 800)
		if ball_in_range:
			actions.click = true
			click_pos = ball.vel.normalized().rotated(PI)
			var line_of_sight = not raycast(position, best_pos).is_collision
			if line_of_sight:
				click_pos = position.direction_to(best_pos)
			else:
				var avg = (position + best_pos) * 0.5
				avg.y -= 200
				click_pos = position.direction_to(avg)
		
		#Jumping
		if (abs(position.y - future_pos.y) < 100 and ball.vel.y > 0) or (abs(position.y - future_pos.y) > 800 and ball.vel.y > 0):
			actions.jump = true
		
		#Dashing
		if future_pos.distance_to(position) > 600:
			actions.dash = true
			if future_pos.x > position.x:
				actions.right = true
			else:
				actions.left = true
			if abs(position.y - future_pos.y) > 600 and future_pos.y < position.y:
				actions.jump = true
			elif future_pos.y > position.y:
				actions.down = true
		
#		$Sprite.global_position = best_pos
	elif skill_level == EXCELLENT:
		
		
#		Section 1: Movement when ball is coming
		if is_on_wall() and not actions.jump:
			actions.jump = true
		
		var sim_ball_pos = ball.position
		var sim_pos = position
		var sim_vel = vel
		var sim_ball_vel = ball.vel
		var depth = 10
		for i in depth:
			if actions.right:
				sim_vel.x += GLOBAL.accel * delta
			if actions.left:
				sim_vel.x += -GLOBAL.accel * delta
			sim_vel.x *= (60.0 - GLOBAL.friction) * delta
			sim_pos.x += sim_vel.x * delta
			sim_ball_vel.x *= (60.0 - ball.friction) * delta
			sim_ball_vel.y += ball.gravity * delta
			
			sim_ball_pos += sim_ball_vel * delta
#		$Sprite2.global_position = sim_ball_pos
		var player_offset = 0
		var pos_want = Vector2(-GLOBAL.level.in_bounds_size * 0.9, 700)
		pos_want = Vector2(-100, 700)
		
		click_pos = pos_want
		click_pos = to_local(click_pos)
		var rot = PI * min(abs(pos_want.x - position.x) / 5000, 0.5)
		rot += 0.2
		click_pos = click_pos.rotated(rot)
		click_pos.x = -abs(click_pos.x)
		rot += (vel.x + -vel.y) * 0.00005
		while true:
			var check = raycast(position, click_pos, 3)
			click_pos = click_pos.rotated(PI / 24)
			if not check.is_collision:
				break
		click_pos = to_global(click_pos)
		
		if state == "chase":
			if sim_ball_pos.x > position.x:
				actions.right = true
			else:
				actions.left = true
			
			if abs(sim_ball_pos.x - sim_pos.x) < 200 and abs(sim_ball_pos.y - sim_pos.y) > GLOBAL.jump_height * 0.3 and ball.vel.y > 0:
				actions.jump = true
			
			if ball.position.x > 0 and ball.vel.x > 0:
				if abs(sim_ball_pos.x - sim_pos.x) > GLOBAL.hit_radius * 1.5:
					actions.dash = true
				if sim_ball_pos.distance_to(position) < GLOBAL.hit_radius * 2 and sim_ball_pos.x < position.x:
					actions.left = true
					actions.right = false
			if ball.position.direction_to(position).dot(ball.vel) > 0.5 and ball.position.distance_to(position) > 300 and ball.vel.x > 0:
				state = "get ready"
			if ball.position.distance_to(position) < GLOBAL.hit_radius and sim_ball_pos.x < GLOBAL.level.in_bounds_size:
				state = "hit"
		elif state == "hit":
			if not (dashing and position.x < ball.position.x):
				actions.left = false
				actions.right = false
				actions.click = true
			state = "wait"
		elif state == "get ready":
			sim_ball_pos.x += 500
			if sim_ball_pos.x > position.x:
				actions.right = true
			else:
				actions.left = true
			if abs(sim_ball_pos.y - position.y) < 400:
				state = "chase"
		elif state == "wait":
			if ball.position.distance_to(position) > GLOBAL.hit_radius:
				state = "chase"
#	$Sprite.global_position = click_pos


func reset():
	position = start_pos
	can_dash = true

func click():
	if register_click and not raycast(position, GLOBAL.ball.position, 2).is_collision and GLOBAL.hit_counter > -2:
		GLOBAL.ball.hit(position, position.direction_to(click_pos), vel, GLOBAL.hit_power, self)
		$Graphics.throwing_hands = true

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
	vel *= GLOBAL.dash_stop
	dashing = false
	$DashCooldown.start()
	$Graphics.reset_dash_anim()
	$Area2D/CollisionShape2D.shape.radius /= GLOBAL.dash_radius_factor

func _on_DashCooldown_timeout():
	can_dash = true
