extends KinematicBody2D
var col = Color(0.78125, 0.305271, 0.119019)
var vel = Vector2.ZERO
var in_air = 0
var register_click = true
var click_pos = Vector2.ZERO
var click_pos_poor = Vector2(0, 100)
var ball_in_range = false
onready var start_pos = position
var delta_time
export var right_side = true
var state = "chase"
var chase_dist = 0
var opponent
var should_dash = false
var dashes = 0
var clicks = 0
var p1_score = 0

enum {
	BEGINNER,
	GOOD,
	MASTER,
  SKILLED
}

export var skill_level = 0

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
	print("Log for debugging the AI,\nmainly when I am working with the expert")
	GLOBAL.agent = self
	$DashCooldown.wait_time = GLOBAL.dash_cooldown
	$DashTimer.wait_time = GLOBAL.dash_time
	$Area2D/CollisionShape2D.shape.radius = GLOBAL.hit_radius
	skill_level = GLOBAL.skill_level
	if skill_level == BEGINNER:
		print("Skill level: beginner")
	elif skill_level == GOOD:
		print("Skill level: good")
	elif skill_level == MASTER:
		print("Skill level: expert")

#Change code depending on side

func _physics_process(delta):
	delta_time = delta
	in_air += 60 * delta
	if not GLOBAL.p1_score == p1_score and skill_level == MASTER:
		print("They scored!\nWhat went wrong?")
		if dashing:
			print("We had to dash.")
		p1_score = GLOBAL.p1_score
	if is_on_floor():
		in_air = 0
		vel.y = 0
	
	if is_on_wall():
		vel.x *= 0.2 * 60 * delta
	
	act(delta)
	
	if actions.dash and not dashing and can_dash:
		dashing = true
		can_dash = false
		var prev_vel = vel
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
		if vel.length_squared() == 0:
			vel = prev_vel
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
	if not right_side and false:
		$Graphics.vel.x *= -1
		$Graphics.click_pos.x *= -1
	$Graphics.in_air = in_air
	
	actions.left = false
	actions.right = false
	actions.jump = false
	actions.click = false
	actions.dash = false

func act(delta):
	var side = 1 if right_side else -1
	if GLOBAL.player.clicked:
		clicks = 0
	var ball = GLOBAL.ball
	var player = GLOBAL.player
	if ball.position.distance_to(position) > 700 * 700:
		chase_dist = 100
	else:
		chase_dist = 0
	if skill_level == GOOD:
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
			elif future_pos.y > position.y:
				actions.down = true
		
#		$Sprite.global_position = best_pos
	elif skill_level == EXCELLENT:
			
			if ball.position.x > 0 and ball.vel.x > 0:
				
				if (ball.position.x > position.x + GLOBAL.hit_radius and ball.vel.x > 0.2):
					actions.right = true
					actions.left = false
					actions.dash = true
					print("dash back")
				if(ball.position.x < position.x - GLOBAL.dash_length):
					actions.right = false
					actions.left = true
					actions.dash = true
					print("dash forward")
				if sim_ball_pos.distance_to(position) < GLOBAL.hit_radius * 2 and sim_ball_pos.x < position.x:
					actions.left = true
					actions.right = false
			if ball.position.distance_to(position) < GLOBAL.hit_radius:
				state = "hit"
		elif state == "hit":
			actions.left = true
			actions.right = false
			actions.click = true
			print("hit")
			state = "wait"
		elif state == "wait":
			if ball.position.distance_to(position) > GLOBAL.hit_radius:
				state = "chase"
			

	elif skill_level == MASTER :
		
		
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

		#This is here for debug purposes. Put in "hit" when done
		var player_offset = 0
		var pos_want = Vector2(-GLOBAL.level.in_bounds_size * 0.9, 700)
		pos_want = Vector2(-100 * side, 700)
		
