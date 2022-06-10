extends Node2D

var player
var agent
var ball
var hit_counter = 0
var network_player
var has_authority = false
var singleplayer = true
var level
var p1_score = 0
enum {
	BEGINNER,
	GOOD,
	EXPERT
}
var skill_level


var dash_speed = 2750
var dash_radius_factor = 0.8
var dash_cooldown = 2
var dash_time = 0.15
var dash_length = dash_speed * dash_time
var hit_power = 1200
var gravity = 1500
var friction = 6.5
var accel = 5000
var jump_height = 1400
var dash_stop = 0.4
var hit_radius = 120


func _ready():
	gravity = 2000
	hit_power = 1000
	friction = 7.5
	accel = 6000
	jump_height = 1000
	dash_stop = 0.2
	hit_power = 1100
