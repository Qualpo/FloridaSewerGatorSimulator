extends KinematicBody


var MoveSpeed = 0.5

var Velocity = Vector3()

var FacingDir = Vector3()

var CamEnd = 0

var Aim = false

var Running = false

var Fov = 70

var InPoop = false

var Hp = 100

onready var BulletHole = preload("res://scene/BulletHole.tscn")

onready var PoopWalkSound = preload("res://audio/sfx/poopstep.ogg")
onready var PoopWalkSound2 = preload("res://audio/sfx/poopstep2.ogg")
onready var StoneStepSound = preload("res://audio/sfx/stonestep.ogg")
onready var StoneStepSound2 = preload("res://audio/sfx/stonestep2.ogg")

var CanShoot = true

var Jump = true

var BackFlip = false

var FlashLight = true

var Sensitivity = 1.0

var Delta = 1

var Ladder = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	Cam_Move(Vector2(Input.get_axis("AimDown","AimUp"),Input.get_axis("AimLeft","AimRight")) * Sensitivity*2*60 *delta)
	Delta = delta
	if not BackFlip:
		if Ladder == null:
			Velocity.y -= 0.8
		$Camera.rotation_degrees.x = lerp($Camera.rotation_degrees.x,CamEnd,0.4)
	else:
		Velocity.y = 0
		if $Camera.rotation_degrees.x > 359:
			BackFlip = false
			$Camera.rotation_degrees.x = CamEnd
		$Camera.rotation_degrees.x += 10
	
	
	$Camera.fov = lerp($Camera.fov,Fov,0.5)
	var inputDir = Vector2(Input.get_axis("Left","Right"),Input.get_axis("Backward","Forward"))
	var rotInputDir = inputDir.rotated(rotation.y)

	if Ladder == null:
		Velocity += Vector3(rotInputDir.x,0,-rotInputDir.y) * MoveSpeed
	else:
		Velocity.y = lerp(Velocity.y,0,0.5)
		
		#var ladder2dPos = Vector2(Ladder.z,Ladder.x)
		#var dirToLadder = Vector2(translation.z,translation.x).direction_to(ladder2dPos)
		Velocity.y -= rotInputDir.y
		if is_on_floor():
			if rotInputDir.y > 0:
				SetOffLadder(Ladder)
	
	if Input.is_action_just_pressed("FlashLight"):
		FlashLight = !FlashLight
		$Camera/SpotLight.visible = !$Camera/SpotLight.visible
	

	if Running and not Aim:
		MoveSpeed = 0.8
		if inputDir != Vector2():
			Fov = 80
		else:
			Fov = 70
	if Input.is_action_just_pressed("Run"):
			if Aim:
				Sensitivity = 1
				$AnimationPlayer.play_backwards("Aim")
				Aim = false
			Running = true
	if Input.is_action_just_released("Run"):
		Running = false
		if not Aim:
			
			MoveSpeed = 0.5
			Fov = 70
	$Camera.rotation_degrees.z = lerp($Camera.rotation_degrees.z,inputDir.x*-10,0.1)
	if is_on_floor():
		if Ladder == null:
			Velocity = lerp(Velocity , Vector3(0,Velocity.y,0),0.1)
			if Jump == true:
				if BackFlip:
					$Camera.rotation_degrees.x = 0
					BackFlip = false
				Jump = false
			if inputDir != Vector2():
				$AnimationPlayer3.playback_speed = MoveSpeed
				$AnimationPlayer3.play("Walk")
			
			else:
				$AnimationPlayer3.play("Stop")
				$Camera.v_offset = lerp($Camera.v_offset,0,0.1 )
		if Ladder == null:
			if Input.is_action_pressed("Jump"):
				Velocity.y += 10
	else:
		Velocity = lerp(Velocity , Vector3(0,Velocity.y,0),0.08)
		Jump = true
		$AnimationPlayer3.play("Stop")
		$Camera.v_offset = lerp($Camera.v_offset,Velocity.y/30,0.1 )
		if Ladder == null:
			if Input.is_action_just_pressed("Jump"):
				BackFlip = true
	if Input.is_action_just_pressed("Aim"):
			MoveSpeed = 0.4
			Sensitivity = 0.25
			Aim = true
			Fov = 50
			$AnimationPlayer.play("Aim")
	if Input.is_action_just_released("Aim"):
		if Aim:
			Sensitivity = 1
			Aim = false
			MoveSpeed = 0.5
			Fov = 70
			$AnimationPlayer.play_backwards("Aim")
	Velocity = move_and_slide(Velocity,Vector3.UP,true)
	
	if Input.is_action_just_pressed("Shoot"):
		Shoot()
func Hit():
	Hp -= 10
	if Hp <= 0:
		get_tree().quit()
func SetOnLadder(ladder):
	Ladder = ladder
func SetOffLadder(ladder):
	if ladder == Ladder:
		Ladder = null
func Shoot():
	if CanShoot:
		$Camera.rotation_degrees.x += 5
		$AnimationPlayer2.stop()
		$AnimationPlayer2.play("shoot")
		$AudioStreamPlayer2.play()
		$Timer.start()
		CanShoot = false
		if not Aim:
			
			CamEnd += 1
			CamEnd = clamp(CamEnd,-90, 90)
		if $Camera/GunCast.is_colliding():

				
			if $Camera/GunCast.get_collider().is_in_group("Enemy"):
				
				$Camera/GunCast.get_collider().Hit(false,self)
				#$Camera/GunCast.get_collider().Shot($Camera/GunCast.get_collision_normal())
			else:
				var hole = BulletHole.instance() 
				hole.look_at($Camera/GunCast.get_collision_normal(),Vector3(0,1,0))
				hole.translation = $Camera/GunCast.get_collision_point() + $Camera/GunCast.get_collision_normal()/100
				
				get_parent().add_child(hole)
func Cam_Move(moveVec):
		rotation_degrees.y += -moveVec.y
		CamEnd += moveVec.x
		CamEnd = clamp(CamEnd,-90, 90)
				

func _input(event):
	if event is InputEventMouseMotion:
		var CamMove = Vector3()
		CamMove = Vector3(-event.relative.y,event.relative.x,0) * Sensitivity*60 *Delta
		Cam_Move(CamMove)


func _on_Area_area_entered(area):
	if area.is_in_group("Water"):
		InPoop = true


func _on_Area_area_exited(area):
	if area.is_in_group("Water"):
		InPoop = false

func _play_FootStep_sound():
	if InPoop:
		if $AudioStreamPlayer.stream != PoopWalkSound:
			$AudioStreamPlayer.stream = PoopWalkSound
		else:
			$AudioStreamPlayer.stream = PoopWalkSound2
	else:
		if $AudioStreamPlayer.stream != StoneStepSound:
			$AudioStreamPlayer.stream = StoneStepSound
		else:
			$AudioStreamPlayer.stream = StoneStepSound2
	$AudioStreamPlayer.play()


func _on_Timer_timeout():
	CanShoot = true
