extends Control
enum {
	BEGINNER,
	GOOD,
	EXPERT
}
var skill_level

func _ready():
	for button in $VBoxContainer/Opponents.get_children():
		button.connect("button_up", self, "_button_pressed", [button])

func _button_pressed(button):
	$FadeIn.fade_in()


func _on_FadeIn_finished(anim_name):
	get_tree().change_scene("res://Level/Level.tscn")
	GLOBAL.skill_level = skill_level


func _on_Beginner_pressed():
	skill_level = BEGINNER

func _on_Good_pressed():
	skill_level = GOOD

func _on_Expert_pressed():
	skill_level = EXPERT
