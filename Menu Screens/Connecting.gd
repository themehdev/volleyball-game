extends Control

var status = "connecting"

func _ready():
	NetworkManager.start_connecting()
	NetworkManager._client.connect("connection_established", self, "connected")
	NetworkManager.connect("start", self, "start_game")

func connected(_proto):
	status = "waiting"
	$VBoxContainer/Label.text = "Waiting for players..."
	NetworkManager.send_msg({"ready": true})

func start_game():
	get_tree().change_scene("res://Level/Level.tscn")

func _on_Timer_timeout():
	if status == "connecting":
		$VBoxContainer/Label.text += "."
		if $VBoxContainer/Label.text == "Connecting....":
			$VBoxContainer/Label.text = "Connecting"


func _on_Button_pressed():
	get_tree().change_scene("res://Menu Screens/Menu.tscn")
