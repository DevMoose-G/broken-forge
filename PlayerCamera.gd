extends Camera3D

enum {ANVIL, COUNTER, FORGE, WHETSTONE}

var current_station = COUNTER

var anvilTransform = Transform3D(Vector3(0, 0, -1), Vector3(-0.974, 0.225, 0), Vector3(0.225, 0.974, 0), Vector3(-4.856, 1.624, 1.738))
var counterTransform = Transform3D(Basis(), Vector3(0, 0.8, 0))
var forgeTransform = Transform3D(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(2.677, 0.8, 1.754))
var whetstoneTransform = Transform3D(Vector3(-0.68, 0, 0.733), Vector3(0.168, 0.973, 0.156), Vector3(-0.714, 0.229, -0.662), Vector3(2.362, 0.772, 4.309))

var camera_transforms = [anvilTransform, counterTransform, forgeTransform, whetstoneTransform]

var starter_transform = transform
var transition_time = 0
var timeToTransition = 0.66
var end_transform

enum {HAMMER_UP, HAMMER_DOWN, HAMMER_IDLE}
var hammering = HAMMER_IDLE

@onready var raycast = get_node("RayCast3D")
@onready var hammer = get_node("Hammer")

var hammerSpeed = 8.0
var hammerDownTimer = 0
var hammerPower = 0
var hammerPowerDecreasing = false

var hammerButtonDown = false

var cast_starter_translation = Vector3(-1.3, 1.888, 1.069)
var cast_starter_transform = Transform3D(Vector3(-0.6, 0, 0), Vector3(0, 0.6, 0), Vector3(0, 0, -0.6), Vector3(-0.193, 1.308, 2.308))
var cast_translation = Vector3(-0.6, 0, 0)
var cast_transform = Transform3D(Vector3(-0.6, 0, 0), Vector3(0, 0, -0.6), Vector3(0, -0.6, 0), Vector3(-0.193, 1.308, 2.308))
var cast_in_place = null
var ingot_in_place = null

