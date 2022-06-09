extends Node

var _client = WebSocketClient.new()
var id
var opponent_id = null
var players = []
export var websocket_url = "wss://quick-classy-cork.glitch.me/"
var connected = false
var sync_timer = 0
var last_data = {}

signal action(act)
signal start

func _init():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_on_error")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	

func start_connecting():
	print("Connecting...")

	#glitch.com requires these headers to be sent to connect through websockets.
	var custom_headers = []
	if not OS.has_feature("HTML5"):
		custom_headers = PoolStringArray([
			"Connection: keep-alive",
			"User-Agent: Websocket Demo",
		])
	var err = _client.connect_to_url(websocket_url, PoolStringArray([]), false, custom_headers)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _closed(was_clean = false):
	print("Disconnected!")
	connected = false

func _connected(_proto):
	print("Connected!")
	connected = true
	send_msg({"game": "volleyball", "ready": false})

func _on_error():
	print("Connection error!")

func _on_data():
	var msg = _client.get_peer(1).get_packet().get_string_from_utf8()
	var data = JSON.parse(msg).result
	
	if data.hash() == last_data.hash():
		return
	last_data = data
	
	if "ids" in data:
		opponent_id = data.ids[0]
		GLOBAL.has_authority = data.has_authority
		emit_signal("start")
	else:
		if "player" in data:
			GLOBAL.network_player.new_data(data.player)
		if "ball" in data:
			if "check" in data:
				if abs(data.ball.pos.x - GLOBAL.ball.position.x) > 50 or abs(data.ball.pos.y - GLOBAL.ball.position.y) > 50:
					GLOBAL.ball.new_data(data.ball.pos, data.ball.vel)
#					GLOBAL.level.set_score_and_update(data.current_scores.self, data.current_scores.enemy)
			else:
				GLOBAL.ball.new_data(data.ball.pos, data.ball.vel)
		if "ball_hit" in data:
			GLOBAL.has_authority = false
			GLOBAL.ball.emit_signal("hit", GLOBAL.network_player)
			GLOBAL.level.set_score_and_update(data.current_scores.self, data.current_scores.enemy)
		if "action" in data:
			emit_signal("action", data.action)

func send_msg(dict):
	if connected:
		var parsed = JSON.print(dict)
		_client.get_peer(1).put_packet(parsed.to_utf8())

func send_direct_msg(msg):
	if opponent_id:
		send_msg({
			"id": opponent_id,
			"message": msg,
			"is_direct_msg": true
		})

func _process(delta):
	_client.poll()
	
	if GLOBAL.has_authority and false:
		sync_timer += 1 * delta
		if sync_timer > 2:
			var ball = GLOBAL.ball
			send_direct_msg({
				"ball": {
					"pos": {
						"x": ball.position.x,
						"y": ball.position.y,
					},
					"vel": {
						"x": ball.vel.x,
						"y": ball.vel.y,
					}
				},
				"check": true,
				"current_scores": { #Data is from the perspective of the receiver
					"enemy": GLOBAL.level.p1_score,
					"self": GLOBAL.level.p2_score
				}
			})
			sync_timer = 0
