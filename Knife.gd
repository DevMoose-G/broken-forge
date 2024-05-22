extends StaticBody3D

@export var damaged_nodes = [] # (Array, NodePath)
@export var power_needed_damage = [0.5, 0.5, 0.5, 0.5] # out of 1 # (Array, float)
var damaged_points = []

var scores = []

var MIN_DIST_TO_HIT = 0.1

var startingModelNum = "0000"
@onready var modelNum = startingModelNum
@export var model_path: NodePath
var model

var adventurer = null
var type = "Sword"

@onready var tooltip = get_node("/root/World/UI/Tooltip")

var latest_tooltip_idx = 0

func _ready():
	for i in range(0, len(damaged_nodes)):
		damaged_points.append(get_node(damaged_nodes[i]))
		damaged_points[i].connect("input_event", Callable(self, "displayDamage").bind(i))
		damaged_points[i].connect("mouse_exited", Callable(self, "hideTooltip").bind(i))
	
	if(model == null):
		model = get_node(model_path)
		
	for node in damaged_nodes:
		scores.append({accuracy=0, power=0, num_of_strikes=0})
	
	# randomize the power_needed_damage
	for i in range(0, len(power_needed_damage)):
		var choice = randi() % 3
		if(choice == 0):
			power_needed_damage[i] = 0.33
		elif(choice == 1):
			power_needed_damage[i] = 0.6
		elif(choice == 2):
			power_needed_damage[i] = 1.0

# tooltip to show damage of dent
func displayDamage(camera, event, position, normal, shape_idx, index):
	if(modelNum[len(damaged_nodes) - 1 - index] ==  "1"): # already repaired
		tooltip.visible = false
		return
	latest_tooltip_idx = index
		
	var power_diff = power_needed_damage[index] - scores[index].power
	if(power_diff <= 0.33 and power_diff >= 0):
		tooltip.get_node("Label").add_theme_color_override("font_color", Color(0.33,0.66,0))
		tooltip.get_node("Label").text = "Light3D damage"
	elif(power_diff <= 0.66  and power_diff > 0):
		tooltip.get_node("Label").add_theme_color_override("font_color", Color(0.66,.33,0))
		tooltip.get_node("Label").text = "Moderate damage"
	elif(power_diff > 0):
		tooltip.get_node("Label").add_theme_color_override("font_color", Color(1,0,0))
		tooltip.get_node("Label").text = "Severe damage"
	elif(power_diff > -1):
		tooltip.get_node("Label").add_theme_color_override("font_color", Color(1,0,0))
		tooltip.get_node("Label").text = "Damaged"
	tooltip.visible = true
	tooltip.position = get_viewport().get_mouse_position()

func hideTooltip(index):
	if(latest_tooltip_idx == index):
		tooltip.visible = false
	
func setStartingModel(num):
	print("res://Models/knife_"+num+".tscn")
	if(model != null):
		model.queue_free()
	modelNum = num
	startingModelNum = num
	model = load("res://Models/knife_"+modelNum+".tscn").instantiate()
	add_child(model)

func payment():
	# figure out a score system using dist, quality of sword,...
	
	# how much damage it had to start
	var num_of_damage_points = 0
	var pay = 0
	for i in range(0, len(startingModelNum)):
		if(startingModelNum[len(startingModelNum) - 1 - i] == "0"):
			num_of_damage_points += 1
			
			if(scores[i].num_of_strikes == 0):
				print("No Strike")
				continue # no pay
			
			# averaging accuracy
			scores[i].accuracy /= scores[i].num_of_strikes
			
			# worst accuracy can be is a 1
			if(scores[i].accuracy > 1):
				scores[i].accuracy = 1
			elif(scores[i].power - power_needed_damage[i] > 1):
				scores[i].power = power_needed_damage[i] + 1
			elif(scores[i].power - power_needed_damage[i] < -1):
				scores[i].power = power_needed_damage[i] - 1
			# simple logarithmic curve
			var accuracy_score = log(1.1 / (scores[i].accuracy + 0.1) ) / log(10)
			print("Accuracy Score is ", accuracy_score)
			var power_score = log(1.1 / ( abs(scores[i].power - power_needed_damage[i]) + 0.1) ) / log(10)
			print("Power Score is ", power_score)
			
			# basically how severe the dent was
			var difficulty = power_needed_damage[i]
			
			pay += accuracy_score * power_score * 10 * difficulty # a perfect score nets you 10 coin on each strike if severe dent
	
	print("Num of Damaged Points ", num_of_damage_points)
	
	pay = snapped(pay, 0.1)
	return pay

func no_strike_percentage():
	var num_of_no_strikes = 0
	var num_of_dents = 0
	for i in range(0, len(startingModelNum)):
		num_of_dents += 1
		if(startingModelNum[len(startingModelNum) - 1 - i] == "0"):
			if(scores[i].num_of_strikes == 0):
				num_of_no_strikes += 1
	return num_of_no_strikes / num_of_dents

