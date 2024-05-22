extends Node3D

var adventurer_name = "Samwell"
var epithet = ""
var dialogue = "My sword got chipped on a Wildling Ogre out at Greenich Meadows. Could you fix it?"
var walkSpeed = 3.0

var weapon = null

enum {ENTERING, IDLE, WAITING, LEAVING}
var state = ENTERING

var target = Vector3(0, 1.3, -0.85)

func get_adv_name():
	return adventurer_name + " " + epithet

func displayDialogue(request):
	# display dialogue
	get_node("/root/World").dialogueDisplayed = true
	get_node("/root/World/UI/Dialogue").visible = true
	get_node("/root/World/UI/Dialogue/Buttons").visible = true
	get_node("/root/World/UI/Dialogue/NameLabel").text = adventurer_name + " " + epithet
	get_node("/root/World/UI/Dialogue/DialogueLabel").text = dialogue
	
	get_node("/root/World/UI/Dialogue/Buttons/Accept").connect("pressed", Callable(get_node('/root/World'), "acceptRequest").bind(request, self))
	get_node("/root/World/UI/Dialogue/Buttons/Reject").connect("pressed", Callable(get_node('/root/World'), "rejectRequest").bind(request, self))

func _physics_process(delta):
	if(get_node("/root/World").pauseGame):
		return
	
	if(state == ENTERING):
		if(global_position.distance_to(target) > 0.1):
			var spots_to_wait = get_node("/root/World").queue_adventurers.find(self) * Vector3(0, 0, -1.0)
			global_position += global_position.direction_to(target + spots_to_wait) * min(global_position.distance_to(target + spots_to_wait) * walkSpeed, walkSpeed) * delta
		elif(get_node("/root/World/Player/PlayerCamera").current_station == get_node("/root/World/Player/PlayerCamera").COUNTER 
			and get_node("/root/World").at_adventurer == -1):
			state = IDLE
			
	if(state == IDLE and get_node("/root/World/UI/Dialogue/NameLabel").text != adventurer_name + " " + epithet and get_node("/root/World").at_adventurer == -1):
		var request = {
			item=weapon,
			service_type="Repair", # or buy
			adventurer=self,
			completed=false,
			pay=0
		}
			
		displayDialogue(request)
			
	elif(state == WAITING):
		if(global_position.distance_to(target) > 0.2):
			global_position += global_position.direction_to(target) * min(global_position.distance_to(target), walkSpeed) * delta
		else:
			pass
	elif(state == LEAVING):
		if(global_position.distance_to(target) > 0.1):
			global_position += global_position.direction_to(target) * min(global_position.distance_to(target) * walkSpeed, walkSpeed) * delta
		elif(target != Vector3(0, global_position.y, -10)):
			target = Vector3(0, global_position.y, -10)
		
		if(global_position.z < -7):
			# open door
			get_node("/root/World/door/AnimationPlayer").play("open")
		if(global_position.z < -9):
			if(self in get_node("/root/World").adventurers):
				get_node("/root/World").adventurers.erase(self)
			queue_free()