func _process(delta):
	if(get_node("/root/World").pauseGame):
		return
	
	# transitioning stations
	if(Input.is_action_just_pressed("prev_station") && transition_time <= 0):
		current_station -= 1
		if(current_station < ANVIL):
			current_station = ANVIL
		transition_time = timeToTransition
		starter_transform = transform
		end_transform = camera_transforms[current_station]
		
		get_node("/root/World").returnItemButtton.visible = false
	elif(Input.is_action_just_pressed("next_station") && transition_time <= 0):
		current_station += 1
		if(current_station > WHETSTONE):
			current_station = WHETSTONE
		transition_time = timeToTransition
		starter_transform = transform
		end_transform = camera_transforms[current_station]
		
		get_node("/root/World").returnItemButtton.visible = false
		
	if( (Input.is_action_just_pressed("prev_station") or Input.is_action_just_pressed("next_station"))):
		if(current_station == ANVIL):
			print("ENABLE ANVIL UI")
			get_node("/root/World/Anvil").enableAnvilUI()
		else:
			get_node("/root/World/Anvil").disableAnvilUI()
			hammerButtonDown = false
			hammering = HAMMER_IDLE
		
		if(current_station == FORGE and get_node("/root/World/Forge").visible != true): # need to unlock
			get_node("/root/World/UI/BuyEquipment/Button").disconnect("pressed", Callable(self, "buyWhetstone"))
			get_node("/root/World/UI/BuyEquipment/Button").disconnect("pressed", Callable(self, "buyForge"))
			get_node("/root/World/UI/BuyEquipment").visible = true
			get_node("/root/World/UI/BuyEquipment/Button").text = "Purchase Forge for 200 coins"
			get_node("/root/World/UI/BuyEquipment/Button").connect("pressed", Callable(self, "buyForge"))
		elif(current_station == WHETSTONE and get_node("/root/World/Whetstone").visible != true): # need to unlock
			get_node("/root/World/UI/BuyEquipment/Button").disconnect("pressed", Callable(self, "buyWhetstone"))
			get_node("/root/World/UI/BuyEquipment/Button").disconnect("pressed", Callable(self, "buyForge"))
			get_node("/root/World/UI/BuyEquipment").visible = true
			get_node("/root/World/UI/BuyEquipment/Button").text = "Purchase Whetstone for 125 coins"
			get_node("/root/World/UI/BuyEquipment/Button").connect("pressed", Callable(self, "buyWhetstone"))
			
		else:
			get_node("/root/World/UI/BuyEquipment").visible = false
		
		if(current_station == COUNTER):
			if(get_node("/root/World").dialogueDisplayed and get_node("/root/World").at_adventurer == -1):
				get_node("/root/World/UI/Dialogue").visible = true
		else:
			get_node("/root/World/UI/Dialogue").visible = false
	
	if(transition_time > 0):
		transition_time -= delta
		transform = end_transform.interpolate_with(starter_transform, transition_time/timeToTransition)
	
	# moving left and right (at counter)
	if(current_station == COUNTER):
		if(Input.is_action_just_pressed("walk_left")):
			counter_move("left")
			
		if(Input.is_action_just_pressed("walk_right")):
			counter_move("right")
			
	# click to hammer while at anvil
	if(Input.is_action_just_pressed("hammer") and hammering != HAMMER_UP and current_station == ANVIL):
		if(hammering == HAMMER_DOWN): # resets if player decides to press hammer again
			hammering = HAMMER_IDLE
		
		hammerButtonDown = true
	if(hammerButtonDown and current_station == ANVIL):
		if(not hammerPowerDecreasing):
			# harder as hammerPower increases
			if(hammerPower < 0.35):
				hammerPower += delta * 1.5 
			elif(hammerPower < 0.75):
				hammerPower += delta * 3.5 
			else:
				hammerPower += delta * 7.5
			
			if(hammerPower >= 1):
				hammerPower = 1
				hammerPowerDecreasing = true
		else:
			hammerPower -= delta
			if(hammerPower <= 0):
				hammerPower = 0
				hammerPowerDecreasing = false
		get_node("/root/World/UI/PowerBar/Inside").scale.x = hammerPower
		get_node("/root/World/UI/PowerBar/Inside/White64").modulate = Color(hammerPower, 1 - hammerPower, 0)
	if(Input.is_action_just_released("hammer") and current_station == ANVIL):
		hammering = HAMMER_UP
		hitSurface()
		
		hammerButtonDown = false
		hammerPowerDecreasing = false
		
	
	hammer.global_rotation.x = 0
	if(hammering == HAMMER_UP):
		if(hammer.global_position.distance_to(raycast.get_collision_point()) < hammerSpeed * delta):
			hammer.global_position = raycast.get_collision_point()
		else:
			hammer.global_position += hammer.global_position.direction_to(raycast.get_collision_point()) * hammerSpeed * (hammerPower + 0.1) * delta
		
		# actual hit of hammer
		if(hammer.global_position.distance_to(raycast.get_collision_point()) < 0.01):
			hammering = HAMMER_DOWN
			hammerDownTimer = 0
			if(raycast.get_collider() != null and raycast.get_collider().get("modelNum") != null):
				if(hammerPower > 0.65):
					get_node("Hammer/AudioStreamPlayer3D").stream = load("res://HeavyHammerClang.wav")
					get_node("Hammer/AudioStreamPlayer3D").volume_db = 1.75*(hammerPower - 0.65) - 3
				else:
					get_node("Hammer/AudioStreamPlayer3D").stream = load("res://LightHammerClang.wav")
					get_node("Hammer/AudioStreamPlayer3D").volume_db = 4*(hammerPower) - 4
				get_node("Hammer/AudioStreamPlayer3D").playing = true
				
				raycast.get_collider().checkForHit(raycast.get_collision_point(), hammerPower)
	elif(hammering == HAMMER_DOWN):
		hammerPower = 0 # reset hammer power
		hammerDownTimer += delta
		hammer.global_position = hammer.global_position.lerp(global_position - (transform.basis.y * 2), 0.03 * hammerDownTimer)
		if(hammer.global_position.distance_to(global_position - (transform.basis.y * 2)) < 0.1):
			hammering = HAMMER_IDLE
	
	# click to move objects at forge
	if(Input.is_action_pressed("hammer") and current_station == FORGE and get_node("/root/World/Forge").visible):
		hitSurface()
		print(raycast.get_collider())
		
		if(raycast.get_collider() != null and raycast.get_collider().get("ingot_type") != null):
			if(not raycast.get_collider().paid_for):
				print("NOT PAID FOR")
				if(get_node("/root/World").coin >= raycast.get_collider().cost):
					print("TRYING TO PAY")
					get_node("/root/World").coin -= raycast.get_collider().cost
					get_node("/root/World").ores_cost += raycast.get_collider().cost
					raycast.get_collider().paid_for = true
			
			if(raycast.get_collider().paid_for):
			
				ingot_in_place = raycast.get_collider()
				
				var direction = global_position.direction_to(raycast.get_collision_point())
				var dist_to_ingot = raycast.get_collider().global_position.distance_to(global_position)
				raycast.get_collider().held = true
				
				if(Input.is_action_pressed("walk_forward")):
					direction -= global_transform.basis.z * delta * 1.5
				elif(Input.is_action_pressed("walk_backward")):
					direction += global_transform.basis.z * delta * 1.5
				raycast.get_collider().global_position = (direction * dist_to_ingot) + global_position
	
	# single click to pull up cast or put it away
	if(Input.is_action_just_pressed("hammer") and current_station == FORGE and get_node("/root/World/Forge").visible):
		hitSurface()
		if(raycast.get_collider() != null and raycast.get_collider().name == "KnifeCast"):
			if(cast_in_place):
				raycast.get_collider().transform = cast_starter_transform
				raycast.get_collider().position = cast_starter_translation
				cast_in_place = null
			else:
				raycast.get_collider().transform = cast_transform
				cast_in_place = raycast.get_collider()
	
	# moving the cast forward and backward
	if(current_station == FORGE and cast_in_place != null and get_node("/root/World/Forge").visible):
		
		# making sure ingot is not in hand
		if not(Input.is_action_pressed("hammer") and raycast.get_collider() != null and raycast.get_collider().get("ingot_type") != null):
			
			if(Input.is_action_pressed("walk_forward")):
				cast_in_place.global_position -= global_transform.basis.z * delta * 1.5
			elif(Input.is_action_pressed("walk_backward")):
				cast_in_place.global_position += global_transform.basis.z * delta * 1.5

