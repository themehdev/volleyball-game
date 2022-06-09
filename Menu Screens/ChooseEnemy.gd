extends Control


func _ready():
	for button in $VBoxContainer/Opponents.get_children():
		button.connect("button_up", self, "_button_pressed", [button])

func _button_pressed(button):
	$FadeIn.fade_in()


func _on_FadeIn_finished(anim_name):
	get_tree().change_scene("res://Level/Level.tscn")
