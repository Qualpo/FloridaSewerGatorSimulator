extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (AudioStream)var Music

# Called when the node enters the scene tree for the first time.
func _ready():
	audio.stream = Music
	audio.play()
func _process(delta):
	$HpBar.value = $ViewportContainer/Viewport/Objects/Player.Hp