#		if side == 1:
#
#			randomize()
#			pos_want.x = rand_range(-50, -500)
#		else:
#			pos_want.x = 10 #GOOD
		
		click_pos = pos_want
		click_pos = to_local(click_pos)
		var rot = PI * min(abs(pos_want.x - position.x) / 5000, 0.5 * side)
		rot += 0.2
		click_pos = click_pos.rotated(rot)
		click_pos.x = -abs(click_pos.x) * side
		rot += (vel.x + -vel.y) * 0.00005
		var c = 0
		while true:
			var check = raycast(position, click_pos, 2)
			click_pos = click_pos.rotated(PI / 24)
			if not check.is_collision or c > 100:
				break
			c += 1
		click_pos.x = -abs(click_pos.x)
		click_pos = to_global(click_pos)
		
		if state == "chase":
			if sim_ball_pos.x - position.x > chase_dist:
				actions.right = true
			elif sim_ball_pos.x - position.x < -chase_dist:
				actions.left = true
			
			if abs(sim_ball_pos.x - sim_pos.x) < 200 and ball.vel.x * side > vel.x * side:
				actions.jump = true
			

			if ball.position.x > 0 and ball.vel.x > 0:
				
				if (ball.position.x > position.x + GLOBAL.hit_radius and ball.vel.x > 0.2):
					actions.right = true
					actions.left = false
					actions.dash = true
					if not dashing and can_dash:
						print("dash back")
				if (ball.position.x < position.x - GLOBAL.dash_length - GLOBAL.hit_radius - 400 + ball.position.y - 90 if ball.vel.y > 0.15 else 0):
					actions.right = false
					actions.left = true
					actions.dash = true
					if not dashing and can_dash:
						print("dash forward")
				if sim_ball_pos.distance_to(position) < GLOBAL.hit_radius * 2 and sim_ball_pos.x < position.x:
					actions.left = true
					actions.right = false
				if sim_ball_pos.x < 300 and position.x < 300:
					actions.jump = true
			if ball.position.x < 0 and ball.vel.x > 0.15 and clicks == 0 and position.x - GLOBAL.hit_radius + 20 - GLOBAL.dash_length < sim_ball_pos.x:
				state = "get ready"
				print("premoving")
			if ball.position.distance_to(position) < GLOBAL.hit_radius and sim_ball_pos.x < GLOBAL.level.in_bounds_size:
				state = "hit"
			
			if abs(ball.position.x - position.x) > 900 and ball.position.direction_to(opponent.position).dot(ball.vel) > 0.2:
				state = "resting pos"
			
		elif state == "hit":
			if (not dashing or ball.position.y > 700) and (clicks == 0 or (ball.position.x > 0 or ball.vel.x > 0) and (vel.y <= 0 or ball.position.x < 200)) :
				if(not clicks == 0 and (sim_ball_pos.x < 0 and sim_ball_vel.x < 0)):
					state = "wait"
					return
				actions.right = false
				if click_pos.x > position.x:
					click_pos.x = 0
				if position.x < 1000 and position.x > 300:
					print("hit")
					actions.left = true
					if(not clicks == 0):
						actions.jump = true
						click_pos = Vector2(-550, -350)
						print("long")
					else:
						click_pos.x -= 150
						click_pos.y -= 200
				elif position.x >= 1000:
					if clicks == 0:
						print("seting")
						click_pos = Vector2(position.x - 200, 150)
					else : 
						print("long bomb")
						click_pos = Vector2(-200, -350)
						actions.jump = true
					actions.left = true
				elif position.x <= 200 and clicks == 0 and position.y - GLOBAL.hit_radius > 425 and ball.position.y > 400:
					print("seting close")
					click_pos = Vector2(position.x + 7 if not vel.x > 0 else 0, position.y - 20)
					actions.left = false
					actions.right = false
					actions.jump = true
				else :
					if position.y - GLOBAL.hit_radius <= 425 and ball.position.y <= 375 and position.x < 200:
						print("spiking")
						click_pos = Vector2(-200, 821 - position.x/2)
					elif position.y - GLOBAL.hit_radius + 25 < 610  and ball.position.y < 610:
						click_pos = Vector2(0, 450 - position.x/2)
						print("tapping over")
					else :
						print("close hit")
						click_pos = Vector2(position.x - 100, -200)
					actions.left = true
					actions.jump = true
				actions.click = true
				state = "wait"
		elif state == "get ready":
			actions.right = true
			actions.left = false
			if abs(sim_ball_pos.y - position.y) < 400 or ball.position.x > position.x + GLOBAL.hit_radius - 20:
				state = "chase"
		elif state == "wait":
			if ball.position.distance_to(position) > GLOBAL.hit_radius:
				state = "chase"
	elif skill_level == BEGINNER:
		#Section 1: Movement when ball is coming
		if is_on_wall() and not actions.jump:
			actions.jump = true
		
