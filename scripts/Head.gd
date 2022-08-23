extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal Hit(head,shooter)

# Called when the node enters the scene tree for the first time.
func Hit(e,shooter):
	emit_signal("Hit",true,shooter)
