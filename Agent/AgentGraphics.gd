extends Node2D

var left_foot = Vector2.ZERO
var right_foot = Vector2.ZERO
var max_move_threshold = 50
var move_threshold = max_move_threshold
var left_rest_pos = Vector2(0, move_threshold)
var right_rest_pos = Vector2(0, move_threshold)
var right_hand = Vector2.ZERO
var left_hand = Vector2.ZERO
var body = Vector2.ZERO
var head = Vector2.ZERO
var vel = Vector2.ZERO
var in_air = 0
var throwing_hands = false
var hand_state = 0
var ball_pos = Vector2.ZERO

func _ready():
	left_foot = $LeftFoot.rect_global_position
	right_foot = $RightFoot.rect_global_position

func _process(delta):
	$LeftFoot.rect_global_position += ((left_foot - $LeftFoot.rect_global_position) / 4) * 60 * delta
	$RightFoot.rect_global_position += ((right_foot - $RightFoot.rect_global_position)) / 4 * 60 * delta
	$RightHand.rect_global_position += ((right_hand - $RightHand.rect_global_position)) / 4 * 60 * delta
	$LeftHand.rect_global_position += ((left_hand - $LeftHand.rect_global_position)) / 4 * 60 * delta
	$Body.rect_global_position += ((body - $Body.rect_global_position) / 40) * 60 * delta
	$Head.rect_global_position += ((head - $Head.rect_global_position) / 40) * 60 * delta

func animation_walk():
	var p = abs(vel.x) / 400
	move_threshold = max(p * max_move_threshold, 10)
	var left_result = raycast(global_position, $MiddleRest.global_position)
	var right_result = raycast(global_position, $MiddleRest.global_position)
	var left_dist = left_result.position.distance_to(left_foot)
	var right_dist = right_result.position.distance_to(right_foot)
	var future_left_pos = left_result.position + Vector2(move_threshold * sign(vel.x) * 1.05, 0)
	var future_right_pos = right_result.position + Vector2(move_threshold * sign(vel.x) * 1.05, 0)
	if left_dist > right_dist:
		if left_result:
			if left_dist > move_threshold and right_foot.distance_to(future_left_pos) > move_threshold * 1:
				left_foot = future_left_pos
	else:
		if right_result:
			if right_dist > move_threshold and left_foot.distance_to(future_right_pos) > move_threshold * 1:
				right_foot = future_right_pos

func animation_head_body():
	head = $HeadRest.global_position
	body = $LeftShoulder.global_position

func animation_hands():
	if throwing_hands:
		animation_hands_hitting()
	else:
		animation_hands_idle()

func animation_hands_idle():
	var mouse_pos = get_global_mouse_position()
	var per = min(1, $RightShoulder.global_position.distance_to(mouse_pos) / 500.0)
	var dir = $RightShoulder.global_position.direction_to(mouse_pos)
	var least = dir * 20
	var most = dir * 30
	var offset = (most * per) + (least * (1.0 - per))
	right_hand = $RightShoulder.global_position + offset
	
	per = min(1, $LeftShoulder.global_position.distance_to(mouse_pos) / 500.0)
	dir = $LeftShoulder.global_position.direction_to(mouse_pos)
	least = dir * 20
	most = dir * 30
	offset = (most * per) + (least * (1.0 - per))
	left_hand = $LeftShoulder.global_position + offset

func animation_hands_hitting():
	var mouse_pos = get_global_mouse_position()
	var dir = $RightShoulder.global_position.direction_to(ball_pos)
	var right_dest = ball_pos
	var left_dest = ball_pos
	if hand_state == 0:
		if $RightHand.rect_global_position.distance_to(ball_pos) > 100:
			right_hand = right_dest
			left_hand = left_dest
			$RightHand.rect_global_position = ball_pos
			$LeftHand.rect_global_position = ball_pos
		else:
			hand_state = 1
	else:
		dir = ball_pos.direction_to(mouse_pos)
		right_dest = ball_pos + dir.rotated(0.2) * 150
		left_dest = ball_pos + dir.rotated(-0.2) * 150
		if right_dest.distance_to($RightHand.rect_global_position) > 70:
			right_hand = right_dest
			left_hand = left_dest
		else:
			hand_state = 0
			throwing_hands = false

func animation_idle():
	left_foot = $LeftRest.global_position
	right_foot = $RightRest.global_position

func animation_jump():
	if vel.y < 150:
		if in_air > 5:
			left_foot = $LeftRest.global_position
			right_foot = $RightRest.global_position
		else:
			left_foot = $LeftRest.global_position + Vector2(0, 50)
			right_foot = $RightRest.global_position + Vector2(0, 50)
	else:
		var left_result = raycast($LeftRest.global_position, $LeftRest.global_position + Vector2(0, 40), 2)
		var right_result = raycast($RightRest.global_position, $RightRest.global_position + Vector2(0, 40), 2)
		var left_dist = abs(left_result.position.y - $LeftRest.global_position.y)
		var right_dist = abs(right_result.position.y - $RightRest.global_position.y)
		left_foot = $LeftRest.global_position + Vector2.DOWN * left_dist
		right_foot = $RightRest.global_position + Vector2.DOWN * right_dist
	
func animation_dash():
	if rotation == 0:
		scale.x /= 1.5
		rotation = vel.angle()
		rotation += PI / 2
	left_hand = global_position + vel * 0.01
	left_hand.x += cos(Engine.get_frames_drawn()) * 100
	right_hand = global_position + vel * 0.01
	right_hand.x += cos(Engine.get_frames_drawn()) * -100
	
	left_foot = $MiddleRest.global_position + vel * 0
	left_foot.x += cos(Engine.get_frames_drawn()) * -100
	right_foot = $MiddleRest.global_position + vel * 0
	right_foot.x += cos(Engine.get_frames_drawn()) * 100

func reset_dash_anim():
	rotation = 0
	scale.x *= 1.5

func raycast(from, to, layer = 1, exceptions = [get_parent(), self]):
	var result = get_world_2d().direct_space_state.intersect_ray(from, to, exceptions, layer)
	if not result:
		result["position"] = to
		result["is_collision"] = true
	else:
		result["is_collision"] = false
	return result
