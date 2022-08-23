extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
enum STATES {default,walkback,shot,seek,attack}


onready var BulletHole = preload("res://scene/BulletHole.tscn")

var Destination = Vector3()
var Hp = 100

var StartPos = Vector3()

var MoveSpeed = 0.5

var Velocity = Vector3()
var RayArray = []

var Target = null

var State = STATES.default

var LookDir = Vector2(0,1)

var PathCompleted = false
var CanShoot = true

func _ready():
	StartPos = translation
	LookDir = Vector2.RIGHT.rotated(rotation.y)
	
	CreateRays()

func CreateRays():
	for h in range(-3,3):
		for r in range(-25,25):
			var ray = RayCast.new()
			var castpos = Vector2(0,50).rotated(deg2rad(r)) 
			var castpos2 = Vector2(0,castpos.y).rotated(deg2rad(h*6)) 
			ray.cast_to = Vector3(castpos.x,castpos2.x,castpos2.y)
			ray.enabled = true
			ray.collision_mask = 5
			$Head/Eyes.add_child(ray)
			RayArray.append(ray)
		

func set_destination(new_dest):
	Destination = new_dest
	$NavigationAgent.set_target_location(Destination)

func _physics_process(delta):
	Velocity.y -= 0.8
	Velocity = lerp(Velocity , Vector3(0,Velocity.y,0),0.1)
	rotation.y = lerp_angle(rotation.y,LookDir.angle(),0.3)

	if State == STATES.attack:
		if Target != null:
			$AnimationPlayer.play("Aim")
			if translation.distance_to(Target.translation) >= 20:
				ChangeState(STATES.seek)
			if translation.distance_to(Target.translation) < 4:
				Velocity -= translation.direction_to(Target.translation) *MoveSpeed/1
			LookDir = Vector2(translation.z,translation.x).direction_to(Vector2(Target.translation.z,Target.translation.x))

			$Head.look_at(Target.translation,Vector3.UP)
			$Head.rotation.y = 0 
			
			$Head.rotation.x *= -1
	elif State == STATES.default:
		$AnimationPlayer.play("Idle")
	elif State != STATES.shot:
		$AnimationPlayer.play("Walk")
		$Head.rotation.x = 0
		LookDir = Vector2(Velocity.z,Velocity.x)
	
		if $NavigationAgent.is_target_reachable() and not PathCompleted:
			var target = $NavigationAgent.get_next_location()
			Velocity += translation.direction_to(target).normalized() * MoveSpeed
			$NavigationAgent.set_velocity(Velocity)
	Velocity = move_and_slide(Velocity,Vector3.UP,true)

	
	
func ChangeState(state):
	
	if State != state:
		State = state
		match state:
			STATES.attack:
				$AttackTimer.start()
			STATES.seek:
				$StopTargetTimer.start()
			STATES.shot:
				Velocity = Vector3()

func Hit(head,shooter):
	LookDir = Vector2(translation.direction_to(shooter.translation).z,translation.direction_to(shooter.translation).x)
	if State != STATES.seek:
		ChangeState(STATES.shot)
	if head:
		Hp -= 100
	else:
		Hp -= 25
	if Hp <= 0:
		queue_free()
func Shoot():
	if CanShoot:
		
		if $Head/RayCast.is_colliding():
			
			if $Head/RayCast.get_collider().is_in_group("Player"):

				$AnotherTimer.start()
			else:
				$AttackTimer.start()
	else: 
		$AttackTimer.start()


func _on_Timer_timeout():
	if Target!=null:
		set_destination(Target.translation)
	for i in RayArray:
		if i.is_colliding():
			if i.get_collider().is_in_group("Player"):
				Target = i.get_collider()
				ChangeState(STATES.attack)
				PathCompleted = false
				return
	if State == STATES.attack:
		ChangeState(STATES.seek)





func _on_StopTargetTimer_timeout():
	Target = null


func _on_NavigationAgent_target_reached():

	PathCompleted = true
	match State:
		STATES.default:
			pass
		STATES.seek:
			set_destination(StartPos)
			PathCompleted = false
			ChangeState(STATES.walkback)


func _on_ShotTimer_timeout():
	if State == STATES.shot:
		ChangeState(STATES.walkback)


func _on_AttackTimer_timeout():

	Shoot()


func _on_AnotherTimer_timeout():
			$ShootSOund.play()
			if $Head/RayCast.is_colliding():
				if $Head/RayCast.get_collider().is_in_group("Player"):
					$Head/RayCast.get_collider().Hit()
				if $Head/RayCast.get_collider().is_in_group("Wall"):
						var hole = BulletHole.instance() 
						hole.look_at($Head/RayCast.get_collision_normal(),Vector3.UP)
						hole.translation = $Head/RayCast.get_collision_point() + $Head/RayCast.get_collision_normal()/100
						get_parent().add_child(hole)
			$AttackTimer.start()


