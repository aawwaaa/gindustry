class_name BuildingTypePanel
extends VBoxContainer

const requirement_scene: PackedScene = preload("res://ui/build/building_type_panel_requirement.tscn")

@onready var building_type_icon: TextureRect = %Icon
@onready var building_type_name: Label = %Name
@onready var building_type_requirements: VBoxContainer = %Requirements

var current_building_type: BuildingType = null

func apply_data(building_type: BuildingType) -> void:
    building_type_icon.texture = building_type.icon if building_type else null
    building_type_name.text = building_type.get_localized_name() if building_type else ""
    current_building_type = building_type
    visible = building_type != null
    update_requirements()

func update_requirements() -> void:
    var building_type = current_building_type
    var size = max(building_type.requirements.size() if building_type else 0, \
            building_type_requirements.get_child_count())
    var requirements = building_type.get_requirements() if building_type else []
    for index in size:
        var requirement_node: BuildingTypePanel_Requirement = building_type_requirements.get_child(index) \
            if index < building_type_requirements.get_child_count() else null
        if not requirement_node:
            requirement_node = requirement_scene.instantiate()
            building_type_requirements.add_child(requirement_node)
        if index >= requirements.size():
            requirement_node.apply_data(null, 0, 0)
            continue
        var requirement = requirements[index]
        var item_adapter = Game.current_entity.get_adapter(ItemAdapter.DEFAULT_NAME) as ItemAdapter
        var exists_item_amount = item_adapter.get_item_amount(requirement)
        requirement_node.apply_data(requirement, exists_item_amount, requirement.amount)

func _ready() -> void:
    await get_tree().process_frame
    GameUI.instance.player_inventory.inventory_updated.connect(update_requirements)
    visible = false
