extends Control


func _ready():
	pass


func _on_Singleplayer_button_up():
	$FadeIn.fade_in()
	GLOBAL.singleplayer = true

func _on_Fadein_finished(anim_name):
	if GLOBAL.singleplayer:
		get_tree().change_scene("res://Menu Screens/ChooseEnemy.tscn")
	else:
		get_tree().change_scene("res://Menu Screens/Connecting.tscn")


func _on_Multiplayer_button_up():
	$FadeIn.fade_in()
	GLOBAL.singleplayer = false
