extends Node3D

var accepted_requests = []
var current_working_request = 0

var queue_adventurers = [] # adventurers in line

var adventurers = []

var adventurers_heads = []
var adventurers_chests = []

var at_adventurer = -1

var dialogueDisplayed = false

@onready var returnItemButtton = get_node("UI/ReturnSword")

var time_bw_customer = .5

var names = ["Samwell", "Gregory", "Henry", "Charlemagne", "Edmund", "Edgar", "Harold", "Tyler"]
var epithets = ["the Great", "the Wolf", "the Sloth", "the Elder", "the Lion", "of Caria", "of Rivia", "of Athens", "of Sparta", "of Thebes", "of Corinth", "the Creator"]

var downarrow_up = true

var locked_response = null

@onready var playerCam = get_node("Player/PlayerCamera")

var coin = 1000
var timeSpeed = 3.0 # every second is 3 minutes
var time_in_day = 0 #in minutes, only 12 hours a day
var rent = 75
var equipment_cost = 0
var ores_cost = 0
var daysPassed = 0
@onready var endScreen = get_node("UI/EndScreen")
var waiting_input_end_of_day = false

var pauseGame = true

var good_responses = [
	"Thank you. You've earned a new loyal customer.",
	"Wow. I have never seen my {item} looking so good.",
	"It's a decent job. Looks a bit bent there, but it's good. How much?"
]
var bad_responses = [
	"You're a blacksmith? You broke my {item}. I am never coming back here.",
	"I curse your family for what you did to my {item}. I hope your firstborn never sees past puberty.",
	"I swear I shall get my revenge for this disgrace to my {item}. I stake that on my name as {name}."
]
var no_work_responses = [
	"You didn't do anything! It looks the same as before."
]

var places = ["Greenwich Alley", "Mellow Fields", "The Bog of Corina", "The Killer Jungle", "Shores of Hel"]
var monsters = ["Wildling Ogre", "Slithering Scorpion", "Two-faced Hogart"]
var starting_dialogues = [
	"My {item} got chipped on a {monster} out at {place}. Could you fix it?",
	"I just defeated a {monster} yesterday after days out in the forest, but alas, my {item} broke during the fight and I had to resort to my fists. Could you fix it?",
	"My {item} broke again. Be sure to fix it this time. I don't want to have to come back here.",
	"I nearly lost my life the instant I arrived at {place}. My {item} broke as I slashed my way out. I would be grateful if you could fix it.",
]

func _ready():
	
	adventurers_heads.append(load("res://PlagueMask.png"))
	adventurers_heads.append(load("res://HumanFace.png"))
	adventurers_heads.append(load("res://Helmet1.png"))
	adventurers_heads.append(load("res://Helmet2.png"))
	
	adventurers_chests.append(load("res://PlagueSuit.png"))
	adventurers_chests.append(load("res://LeatherChest.png"))
	adventurers_chests.append(load("res://SamuraiChest.png"))
	adventurers_chests.append(load("res://MetalChest.png"))
	
	get_node("StaticBody3D/Roof").visible = true
	randomize()

func non_completed_requests():
	var arr = []
	for request in accepted_requests:
		if(request.completed == false):
			arr.append(request)
	
	return arr

func acceptRequest(request, adventurer):
	# max of 3 accepted requests
	var num_of_requests_uncompleted = 0
	for req in accepted_requests:
		if(req.completed == false):
			num_of_requests_uncompleted += 1
	if(num_of_requests_uncompleted >= 3):
		return
	
	adventurer.state = adventurer.WAITING
	accepted_requests.append(request)
	adventurers.append(adventurer)
	
	get_node("/root/World/UI/Dialogue/NameLabel").text = ""
	get_node("/root/World/UI/Dialogue").visible = false
	
	get_node("/root/World/UI/Dialogue/Buttons/Accept").disconnect("pressed", Callable(self, "acceptRequest"))
	get_node("/root/World/UI/Dialogue/Buttons/Reject").disconnect("pressed", Callable(self, "rejectRequest"))
	
	dialogueDisplayed = false
	get_node("/root/World").queue_adventurers.erase(adventurer)
	
	# add item to anvil
	get_node("Anvil").addItem(adventurer.weapon, request)

	for player in adventurers:
		player.target = player.global_position + Vector3(-1.5, 0, 0)

