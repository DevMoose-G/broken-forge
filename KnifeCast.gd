extends StaticBody3D

@export var ingotMelt: bool = false
@export var finishBlade: bool = false
var ingot_in_place = null

func _physics_process(delta):
	ingot_in_place = null
	for body in get_node("Area3D").get_overlapping_bodies():
		if(body.get("ingot_type") != null):
			body.global_position.x = global_position.x
			ingot_in_place = body
			
	if(ingotMelt and ingot_in_place != null):
		ingot_in_place.queue_free()
	
	if(global_position.x > 4.8 and (ingot_in_place != null || ingotMelt) ):
		get_node("AnimationPlayer").play("FillUp")
	else:
		get_node("AnimationPlayer").stop()