#		$Sprite2.global_position = sim_ball_pos
		var player_offset = 0
		var pos_want = Vector2(0, 300)

		var rot = PI * min(abs(pos_want.x - position.x) / 5000, 0.5)
		rot += 0.2
		click_pos_poor = click_pos.rotated(rot)
		click_pos_poor.x = -abs(click_pos.x)
		rot += (vel.x + -vel.y) * 0.00005
		while true:
			var check = raycast(position, click_pos, 3)
			click_pos_poor = click_pos_poor.rotated(PI / 24)
			if not check.is_collision:
				break
		click_pos_poor = to_global(click_pos_poor)
		
		if state == "chase":
			if ball.position.x > position.x:
				actions.right = true
			else:
				sim_ball_pos.x += 200 * side
			
			if sim_ball_pos.x - position.x > chase_dist:
				actions.right = true
			elif sim_ball_pos.x - position.x < -chase_dist:
				actions.left = true
			
			if ball.position.x > 0 and ball.vel.x > 0:
				if ball.position.distance_to(position) < GLOBAL.hit_radius * 2 and ball.position.x < position.x + 50:
					actions.left = true
					actions.right = false
			if ball.position.distance_to(position) < GLOBAL.hit_radius:
				state = "hit"
		elif state == "hit":
			actions.left = true
			actions.right = false
			actions.click = true
			print("hit")
			state = "wait"
		elif state == "wait":
			
			if ball.position.distance_to(position) > GLOBAL.hit_radius:
				state = "chase"

			
		elif state == "resting pos":
			var dir = opponent.position.direction_to(ball.position)
			
			var resting_pos = Vector2(GLOBAL.level.in_bounds_size * 0.2 * side, 700)
			
			if (resting_pos.x - position.x) > chase_dist:
				actions.right = true
			elif (resting_pos.x - position.x) < -chase_dist:
				actions.left = true
			if ball.position.x * side > 0:
				state = "chase"
  elif skill_level == SKILLED:
    	
		
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

		#This is here for debug purposes. Put in "hit" when done
		var player_offset = 0
		var pos_want = Vector2(-GLOBAL.level.in_bounds_size * 0.9, 700)
		pos_want = Vector2(-100 * side, 700)
		
#		if side == 1:
#
#			randomize()
#			pos_want.x = rand_range(-50, -500)
#		else:
#			pos_want.x = 10 #GOOD
		
		click_pos = pos_want
		click_pos = to_local(click_pos)
		var rot = PI * min(abs(pos_want.x - position.x) / 5000, 0.5 * side)
		rot += 0.2
		click_pos = click_pos.rotated(rot)
		click_pos.x = -abs(click_pos.x) * side
		rot += (vel.x + -vel.y) * 0.00005
		var c = 0
		while true:
			var check = raycast(position, click_pos, 2)
			click_pos = click_pos.rotated(PI / 24)
			if not check.is_collision or c > 100:
				break
			c += 1
		click_pos.x = -abs(click_pos.x)
		click_pos = to_global(click_pos)
		
		if state == "chase":
			if sim_ball_pos.x - position.x > chase_dist:
				actions.right = true
			elif sim_ball_pos.x - position.x < -chase_dist:
				actions.left = true
			
			if abs(sim_ball_pos.x - sim_pos.x) < 200 and ball.vel.x * side > vel.x * side:
				actions.jump = true
    if abs(sim_ball_pos.x - sim_pos.x) < 200 and abs(sim_ball_pos.y - sim_pos.y) > GLOBAL.jump_height * 0.3 and ball.vel.y > 0:
				actions.jump = true

			if ball.position.x > 0 and ball.vel.x > 0: #Work on this!
				
				if abs(sim_ball_pos.x - sim_pos.x) > GLOBAL.hit_radius * 1.5:
					actions.dash = true
					if abs(sim_ball_pos.x - sim_pos.x + GLOBAL.dash_dist * 1.5) > GLOBAL.hit_radius * 1.5 and ball.position.x > position.x:
						actions.jump = true
				
				if sim_ball_pos.distance_to(position) < GLOBAL.hit_radius * 2 and sim_ball_pos.x < position.x:
					actions.left = true
					actions.right = false
			
			if ball.vel.y < 0 and ball.position.distance_to(position) > 300:
				state = "get ready"
				should_dash = abs(sim_ball_pos.x - sim_pos.x) > 700
      if not (vel.length() > GLOBAL.dash_speed * 0.7) or true:
				actions.left = false
      state = "wait"
		
		elif state == "get ready":
			
			if should_dash:
				sim_ball_pos.x += 700 * side
      if abs(sim_ball_pos.y - position.y) < 400:
				state = "chase"
       
			
	$Label.text = state as String
	$Sprite.global_position = click_pos
		
#	$Sprite.global_position = click_pos

func reset():
	position = start_pos
	can_dash = true
	opponent = GLOBAL.level.p1 if GLOBAL.level.p1 != self else GLOBAL.level.p2

func click():
	if register_click and not raycast(position, GLOBAL.ball.position, 2).is_collision and GLOBAL.hit_counter > -2:
		GLOBAL.ball.hit(position, position.direction_to(click_pos), vel, GLOBAL.hit_power, self)
		$Graphics.throwing_hands = true
		clicks += 1
		print(clicks)
	
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