func rejectRequest(request, adventurer):
	adventurer.target = adventurer.global_position + Vector3(1.5, 0, 0)
	adventurer.state = adventurer.LEAVING
	
	get_node("/root/World/UI/Dialogue/NameLabel").text = ""
	get_node("/root/World/UI/Dialogue").visible = false
	
	get_node("/root/World/UI/Dialogue/Buttons/Accept").disconnect("pressed", Callable(self, "acceptRequest"))
	get_node("/root/World/UI/Dialogue/Buttons/Reject").disconnect("pressed", Callable(self, "rejectRequest"))
	
	dialogueDisplayed = false
	get_node("/root/World").queue_adventurers.erase(adventurer)

# response after giving them the weapon
func give_response(request):
	if(request.item.no_strike_percentage() >= 0.66):
		return no_work_responses[randi() % len(no_work_responses)].format({"item":request.item.type, "name":request.adventurer.get_adv_name()})
	if(request.item.get_score() < 0.55):
		return bad_responses[randi() % len(bad_responses)].format({"item":request.item.type, "name":request.adventurer.get_adv_name()})
	return good_responses[randi() % len(good_responses)].format({"item":request.item.type, "name":request.adventurer.get_adv_name()})

func completeRequest(request):
	# dialogue saying thank you or something
	dialogueDisplayed = true
	get_node("/root/World/UI/Dialogue").visible = true
	get_node("/root/World/UI/Dialogue/Buttons").visible = false
	get_node("/root/World/UI/Dialogue/NameLabel").text = request.adventurer.get_adv_name()
	get_node("/root/World/UI/Dialogue/DialogueLabel").text = give_response(request)
	get_node("/root/World/UI/Dialogue/DownArrow").visible = true
	returnItemButtton.visible = false
	
	request.completed = true
	
	locked_response = request

func adventurerLeaves(request):
	# adventurer leaving
	request.adventurer.state = request.adventurer.LEAVING
	
	get_node("/root/World/UI/Dialogue/NameLabel").text = "" # resets dialogue
	
	request.payment = request.item.payment()
	get_node("UI/Coin/AddedCoinLabel").text = "+" + str(request.item.payment())
	get_node("UI/Coin/AddedCoinLabel").modulate = Color(1, 1, 1, 1)
	coin += request.item.payment()
	print("COIN IS ", coin)
	
	# delete sword
	request.item.queue_free()
	
	get_node("Anvil").current_item = 0
	
	playerCam.counter_move("right")

func int_to_binstring(n, length):
	var ret_str = ""
	while n > 0:
		ret_str = str(n&1) + ret_str
		n = n>>1
	while(len(ret_str) < length):
		ret_str = "0" + ret_str
	return ret_str

func _input(event):
	# wait until player confirms thank you
	if(locked_response != null and not (event is InputEventMouseMotion) ):
		adventurerLeaves(locked_response)
		dialogueDisplayed = false
		get_node("/root/World/UI/Dialogue/DownArrow").visible = false
		get_node("/root/World/UI/Dialogue").visible = false
		locked_response = null
	
	if(waiting_input_end_of_day and not (event is InputEventMouseMotion)):
		# turn off end of day
		waiting_input_end_of_day = false
		endScreen.visible = false
		time_in_day = 0
		equipment_cost = 0
		ores_cost = 0
		accepted_requests = []
		
		get_node("Anvil").reset()