func buyForge():
	if(get_node("/root/World").coin >= 200):
		get_node("/root/World/UI/BuyEquipment").visible = false
		get_node("/root/World/Forge").visible = true
		get_node("/root/World").coin -= 200
		get_node("/root/World").equipment_cost += 200

func buyWhetstone():
	if(get_node("/root/World").coin >= 125):
		get_node("/root/World/UI/BuyEquipment").visible = false
		get_node("/root/World/Whetstone").visible = true
		get_node("/root/World").coin -= 125
		get_node("/root/World").equipment_cost += 125

func counter_move(direction):
	if(direction == "left"):
		get_node("/root/World/UI/Dialogue").visible = false
		if(get_node("/root/World").at_adventurer == -1): # if at center counter, move to last person
			get_node("/root/World").at_adventurer = len(get_node("/root/World").non_completed_requests()) - 1
		else:
			get_node("/root/World").at_adventurer -= 1
			get_node("/root/World").at_adventurer = get_node("/root/World").at_adventurer
			get_node("/root/World").at_adventurer = max(get_node("/root/World").at_adventurer, 0)
	elif(direction == "right"):
		get_node("/root/World/UI/Dialogue").visible = false
		if(get_node("/root/World").at_adventurer != -1):
			get_node("/root/World").at_adventurer += 1
		if(get_node("/root/World").at_adventurer >= len(get_node("/root/World").non_completed_requests())): 
			get_node("/root/World").at_adventurer = -1
			get_node("/root/World/UI/Dialogue").visible = get_node("/root/World").dialogueDisplayed
	
	if(get_node("/root/World").at_adventurer == -1):
		get_node("/root/World").returnItemButtton.visible = false
		transition_time = timeToTransition
		starter_transform = transform
		end_transform = counterTransform
	else:
		var adventurer = get_node("/root/World").adventurers[get_node("/root/World").at_adventurer]
		transition_time = timeToTransition
		starter_transform = transform
		var dist_x = adventurer.global_position.x - global_position.x
		end_transform = transform.translated(Vector3(dist_x, 0, 0))
		
		# shows button to return sword
		get_node("/root/World").returnItemButtton.disconnect("pressed", Callable(get_node("/root/World"), "completeRequest"))
		
		get_node("/root/World").returnItemButtton.visible = true
		get_node("/root/World").returnItemButtton.text = "Return " + adventurer.adventurer_name + " " + adventurer.epithet + "'s " + get_node("/root/World").non_completed_requests()[get_node("/root/World").at_adventurer].item.type
		get_node("/root/World").returnItemButtton.connect("pressed", Callable(get_node("/root/World"), "completeRequest").bind(get_node("/root/World").non_completed_requests()[get_node("/root/World").at_adventurer]))

func hitSurface():
	var mouse = get_viewport().get_mouse_position()
	var from = project_ray_origin(mouse)
	var to = (from + project_ray_normal(mouse))
	raycast.target_position = (project_local_ray_normal(mouse) * 3)
	raycast.force_raycast_update()
