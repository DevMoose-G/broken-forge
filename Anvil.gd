extends StaticBody3D

@onready var items = get_node("Items")

var current_item = 0

var dist_to_move_x = 0

func _process(delta):
	if(get_node("/root/World").pauseGame):
		return
	
	if(items.get_child_count() == 0):
		get_node("/root/World/UI/Work/WorkingOn").text = ""
	
	if(Input.is_action_just_pressed("scroll_up")):
		if(current_item > 0):
			current_item -= 1
			dist_to_move_x += -0.5
			get_node("/root/World/UI/Work/WorkingOn").text = "Working on " + get_node("/root/World").non_completed_requests()[current_item].adventurer.get_adv_name() + "'s " + get_node("/root/World").non_completed_requests()[current_item].item.type
	elif(Input.is_action_just_pressed("scroll_down")):
		if(current_item < len(items.get_children()) - 1):
			current_item += 1
			dist_to_move_x += 0.5
			get_node("/root/World/UI/Work/WorkingOn").text = "Working on " + get_node("/root/World").non_completed_requests()[current_item].adventurer.get_adv_name() + "'s " + get_node("/root/World").non_completed_requests()[current_item].item.type
	
	if(abs(dist_to_move_x) > 0.01):
		for child in items.get_children():
			child.position.x += min(delta, abs(dist_to_move_x)) * sign(dist_to_move_x)
		dist_to_move_x -= min(delta, abs(dist_to_move_x)) * sign(dist_to_move_x)

func enableAnvilUI():
	get_node("/root/World/UI/Work").visible = true
	
	# makes sure items are in the right order
	var curr_x = 0.5 * current_item
	for child in items.get_children():
		child.position.x = curr_x
		curr_x -= 0.5

# clears all swords
func reset():
	for child in items.get_children():
		child.queue_free()
	current_item = 0

func disableAnvilUI():
	get_node("/root/World/UI/Work").visible = false

func addItem(item, request):
	var minX = 0.5
	for child in items.get_children():
		if(minX > child.position.x):
			minX = child.position.x
	items.add_child(item)
	item.position.x = minX - 0.5
	
	get_node("/root/World/UI/Work/WorkingOn").text = "Working on " + get_node("/root/World").non_completed_requests()[current_item].adventurer.get_adv_name() + "'s " + get_node("/root/World").non_completed_requests()[current_item].item.type
