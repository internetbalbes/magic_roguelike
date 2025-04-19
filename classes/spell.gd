class_name SpellClass

# Define the properties of the Player structure
var spell_name: String
var mana_cost: int
var damage: int
var type: String

# You can also add methods if needed
func _init(_spell_name: String, _mana_cost: int, _damage: int, _type: String):
	self.spell_name = _spell_name
	self.mana_cost = _mana_cost
	self.damage = _damage
	self.type = _type
