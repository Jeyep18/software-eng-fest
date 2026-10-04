extends RefCounted

const TICKET_PRICE: int = 50
const FRUIT_IDS := [
	"apple", "banana", "orange", "watermelon",
	"grapes", "cherries", "peach", "raspberry",
]
const WEIGHTS := [28, 24, 18, 12, 8, 5, 3, 2]
const PRIZES := [180, 240, 350, 600, 900, 1200, 2500, 5000]
const WEIGHT_TOTAL: int = 100
const SLOT_COUNT: int = 6


static func roll_ticket(rng: RandomNumberGenerator) -> Array[String]:
	var ticket: Array[String] = []
	for _slot in SLOT_COUNT:
		var draw := rng.randi_range(1, WEIGHT_TOTAL)
		for index in FRUIT_IDS.size():
			draw -= WEIGHTS[index]
			if draw <= 0:
				ticket.append(FRUIT_IDS[index])
				break
	return ticket


static func calculate_payout(ticket: Array[String]) -> int:
	if ticket.size() != SLOT_COUNT:
		return 0
	var payout := 0
	for row_start in [0, 3]:
		var fruit := ticket[row_start]
		if fruit != ticket[row_start + 1] or fruit != ticket[row_start + 2]:
			continue
		var index := FRUIT_IDS.find(fruit)
		if index >= 0:
			payout += PRIZES[index]
	return payout