func endOfDay():
	var extraTime = time_in_day - (12 * 60)
	
	# starting end of day
	if(endScreen.visible == false):
		daysPassed += 1
		coin -= rent
		
		get_node("/root/World/UI/Dialogue/NameLabel").text = ""
		get_node("/root/World/UI/Dialogue").visible = false
		
		# clear all adventurers out
		for adventurer in queue_adventurers:
			adventurer.queue_free()
		for adventurer in adventurers:
			adventurer.queue_free()
		adventurers = []
		queue_adventurers = []
		
		endScreen.visible = true
		var revenue = 0
		for request in accepted_requests:
			if(request.completed == true):
				revenue += request.payment
			
		# turn off all other UI
		
		endScreen.get_node("DayLabel").text = "End of Day " + str(daysPassed)
		endScreen.get_node("Revenue/Revenue").text = str(revenue)
		endScreen.get_node("Rent/Rent").text = str(rent)
		endScreen.get_node("Equipment/Equipment").text = str(equipment_cost)
		endScreen.get_node("Ores/Ores").text = str(ores_cost)
		endScreen.get_node("Profit/Profit").text = str(revenue - rent - equipment_cost - ores_cost)
		
		endScreen.get_node("DayLabel").visible = false
		endScreen.get_node("Revenue").visible = false
		endScreen.get_node("Rent").visible = false
		endScreen.get_node("Equipment").visible = false
		endScreen.get_node("Ores").visible = false
		endScreen.get_node("Profit").visible = false
	
	if(extraTime / timeSpeed > 1.0):
		endScreen.get_node("DayLabel").visible = true
	if(extraTime / timeSpeed > 2.0):
		endScreen.get_node("Revenue").visible = true
	if(extraTime / timeSpeed > 3.0):
		endScreen.get_node("Rent").visible = true
	if(extraTime / timeSpeed > 4.0):
		endScreen.get_node("Equipment").visible = true
	if(extraTime / timeSpeed > 5.0):
		endScreen.get_node("Ores").visible = true
	if(extraTime / timeSpeed > 7.0):
		endScreen.get_node("Profit").visible = true
	if(extraTime / timeSpeed > 8.0):
		waiting_input_end_of_day = true

func _process(delta):
	
	if(Input.is_action_just_released("ui_cancel")):
		pauseGame = !pauseGame
		get_node("UI/StartScreen").visible = !get_node("UI/StartScreen").visible	
	
	if(pauseGame):
		return
	
	if(locked_response != null):
		# waiting for player to press on dialogue
		return
	
	time_in_day += delta * timeSpeed # speeding up a day
	
	if(time_in_day >= (12 * 60) ):
		# end of day code
		endOfDay()
		return
		
	# fading the feedback control & addedCoini
	if(get_node("/root/World/UI/Feedback").modulate.a > 0):
		var old_color = get_node("/root/World/UI/Feedback").modulate 
		get_node("/root/World/UI/Feedback").modulate = old_color - Color(0, 0, 0, delta * 0.35)
	if(get_node("UI/Coin/AddedCoinLabel").modulate.a > 0):
		var old_color = get_node("UI/Coin/AddedCoinLabel").modulate 
		get_node("UI/Coin/AddedCoinLabel").modulate = old_color - Color(0, 0, 0, delta * 0.35)
	
	get_node("UI/Time/Hand").rotation = (time_in_day / (12 * 60) ) * 360
		
	get_node("UI/Coin/CoinLabel").text = str(coin)
	
	# ui downarrow up and down
	if(get_node("UI/Dialogue").visible and get_node("UI/Dialogue/DownArrow").visible):
		print("DIALOGUE VISIBLE")
		if(downarrow_up):
			get_node("UI/Dialogue/DownArrow").position.y -= delta * 50.0
		else:
			get_node("UI/Dialogue/DownArrow").position.y += delta * 50.0
		
		if(get_node("UI/Dialogue/DownArrow").position.y > 570):
			downarrow_up = true
		elif(get_node("UI/Dialogue/DownArrow").position.y < 560):
			downarrow_up = false
	
	if(len(queue_adventurers) < 6): #  no more than 6 waiting customers
		if(time_bw_customer > 0):
			time_bw_customer -= delta
		else:
			# spawn new customer
			var adventurer = load("res://Adventurer.tscn").instantiate()
			add_child(adventurer)
			
			# sprite for adventurer
			adventurer.get_node("Face").texture = adventurers_heads[randi() % len(adventurers_heads)]
			adventurer.get_node("Body").texture = adventurers_chests[randi() % len(adventurers_chests)]
			
			adventurer.epithet = epithets[randi() % len(epithets)]
			adventurer.adventurer_name = names[randi() % len(names)]
			adventurer.dialogue = starting_dialogues[randi() % len(starting_dialogues)].format({"item":"Sword", "place":places[randi() % len(places)], "monster":monsters[randi() % len(monsters)]})
			adventurer.global_position = Vector3(0, 1.3, -8.5)
			queue_adventurers.append(adventurer)
			
			adventurer.weapon = load("res://Knife_Broken1.tscn").instantiate()
			adventurer.weapon.setStartingModel(int_to_binstring(randi() % 11, 4)) # no longer getting one dent
			adventurer.weapon.adventurer = adventurer
			
			time_bw_customer = (randf() * 5) + 15
			
			get_node("/root/World/door/AnimationPlayer").play("open")
			


func _on_Button_pressed():
	get_node("UI/Credits").visible = false
