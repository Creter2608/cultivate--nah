extends Node

signal inventory_updated
signal system_inventory_updated

# Base rules
const BASE_PERSONAL_SLOTS: int = 20

# -----------------------------
# Data Storage
# -----------------------------
# Dictionary of slot_index (int) -> item_data_dict (Dictionary)
# item_data_dict format: {"id": "item_id", "amount": 10}
var personal_inventory: Dictionary = {}
var puppet_inventory: Dictionary = {}

# System inventory has no slot limit, we can just use an Array of dictionaries or dict by item_id
# We'll use a Dictionary of item_id (String) -> amount (int) for infinite stacking
var system_inventory: Dictionary = {}

# Enhancements
var permanent_bonus_slots: int = 0
var equipped_storage_id: String = "" # e.g. "storage_ring_01"

# In a real scenario, this would load from a global Item Database
# For now, we mock a simple database lookup
func _get_item_data(item_id: String) -> ItemData:
	# MOCKUP
	var data = ItemData.new()
	data.id = item_id
	if item_id == "space_stone":
		data.item_name = "Đá Không Gian"
		data.item_type = ItemData.ItemType.MATERIAL
	elif item_id == "storage_ring":
		data.item_name = "Nhẫn Trữ Vật"
		data.item_type = ItemData.ItemType.STORAGE
		data.bonus_inventory_slots = 50
	else:
		data.item_name = "Vật phẩm vô danh"
	return data

# -----------------------------
# Core Functions
# -----------------------------
func get_max_personal_slots() -> int:
	var total = BASE_PERSONAL_SLOTS + permanent_bonus_slots
	if equipped_storage_id != "":
		var storage_item = _get_item_data(equipped_storage_id)
		if storage_item != null:
			total += storage_item.bonus_inventory_slots
	return total

func upgrade_permanent_slots(amount: int = 1) -> void:
	permanent_bonus_slots += amount
	print("Permanent inventory slots upgraded by %d. Total base slots: %d" % [amount, BASE_PERSONAL_SLOTS + permanent_bonus_slots])
	inventory_updated.emit()

func equip_storage_item(item_id: String) -> void:
	equipped_storage_id = item_id
	print("Equipped storage: ", item_id, ". Max slots is now: ", get_max_personal_slots())
	inventory_updated.emit()

# -----------------------------
# Item Management (Personal)
# -----------------------------
func add_to_personal(item_id: String, amount: int) -> bool:
	var item_data = _get_item_data(item_id)
	if item_data == null: return false
	
	# First try to stack in existing slots
	for slot in personal_inventory.keys():
		var stack = personal_inventory[slot]
		if stack["id"] == item_id and stack["amount"] < item_data.max_stack:
			var space_left = item_data.max_stack - stack["amount"]
			if amount <= space_left:
				stack["amount"] += amount
				inventory_updated.emit()
				return true
			else:
				stack["amount"] = item_data.max_stack
				amount -= space_left
				
	# If we still have amount left, try to find empty slots
	var max_slots = get_max_personal_slots()
	for i in range(max_slots):
		if not personal_inventory.has(i):
			var to_add = min(amount, item_data.max_stack)
			personal_inventory[i] = {"id": item_id, "amount": to_add}
			amount -= to_add
			if amount <= 0:
				inventory_updated.emit()
				return true
				
	print("Personal Inventory is Full!")
	inventory_updated.emit()
	return amount == 0 # Returns true if all was added

# -----------------------------
# Item Management (System)
# -----------------------------
# System inventory uses item_id as key, amount as value. Infinite slots.
func add_to_system(item_id: String, amount: int) -> void:
	if not GameManager.has_heavenly_fragment(6):
		printerr("Cannot access System Inventory without Heavenly Fragment #6!")
		return
		
	if system_inventory.has(item_id):
		system_inventory[item_id] += amount
	else:
		system_inventory[item_id] = amount
		
	print("Added %d of %s to System Inventory." % [amount, item_id])
	system_inventory_updated.emit()

func transfer_to_system(slot_index: int) -> void:
	if not GameManager.has_heavenly_fragment(6):
		print("You do not have System Inventory unlocked.")
		return
		
	if personal_inventory.has(slot_index):
		var item = personal_inventory[slot_index]
		add_to_system(item["id"], item["amount"])
		personal_inventory.erase(slot_index)
		inventory_updated.emit()
		print("Item transferred to system inventory.")

func transfer_from_system(item_id: String, amount: int) -> void:
	if not GameManager.has_heavenly_fragment(6):
		return
		
	if system_inventory.has(item_id) and system_inventory[item_id] >= amount:
		if add_to_personal(item_id, amount):
			system_inventory[item_id] -= amount
			if system_inventory[item_id] <= 0:
				system_inventory.erase(item_id)
			system_inventory_updated.emit()
		else:
			print("Not enough space in personal inventory to retrieve from system.")

# -----------------------------
# Serialization
# -----------------------------
func to_dict() -> Dictionary:
	return {
		"permanent_bonus_slots": permanent_bonus_slots,
		"equipped_storage_id": equipped_storage_id,
		"personal_inventory": personal_inventory,
		"puppet_inventory": puppet_inventory,
		"system_inventory": system_inventory
	}

func from_dict(data: Dictionary) -> void:
	permanent_bonus_slots = data.get("permanent_bonus_slots", 0)
	equipped_storage_id = data.get("equipped_storage_id", "")
	
	# Dictionary keys from JSON load as Strings, we need integer keys for personal/puppet slots
	var loaded_personal = data.get("personal_inventory", {})
	personal_inventory.clear()
	for key in loaded_personal.keys():
		personal_inventory[int(key)] = loaded_personal[key]
		
	var loaded_puppet = data.get("puppet_inventory", {})
	puppet_inventory.clear()
	for key in loaded_puppet.keys():
		puppet_inventory[int(key)] = loaded_puppet[key]
		
	system_inventory = data.get("system_inventory", system_inventory)
