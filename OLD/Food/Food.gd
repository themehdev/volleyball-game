extends Area2D

var energy = 5
var size = 20

func _ready():
	$CollisionShape2D.shape.radius = size

func _physics_process(_delta):
	update()

func _draw():
	draw_circle(Vector2(0, 0), size, Color(0.054382, 0.515625, 0.104831))
	draw_circle(Vector2(0, 0), size / 1.3, Color(0.094162, 0.730469, 0.163758))
