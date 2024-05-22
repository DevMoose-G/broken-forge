extends CharacterBody3D

var ingot_type = "Copper"
var cost = 30
var paid_for = false

var start_pos

var GRAV = 98

var held = false

func _ready():
	start_pos = global_position + Vector3(0, 0.25, 0)

func _physics_process(delta):
	if(global_position.y < 0.8):
		global_position = start_pos
	
	var motion = Vector3()
	if(!is_on_floor() and not held):
		motion.y -= GRAV * delta
	set_velocity(motion)
	set_up_direction(Vector3(0, 1, 0))
	move_and_slide()
	
	held = false
