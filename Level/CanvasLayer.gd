extends CanvasLayer


func _ready():
	pass

func update_score(player_score, agent_score):
	$Control/HBoxContainer/PlayerScore.text = player_score as String
	$Control/HBoxContainer/AgentScore.text = agent_score as String
