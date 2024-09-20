class_name SpawnDeck extends Resource
# abstract datatype to have a "deck" of spawn cards
# as a resource, which can be reused between
# directors if needed

@export var cards:Array[SpawnCard]
@export var rate:float = 1
@export var maxCredits:float = 10
