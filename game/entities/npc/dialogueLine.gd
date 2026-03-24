class_name DialogueLine
extends Resource

@export var speaker_name: String = ""
## The expression image shown on this line. 
## Leave empty for player lines if you don't want an image shown.
@export var expression: Texture2D = null
@export_multiline var text: String = ""
