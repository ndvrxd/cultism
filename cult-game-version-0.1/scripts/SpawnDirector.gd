class_name SpawnDirector extends Node

@export var deck:SpawnDeck;
@export var active:bool = true;
@export var rateCoefficient:float = 1;
@export var maxCreditsCoefficient:float = 1;

@export var NYI_immediate:bool = false
@export var attemptDelayUpperBound:float = 10;
@export var attemptDelayLowerBound:float = 1;
@export var maxCardsPerAttempt:int = 10;

var spawnpoints:Array = [];
var balance:float = 0;

@onready var spawnTimer:Timer = Timer.new()

func _ready():
	if !is_multiplayer_authority(): queue_free()
	add_child(spawnTimer)
	spawnpoints = get_tree().get_nodes_in_group("enemy_spawnpoint")
	#spawnTimer.one_shot=true
	spawnTimer.timeout.connect(attempt_spawn)
	spawnTimer.start(randf_range(attemptDelayLowerBound, attemptDelayUpperBound))

func _physics_process(delta:float):
	balance = min(balance + deck.rate * rateCoefficient * delta, deck.maxCredits * maxCreditsCoefficient)
	
func attempt_spawn():
	# TODO: factor in probability weight
	if not active: return
	for i in range(randi_range(1, maxCardsPerAttempt)):
		var card:SpawnCard = null
		for j in range(3):
			var temp:SpawnCard = deck.cards.pick_random()
			if temp.cost <= balance:
				card = temp
		if card == null: continue
		#assume at this point the card can be afforded
		balance -= card.cost
		for k in range(randi_range(card.count_lower, card.count_upper)):
			await get_tree().create_timer(0.2).timeout
			Entity.spawn(card.bodyPath, spawnpoints.pick_random().global_position)
	spawnTimer.wait_time = randf_range(attemptDelayLowerBound, attemptDelayUpperBound)
	
