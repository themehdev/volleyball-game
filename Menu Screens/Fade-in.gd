extends ColorRect

signal finished(anim_name)

func _ready():
	pass

func fade_in():
	$AnimationPlayer.play("Fade-in")


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("finished", anim_name)
