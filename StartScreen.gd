extends Control



func _on_StartButton_pressed():
	visible = false
	get_node("/root/World").pauseGame = false


func _on_CreditsButton_pressed():
	get_node("/root/World/UI/Credits").visible = true
