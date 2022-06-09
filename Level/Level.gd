extends Node2D

var game_in_action = true
var timeout_action = null
var hit_counter = 0 #Positive is player hit counter, negative values is agent hit counter
var win_amt = 6
var p1
var p2
var p1_score = 0
var p2_score = 0
var p1_on_left = true #p1 should always be on left, but this is here in case i need to switch it
onready var in_bounds_size = $Walls/InBounds/CollisionShape2D.shape.extents.x

signal update_score(p_score, a_score)

func _ready():
	$Ball.connect("hit_ground", self, "ball_hit_ground")
	$Ball.connect("hit", self, "ball_hit")
	connect("update_score", $UI, "update_score")
	add_opponent()
	p1 = $Players.get_child(0) #p1 should be player
	p2 = $Players.get_child(1)
	NetworkManager.connect("action", self, "action")
	GLOBAL.level = self

func add_opponent():
	if not GLOBAL.singleplayer:
		var agent = load("res://Network Player/Network Player.tscn").instance()
		agent.position = Vector2(900, 700)
		$Players.add_child(agent)
	else:
		var agent = load("res://Agent/Agent.tscn").instance()
		agent.position = Vector2(900, 700)
		$Players.add_child(agent)

func _process(_delta):
	set_camera()

func start_timer(wait, action):
	$Timer.wait_time = wait
	$Timer.start()
	timeout_action = action

func set_score_and_update(score1, score2):
	if p1_score == score1 and p2_score == score2:
		return
	p1_score = score1
	p2_score = score2
	if p1_on_left:
		emit_signal("update_score", p1_score, p2_score)
	else:
		emit_signal("update_score", p2_score, p1_score)
	$Timer.stop()
	game_in_action = true

func ball_hit_ground(in_bounds, right_side):
	if not game_in_action:
		return
	#This code always assumes p1 is on the left
	#We need to switch sides if p1 is on the right
	if not p1_on_left:
		right_side = not right_side
	if $Ball.last_hit == p1:
		if right_side:
			if in_bounds:
				p1_score += 1
			else:
				p2_score += 1
		else:
			p2_score += 1
	else:
		if not right_side:
			if in_bounds:
				p2_score += 1
			else:
				p1_score += 1
		else:
			p1_score += 1
	if p1_on_left:
		emit_signal("update_score", p1_score, p2_score)
	else:
		emit_signal("update_score", p2_score, p1_score)
	game_in_action = false
	start_timer(4, "reset_wait")

func ball_hit(who):
	if who == p1:
		if hit_counter < 0:
			hit_counter = 1
		else:
			hit_counter += 1
	else:
		if hit_counter > 0:
			hit_counter = -1
		else:
			hit_counter -= 1
	GLOBAL.hit_counter = hit_counter

func set_camera():
	var p = p1.position
	var b = $Ball.position
	b.y *= 2
	var a = p2.position
	var p_a = p.distance_to(a)
	var b_a = b.distance_to(a)
	var p_b = p.distance_to(b)
	var total_dist = p_a + b_a + p_b
	total_dist *= 0.0005
	var pos = Vector2(0, 700)
	var zoom = Vector2(total_dist, total_dist)
	if zoom.x < 2.2:
		zoom = Vector2(2.2, 2.2)
	pos += p * 0.3
	pos += b * 0.5
	pos += a * 0.05
	pos /= 3
	$Camera2D.position += (pos - $Camera2D.position) / 10
	$Camera2D.zoom += (zoom - $Camera2D.zoom) / 10

func _on_Timer_timeout():
	
	if p1_score >= win_amt or p2_score >= win_amt:
		$UI/FadeIn.fade_in()
		return
	if timeout_action == "reset_wait":
		$Ball.physics = false
		$Ball.reset()
		start_timer(3, "go")
		p1.reset()
		p2.reset()
		if GLOBAL.has_authority:
			NetworkManager.send_direct_msg({
				"action": "reset_wait"
			})
	elif timeout_action == "go":
		$Ball.reset()
		$Ball.physics = true
		game_in_action = true
		hit_counter = 0
		GLOBAL.hit_counter = 0
		if GLOBAL.has_authority:
			NetworkManager.send_direct_msg({
				"action": "go"
			})

func _on_FadeIn_finished(anim_name):
	get_tree().change_scene("res://Menu Screens/Menu.tscn")
	NetworkManager._client.disconnect_from_host()

func action(act):
	if act == "reset_wait":
		$Timer.stop()
		$Ball.physics = false
		$Ball.reset()
		start_timer(3, "go")
		p1.reset()
		p2.reset()
	elif act == "go":
		$Timer.stop()
		$Ball.reset()
		$Ball.physics = true
		game_in_action = true
		hit_counter = 0
		