func get_score():
	var score = 0
	var num_of_dents = 0
	for i in range(0, len(startingModelNum)):
		if(startingModelNum[len(startingModelNum) - 1 - i] == "0"):
			num_of_dents += 1
			if(scores[i].num_of_strikes == 0):
				print("No Strike")
				continue # no pay
			
			# averaging accuracy
			scores[i].accuracy /= scores[i].num_of_strikes
			
			# worst accuracy can be is a 1
			if(scores[i].accuracy > 1):
				scores[i].accuracy = 1
			elif(scores[i].power - power_needed_damage[i] > 1):
				scores[i].power = power_needed_damage[i] + 1
			elif(scores[i].power - power_needed_damage[i] < -1):
				scores[i].power = power_needed_damage[i] - 1
			# simple logarithmic curve
			var accuracy_score = log(1.1 / (scores[i].accuracy + 0.1) ) / log(10)
			print("Accuracy Score is ", accuracy_score)
			var power_score = log(1.1 / ( abs(scores[i].power - power_needed_damage[i]) + 0.1) ) / log(10)
			print("Power Score is ", power_score)
			
			score += accuracy_score * power_score
	return score/num_of_dents

func checkForHit(pos_hit, power):
	# find closest point
	var closest_point = damaged_points[0]
	var dist_to_closest_point = closest_point.global_position.distance_to(pos_hit)
	var closest_idx = 0
	for i in range(0, len(damaged_points)):
		var distance = damaged_points[i].global_position - pos_hit
		distance.y = 0
		distance = distance.length()
		if(dist_to_closest_point > distance):
			closest_point = damaged_points[i]
			dist_to_closest_point = distance
			closest_idx = i

	# check if it is a valid hit
	print(dist_to_closest_point)
	if(dist_to_closest_point > MIN_DIST_TO_HIT): # too far to count
		return
		
	# scores stuff
	scores[closest_idx].accuracy += dist_to_closest_point
	scores[closest_idx].power += power
	scores[closest_idx].num_of_strikes += 1
	
	for score in scores:
		print("First # of hits ", score.num_of_strikes)
	
	# disable tooltip
	get_node("/root/World/UI/Tooltip").visible = false
	
	# feedback
	get_node("/root/World/UI/Feedback").modulate = Color(1, 1, 1, 1)
	var ui_pos = get_node("/root/World/Player/PlayerCamera").unproject_position(damaged_points[closest_idx].global_position)
	get_node("/root/World/UI/Feedback").position = ui_pos
	
	if(dist_to_closest_point < 0.025):
		get_node("/root/World/UI/Feedback/Accuracy").add_theme_color_override("font_color", Color(0,1,0))
		get_node("/root/World/UI/Feedback/Accuracy").text = "Perfect accuracy"
	elif(dist_to_closest_point < 0.06):
		get_node("/root/World/UI/Feedback/Accuracy").add_theme_color_override("font_color", Color(0.5,0.5,0))
		get_node("/root/World/UI/Feedback/Accuracy").text = "Ok accuracy"
	else:
		get_node("/root/World/UI/Feedback/Accuracy").set("theme_override_colors/font_color", Color(1, 0, 0))
		get_node("/root/World/UI/Feedback/Accuracy").text = "Awful accuracy"
	
	var power_diff = power_needed_damage[closest_idx] - scores[closest_idx].power
	if(power_diff < 0.1 && power_diff > -0.1):
		get_node("/root/World/UI/Feedback/Power").add_theme_color_override("font_color", Color(0, 1, 0))
		get_node("/root/World/UI/Feedback/Power").text = "Perfect hit"
	elif(power_diff < 0.3 and power_diff > 0):
		get_node("/root/World/UI/Feedback/Power").add_theme_color_override("font_color", Color(0.5, 0.5, 0))
		get_node("/root/World/UI/Feedback/Power").text = "Almost enough power"
	if(power_diff > -0.3 and power_diff < 0):
		get_node("/root/World/UI/Feedback/Power").add_theme_color_override("font_color", Color(0.5, 0.5, 0))
		get_node("/root/World/UI/Feedback/Power").text = "A bit too mmuch power"
	if(power_diff < -0.3):
		get_node("/root/World/UI/Feedback/Power").add_theme_color_override("font_color", Color(1, 0, 0))
		get_node("/root/World/UI/Feedback/Power").text = "Damaged it"
	if(power_diff > 0.3):
		get_node("/root/World/UI/Feedback/Power").add_theme_color_override("font_color", Color(1, 0, 0))
		get_node("/root/World/UI/Feedback/Power").text = "Weak hit"
	
	# checks if enough power to update model
	if(power_diff > 0.1):
		return
	
	# load in new model
	if(modelNum[len(modelNum)-1 - closest_idx] == "1"):
		# already repaired
		return
	model.queue_free()
	modelNum[len(modelNum)-1 - closest_idx] = "1"
	model = load("res://Models/knife_"+modelNum+".tscn").instantiate()
	add_child(model)
	print(modelNum)
	
